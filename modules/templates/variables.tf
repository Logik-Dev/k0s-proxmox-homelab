
variable "proxmox_node" {
  description = "Proxmox datacenter target node"
  type        = string
  default     = "pve"
}

variable "type" {
  description = "Type of template iso/snippets/vztmpl"
  type        = string
}

variable "url" {
  description = "Url of the template file"
  type        = string
  default     = ""
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
