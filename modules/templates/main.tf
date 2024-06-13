terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.57.0"
    }
  }
}

resource "proxmox_virtual_environment_download_file" "container_template" {
  count = var.type == "vztmpl" ? 1 : 0

  content_type        = "vztmpl"
  datastore_id        = "local"
  node_name           = var.proxmox_node
  url                 = var.url
  overwrite_unmanaged = true

  lifecycle {
    prevent_destroy = true
  }
}


resource "proxmox_virtual_environment_download_file" "vm_image" {
  count = var.type == "iso" ? 1 : 0

  content_type        = "iso"
  datastore_id        = "local"
  node_name           = var.proxmox_node
  url                 = var.url
  overwrite_unmanaged = true

  lifecycle {
    prevent_destroy = true
  }
}

resource "proxmox_virtual_environment_file" "cloud_init" {
  count = var.type == "snippets" ? 1 : 0

  content_type = var.type
  datastore_id = "local"
  node_name    = var.proxmox_node

  source_raw {
    data = <<-EOF
    #cloud-config
    users:
      - default
      - name: ${var.ssh_user}
        groups:
          - sudo
        shell: /bin/bash
        ssh_authorized_keys:
          - ${var.ssh_key}
        sudo: ALL=(ALL) NOPASSWD:ALL
    runcmd:
        - apt update
        - apt install -y qemu-guest-agent net-tools
        - timedatectl set-timezone Europe/Paris
        - systemctl enable qemu-guest-agent --now
        - echo "done" > /tmp/cloud-config.done
    EOF

    file_name = "cloud-config.yaml"

  }

  lifecycle {
    prevent_destroy = true
  }
}

output "container_template" {
  value = length(proxmox_virtual_environment_download_file.container_template) > 0 ? proxmox_virtual_environment_download_file.container_template[0].id : ""
}

output "vm_image" {
  value = length(proxmox_virtual_environment_download_file.vm_image) > 0 ? proxmox_virtual_environment_download_file.vm_image[0].id : ""
}

output "cloud_init" {
  value = length(proxmox_virtual_environment_file.cloud_init) > 0 ? proxmox_virtual_environment_file.cloud_init[0].id : ""

}
