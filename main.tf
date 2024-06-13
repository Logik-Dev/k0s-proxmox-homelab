# providers
terraform {
  required_providers {
    sops = {
      source  = "carlpett/sops"
      version = "~> 0.5"
    }
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.57.0"
    }
  }
}

# proxmox provider
provider "proxmox" {
  endpoint  = data.sops_file.secrets.data["proxmox_url"]
  api_token = data.sops_file.secrets.data["api_token"]
  insecure  = false

  ssh {
    agent    = true
    username = data.sops_file.secrets.data["ssh_user"]
  }
}

# secret file
data "sops_file" "secrets" {
  source_file = "./secrets.sops.yaml"
}

# ssh public key
data "local_file" "ssh_yubikey_key" {
  filename = "./yubikey-gpg.pub"
}

# local variables
locals {
  ssh_key = trimspace(data.local_file.ssh_yubikey_key.content)
  env     = terraform.workspace
  vlan_id = {
    dev  = 111,
    prod = 222
  }
}

# ubuntu lxc template
module "ubuntu_lxc_template" {
  source = "./modules/templates"
  type   = "vztmpl"
  url    = "http://download.proxmox.com/images/system/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
}

# ubuntu vm image
module "ubuntu_vm_image" {
  source = "./modules/templates"
  type   = "iso"
  url    = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
}

# cloud-init config
module "cloud_init" {
  source   = "./modules/templates"
  type     = "snippets"
  ssh_user = data.sops_file.secrets.data["ssh_user"]
  ssh_key  = local.ssh_key

}

# 1 control-plane in lxc
module "controller" {
  source = "./modules/lxc"

  name          = format("%s-control-plane", local.env)
  id            = parseint(format("%s%s", lookup(local.vlan_id, local.env), 0), 10)
  template_id   = module.ubuntu_lxc_template.container_template
  tags          = ["k0s", "controller", local.env]
  ssh_keys      = [local.ssh_key]
  root_password = data.sops_file.secrets.data["root_password"]
  vlan_id       = lookup(local.vlan_id, local.env)
}

# 2 workers vms
module "workers" {
  count  = 2
  source = "./modules/vm"

  name         = format("%s-worker-%s", local.env, count.index + 1)
  id           = parseint(format("%s%s", lookup(local.vlan_id, local.env), count.index + 1), 10)
  image        = module.ubuntu_vm_image.vm_image
  cloud_config = module.cloud_init.cloud_init
  tags         = ["k0s", "worker", local.env]
  vlan_id      = lookup(local.vlan_id, local.env)
  memory       = 8192
  cpus         = 2
  size         = 50
}
