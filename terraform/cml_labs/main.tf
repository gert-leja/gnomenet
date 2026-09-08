terraform {
	required_providers {
		cml2 = {
			source = "CiscoDevNet/cml2"
			version = "0.9.1"
		}
	}
}

resource "cml2_lab" "lab" {
	title = var.lab_title
}

locals {
	router_management_ip = {
		for idx, key in sort(keys(var.r_labels)) : key => cidrhost(var.management_cidr, idx + 1)
	}

	# ip_start variable ensure it will always be 192.168.1.10, change this if conflicting addresses are found.
	local_network_ip = cidrhost(var.local_network, var.ip_start)

	# point-to-point network setup, structure: (prefix, newbits, netnum) - newbits controls how many extra bits to add to the prefix length
	# netnum sets which specific subnet block to return out of all the possible ones at this new subnet size (0-indexed)
	# for example, first block is 10.1.0.0/30 and second block would be 10.1.0.4/30, and so on. 
	r1_r2_subnet = cidrsubnet(var.link_base_cidr, 14, 0)
	r2_r3_subnet = cidrsubnet(var.link_base_cidr, 14, 1)
	r2_sw1_subnet = cidrsubnet(var.link_base_cidr, 14, 2)

	router_ifaces = {
		r1 = [
			{ name = "ethernet0/0", ip = local.local_network_ip, mask = "255.255.255.0" },
			{ name = "ethernet0/1", ip = cidrhost(local.r1_r2_subnet, 1), mask = cidrnetmask(local.r1_r2_subnet) },
		]
		r2 = [
			{ name = "ethernet0/0", ip = cidrhost(local.r1_r2_subnet, 2), mask = cidrnetmask(local.r1_r2_subnet) },
			{ name = "ethernet0/1", ip = cidrhost(local.r2_r3_subnet, 1), mask = cidrnetmask(local.r2_r3_subnet) },
			{ name = "ethernet0/2", ip = cidrhost(local.r2_sw1_subnet, 1), mask = cidrnetmask(local.r2_sw1_subnet) },
		]
		r3 = [
			{ name = "ethernet0/0", ip = cidrhost(local.r2_r3_subnet, 2), mask = cidrnetmask(local.r2_r3_subnet) },
		]
	}

	router_config = {
		for key, router in var.r_labels : key => templatefile(
			"${path.module}/template/router_template.tftpl",
			{
				hostname = router
				enable_secret = var.enable_secret
				ansible_user = var.ansible_user
				ansible_password = var.ansible_password
				loopback_ip = local.router_management_ip[key]
				interfaces = local.router_ifaces[key]
			}
		)
	}

	switch_config = {
		sw1 = <<-EOT
			hostname ${var.sw_labels["sw1"]}
			!
			enable secret ${var.enable_secret}
			!
			username ${var.ansible_user} privilege 15 secret ${var.ansible_password}
			!
			ip domain name gnomenet.com
			crypto key generate rsa modulus 4096
			!
			line vty 0 4
			 login local
			 transport input ssh
			!
			interface vlan 1
			 ip address ${cidrhost(local.r2_sw1_subnet, 2)} ${cidrnetmask(local.r2_sw1_subnet)}
			 no shutdown
			!
			end
		EOT
	}

}

resource "cml2_node" "ext_conn" {
	lab_id = cml2_lab.lab.id
	nodedefinition = "external_connector"
	configuration = "bridge0"
	label = "External"
}

# R1 will connect to External
resource "cml2_node" "routers" {
	for_each = var.r_labels
	lab_id = cml2_lab.lab.id
	nodedefinition = "iol-xe"
	label = each.value
	configuration = local.router_config[each.key]
}

# the switch SW1 will have different VLANs so router R2 will connect to SW1 and apply ROAS configuration
resource "cml2_node" "switches" {
	for_each = var.sw_labels
	lab_id = cml2_lab.lab.id
	nodedefinition = "ioll2-xe"
	label = each.value
	configuration = local.switch_config[each.key]
}

resource "cml2_link" "link_r1_ext" {
	lab_id = cml2_lab.lab.id
	node_a = cml2_node.routers["r1"].id
	slot_a = 0
	node_b = cml2_node.ext_conn.id
}

resource "cml2_link" "link_r1_r2" {
	lab_id = cml2_lab.lab.id
	node_a = cml2_node.routers["r1"].id
	slot_a = 1
	node_b = cml2_node.routers["r2"].id
	slot_b = 0
}

resource "cml2_link" "link_r2_sw1" {
	lab_id = cml2_lab.lab.id
	node_a = cml2_node.routers["r2"].id
	slot_a = 2
	node_b = cml2_node.switches["sw1"].id
	slot_b = 0
}

resource "cml2_link" "link_r2_r3" {
	lab_id = cml2_lab.lab.id
	node_a = cml2_node.routers["r2"].id
	slot_a = 1
	node_b = cml2_node.routers["r3"].id
	slot_b = 0
}

resource "cml2_lifecycle" "starter" {
	lab_id = cml2_lab.lab.id

	depends_on = [
		cml2_node.routers,
		cml2_node.switches,
		cml2_node.ext_conn,
		cml2_link.link_r1_ext,
		cml2_link.link_r1_r2,
		cml2_link.link_r2_sw1,
		cml2_link.link_r2_r3,
	]
	

	state = "STARTED"
}

# outputs
output "lab_id" {
	value = cml2_lab.lab.id
}

output "router_id" {
	value = { for device, router in cml2_node.routers : router.label => router.id }
}

output "switch_id" {
	value = { for device, switch in cml2_node.switches : switch.label => switch.id }
}

output "ext_conn_id" {
	value = cml2_node.ext_conn.id
}

output "router_management_ip" {
	value = local.router_management_ip
}