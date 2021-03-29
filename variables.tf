variable "prefix" {
  description = "The prefix which should be used for all resources in this example"
  default = "udacity-c01project"
}

variable "numberOfVms" {
  description = "The amount of VMs that are going to be deployed"
  default = 2
}

variable "username" {
  description = "The username that is going to be created for the virtual machine"
  default = "testUser"
}

variable "password" {
  description = "The password that is going to be created for the user in the virtual machine"
  default = "password1234$"
}