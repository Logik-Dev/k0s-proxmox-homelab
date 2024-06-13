terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.57.0"
    }
  }
}

resource "proxmox_virtual_environment_vm" "worker" {

  name      = var.name
  vm_id     = var.id
  node_name = var.proxmox_node
  tags      = var.tags

  agent {
    enabled = true
  }

  initialization {
    user_data_file_id = var.cloud_config

    ip_config {
      ipv4 {
        address = var.ip
        gateway = var.gateway
      }
    }
    dns {
      servers = var.dns_servers
    }

  }

  cpu {
    cores = var.cpus
    type  = "host"
  }

  memory {
    dedicated = var.memory
  }

  disk {
    datastore_id = var.datastore
    file_id      = var.image
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = var.size
  }

  network_device {
    bridge  = "vmbr0"
    vlan_id = var.vlan_id
  }
}

