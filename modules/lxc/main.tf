terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.57.0"
    }
  }
}


resource "proxmox_virtual_environment_container" "container" {
  description = var.name

  node_name    = var.proxmox_node
  vm_id        = var.id
  unprivileged = true
  tags         = var.tags

  operating_system {
    template_file_id = var.template_id
    type             = "ubuntu"
  }

  disk {
    datastore_id = var.datastore
    size         = var.size
  }


  initialization {
    hostname = var.name
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }

    user_account {
      keys     = var.ssh_keys
      password = var.root_password
    }
  }

  network_interface {
    bridge  = "vmbr0"
    name    = "eth0"
    vlan_id = var.vlan_id
  }

  memory {
    dedicated = var.memory
  }

  cpu {
    cores = var.cpus
  }

}

