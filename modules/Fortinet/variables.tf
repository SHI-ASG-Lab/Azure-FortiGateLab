# Variable Declarations

variable "resource_group_name" {
  type = string
}

variable "RGlocation" {
  type = string
}

variable "customer_id" {
  type = string
}

variable "mgmt_subnet_id" {
  type = string
}

variable "int_subnet_id" {
  type = string
}

variable "ext_subnet_id" {
  type = string
}

variable "tags" {
  type = map(string)
}
