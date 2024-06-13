variable "proxmox_node" {
  description = "Target node of proxmox datacenter"
  type        = string
  default     = "pve"
}

variable "name" {
  description = "Name of the vm"
  type        = string
}

variable "id" {
  description = "VM id"
  type        = number
}

variable "tags" {
  description = "VM tags"
  type        = list(string)

}

variable "cloud_config" {
  description = "Cloud config file"
  type        = string
}

variable "datastore" {
  description = "Datastore where the vm's disk will reside"
  type        = string
  default     = "ultra"
}

variable "image" {
  description = "OS image"
  type        = string
}

variable "size" {
  description = "Size of the disk"
  type        = number
  default     = 20
}

variable "vlan_id" {
  description = "Vlan id"
  type        = number

}

variable "memory" {
  description = "Total memory"
  type        = number
  default     = 2048
}

variable "cpus" {
  description = "Total cpus"
  type        = number
  default     = 1
}
