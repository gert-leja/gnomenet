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