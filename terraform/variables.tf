# Host 1
variable "cml_address_1" {
  type = string
  description = "URL of CML host 1"
}

variable "cml_username_1" {
  type = string
  description = "Username of CML host 1 account"
  sensitive = true
}

variable "cml_password_1" {
  type = string
  description = "Password of CML host 1 account"
  sensitive = true
}

# Host 2
variable "cml_address_2" {
  type = string
  description = "URL of CML host 2"
}

variable "cml_username_2" {
  type = string
  description = "Username of CML host 2 account"
  sensitive = true
}

variable "cml_password_2" {
  type = string
  description = "Password of CML host 2 account"
  sensitive = true
}

# addresses
variable "lab_1_management_cidr" {
  type = string
  default = "1.1.1.0/24"
}

variable "lab_1_link_base_cidr" {
  type = string
  default = "10.1.0.0/16"
}

variable "lab_2_management_cidr" {
  type = string
  default = "2.2.2.0/24"
}

variable "lab_2_link_base_cidr" {
  type = string
  default = "10.2.0.0/16"
}

variable "local_network" {
  type = string
  default = "192.168.1.0/24"
}

variable "lab_1_ip_start" {
  type = number
  default = 10
  description = "offset host part for lab 1's R1"
}

variable "lab_2_ip_start" {
  type = number
  defeault = 11
  description = "offset host part for lab 2's R1"
}