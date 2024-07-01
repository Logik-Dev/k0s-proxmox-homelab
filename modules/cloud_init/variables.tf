
variable "proxmox_node" {
  description = "Proxmox datacenter target node"
  type        = string
  default     = "pve"
}

variable "ssh_user" {
  description = "User account"
  type        = string
  default     = "admin"
}

variable "ssh_key" {
  description = "SSH public key"
  type        = string
  default     = ""
}
