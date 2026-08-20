terraform {
	required_providers {
		cml2 = {
			source = "CiscoDevNet/cml2"
		}
	}
}

provider "cml2" {
	address = "https://192.168.1.109"
	username = "spongebob"
	password = "Pantsok123"
	skip_verify = true
}

resource "cml2_lab" "spongebob" {
	title = "GnomeNet"
}

locals {
	router_management_ip = {
		for idx, key in sort(keys(var.r_labels)) : key => cidrhost(var.management_cidr, idx + 1)
	}

	# this is not a very good way of assigning IPs to router and switch, but it will be replaced when the script is fixed.
	switch_management_ip = {
		for idx, key in sort(keys(var.sw_labels)) : key => cidrhost(var.management_cidr, idx + 4)
	}

	# point-to-point network setup, structure: (prefix, newbits, netnum) - newbits controls how many extra bits to add to the prefix length
	# netnum sets which specific subnet block to return out of all the possible ones at this new subnet size (0-indexed)
	# for example, first block is 10.1.0.0/30 and second block would be 10.1.0.4/30, and so on. 
	r1_r2_subnet = cidrsubnet(var.link_base_cidr, 14, 0)
	r2_r3_subnet = cidrsubnet(var.link_base_cidr, 14, 1)
	r2_sw1_subnet = cidrsubnet(var.link_base_cidr, 14, 2)

	subnet_mask = cidrnetmask(var.network_cidr)

	router_ifaces = {
		for idx, router in sort(keys(var.r_labels)) : router => {
			for ifnum in range(3) : "ethernet0/${ifnum}" =>
				cidrhost(var.network_cidr, var.ip_start + idx * var.ip_increment_amount + ifnum)
		}
	}

	router_config = {
		r1 = <<-EOT
			hostname ${var.r_labels["r1"]}
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
			interface Loopback0
			 ip address ${local.router_management_ip["r1"]} 255.255.255.255
			 no shutdown
			!
			interface ethernet0/0
			 ip address dhcp
			 no shutdown
			interface ethernet0/1
			 ip address ${cidrhost(local.r1_r2_subnet, 1)} ${cidrnetmask(local.r1_r2_subnet)}
			 no shutdown
			!
			router ospf 1
			 network 192.168.0.0 0.0.255.255 area 0
			 network 10.0.0.0 0.255.255.255 area 1
			end
		EOT

		r2 = <<-EOT
			hostname ${var.r_labels["r2"]}
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
			interface Loopback0
			 ip address ${local.router_management_ip["r2"]} 255.255.255.255
			 no shutdown
			!
			interface ethernet0/0
			 ip address ${cidrhost(local.r1_r2_subnet, 2)} ${cidrnetmask(local.r1_r2_subnet)}
			 no shutdown
			!
			interface ethernet0/1
			 ip address ${cidrhost(local.r2_r3_subnet, 1)} ${cidrnetmask(local.r2_r3_subnet)}
			 no shutdown
			!
			interface ethernet0/2
			 ip address ${cidrhost(local.r2_sw1_subnet, 1)} ${cidrnetmask(local.r2_sw1_subnet)}
			 no shutdown
			!
			router ospf 1
			 network 192.168.0.0 0.0.255.255 area 0
			 network 10.0.0.0 0.255.255.255 area 1
			!
			end
		EOT

		r3 = <<-EOT
			hostname ${var.r_labels["r3"]}
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
			interface Loopback0
			 ip address ${local.router_management_ip["r3"]} 255.255.255.255
			!
			interface ethernet0/0
			 ip address ${cidrhost(local.r2_r3_subnet, 2)} ${cidrnetmask(local.r2_r3_subnet)}
			 no shutdown
			!
			router ospf 1
			 network 192.168.0.0 0.0.255.255 area 0
			 network 10.0.0.0 0.255.255.255 area 1
			!
			end
		EOT
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
			 ip address ${local.switch_management_ip["sw1"]} 255.255.255.255
			 no shutdown
			!
			interface ethernet0/0
			 ip address ${cidrhost(local.r2_sw1_subnet, 2)} ${cidrnetmask(local.r2_sw1_subnet)}
			 no shutdown
			!
			end
		EOT
	}

}

resource "cml2_node" "ext_conn" {
	lab_id = cml2_lab.spongebob.id
	nodedefinition = "external_connector"
	configuration = "bridge0"
	label = "External"
}

# R1 will connect to External, but there is no need for a separate network assignment for R1, R1 will grab IP via DHCP.
resource "cml2_node" "routers" {
	for_each = var.r_labels
	lab_id = cml2_lab.spongebob.id
	nodedefinition = "iol-xe"
	label = each.value
	configuration = local.router_config[each.key]
}

# the switch SW1 will have different VLANs so router R2 will connect to SW1 and apply ROAS configuration
resource "cml2_node" "switches" {
	for_each = var.sw_labels
	lab_id = cml2_lab.spongebob.id
	nodedefinition = "ioll2-xe"
	label = each.value
	configuration = local.switch_config[each.key]
}

resource "cml2_link" "link_r1_ext" {
	lab_id = cml2_lab.spongebob.id
	node_a = cml2_node.routers["r1"].id
	slot_a = 0
	node_b = cml2_node.ext_conn.id
}

resource "cml2_link" "link_r1_r2" {
	lab_id = cml2_lab.spongebob.id
	node_a = cml2_node.routers["r1"].id
	slot_a = 1
	node_b = cml2_node.routers["r2"].id
	slot_b = 0
}

resource "cml2_link" "link_r2_sw1" {
	lab_id = cml2_lab.spongebob.id
	node_a = cml2_node.routers["r2"].id
	slot_a = 2
	node_b = cml2_node.switches["sw1"].id
	slot_b = 0
}

resource "cml2_link" "link_r2_r3" {
	lab_id = cml2_lab.spongebob.id
	node_a = cml2_node.routers["r2"].id
	slot_a = 1
	node_b = cml2_node.routers["r3"].id
	slot_b = 0
}

resource "cml2_lifecycle" "starter" {
	lab_id = cml2_lab.spongebob.id

	elements = concat(
		[for router in cml2_node.routers : router.id],
		[for switch in cml2_node.switches : switch.id],
		[cml2_node.ext_conn.id],
		[
			cml2_link.link_r1_ext.id,
			cml2_link.link_r1_r2.id,
			cml2_link.link_r2_sw1.id,
			cml2_link.link_r2_r3.id,
		]
	)

	state = "STARTED"
}

output "router_id" {
	value = { for device, router in cml2_node.routers : router.label => router.id}
}

output "switch_id" {
	value = { for device, switch in cml2_node.switches : switch.label => switch.id}
}
