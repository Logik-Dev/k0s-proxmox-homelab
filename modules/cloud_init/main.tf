terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.57.0"
    }
  }
}

resource "proxmox_virtual_environment_file" "cloud_init" {
  content_type = "snippets"
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

output "cloud_init" {
  value = proxmox_virtual_environment_file.cloud_init.id

}
