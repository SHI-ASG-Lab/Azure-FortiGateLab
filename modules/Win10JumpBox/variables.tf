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

variable "win10vmName" {
  type = string
}

variable "ipnum"{
    type = number
}

variable "user" {
  type = map(string)
}

variable "pass" {
  type = string
}

variable "DNS_Name" {
  type = string
}
