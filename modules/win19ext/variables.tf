# Variable Declarations

variable "resource_group_name" {
  type = string
}

variable "RGlocation" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "VmName" {
  type = string
}

variable "ipnum"{
    type = number
}

variable "user" {
  type = string
}

variable "pass" {
  type = string
}
