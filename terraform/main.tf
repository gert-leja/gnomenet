terraform {
	required_providers {
		cml2 = {
			source = "CiscoDevNet/cml2"
		}
	}
}

provider "cml2" {
	alias = "host1"
	address = var.cml_address_1
	username = var.cml_username_1
	password = var.cml_password_1
	skip_verify = true
}

provider "cml2" {
	alias = "host2"
	address = var.cml_address_2
	username = var.cml_username_2
	password = var.cml_password_2
	skip_verify = true
}


module "lab_1" {
	source = "./cml_labs"
	providers = {
		cml2 = cml2.host1
	}

	lab_title = "GnomeNet_1"
	management_cidr = var.lab_1_management_cidr
	link_base_cidr = var.lab_1_link_base_cidr
	local_network = var.local_network
	ip_start = var.lab_1_ip_start
}

module "lab_2" {
	source = "./cml_labs"
	providers = {
		cml2 = cml2.host2
	}

	lab_title = "GnomeNet_2"
	management_cidr = var.lab_2_management_cidr
	link_base_cidr = var.lab_2_link_base_cidr
	local_network = var.local_network
	ip_start = var.lab_2_ip_start
}

# add interconnect link here later


# outputs
output "lab_1_router_id" {
	value = module.lab_1.router_id
}

output "lab_1_switch_id" {
	value = module.lab_1.switch_id
}

output "lab_1_router_management_ip" {
	value = module.lab_1.router_management_ip
}

output "lab_2_router_id" {
	value = module.lab_2.router_id
}

output "lab_2_switch_id" {
	value = module.lab_2.switch_id
}

output "lab_2_router_management_ip" {
	value = module.lab_2.router_management_ip
}
