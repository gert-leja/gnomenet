variable "r_labels" {
	type = map(string)

	default ={ 
	r1 = "R1",
	r2 = "R2",
	r3 = "R3"
	}
}

variable "sw_labels" {
  type = map(string)

  default = {
  sw1 = "SW1",
  }
}

variable "enable_secret" {
	type = string
	default = "admin"
}

variable "ansible_user" {
	type = string
	default = "admin"
}

variable "ansible_password" {
	type = string
	default = "admin"
}

variable "ip_increment_amount" {
	type = number
	default = 10
}

variable "ip_start" {
	type = number
	default = 10
}

variable "management_cidr" {
	type = string
	default = "1.1.1.0/24"
}

variable "link_base_cidr" {
	type = string
	default = "10.1.0.0/16"
}

variable "network_cidr" {
  type = string
  default = "172.16.0.0/16"
}

variable "local_network" {
	type = string
	default = "192.168.1.0/24"
}
