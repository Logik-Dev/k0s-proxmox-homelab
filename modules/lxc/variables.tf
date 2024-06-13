variable "proxmox_node" {
  description = "Target node of proxmox datacenter"
  type        = string
  default     = "pve"
}

variable "name" {
  description = "Name of the lxc container"
  type        = string
}

variable "id" {
  description = "Container ID"
  type        = number
}

variable "tags" {
  description = "Container tags"
  type        = list(string)

}
variable "template_id" {
  description = "Unique identifier of the template"
  type        = string
}
variable "datastore" {
  description = "Datastore where the container's disk will reside"
  type        = string
  default     = "ultra"
}
variable "size" {
  description = "Size of the disk"
  type        = number
  default     = 20
}

variable "root_password" {
  description = "Root password"
  type        = string
  sensitive   = true
}

variable "ssh_keys" {
  description = "Array of ssh public keys"
  type        = list(string)
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
