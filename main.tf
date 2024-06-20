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
    time = {
      source  = "hashicorp/time"
      version = "0.11.2"
    }
    flux = {
      source  = "fluxcd/flux"
      version = ">= 1.3"
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

# flux provider
provider "flux" {
  kubernetes = {
    config_path = "~/.kube/config"
  }

  git = {
    url = "https://github.com/${local.github_user}/${local.github_repo}.git"
    http = {
      username = local.github_user
      password = data.sops_file.secrets.data["flux_github_token"]
    }

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
  github_user = "Logik-Dev"
  github_repo = "flux-homelab"
  ssh_key     = trimspace(data.local_file.ssh_yubikey_key.content)
  env         = terraform.workspace
  network     = "10.0"
  vlans = {
    dev  = 111,
    prod = 222
  }

  vlan_id = lookup(local.vlans, local.env)
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
  id            = parseint(format("%s%s", local.vlan_id, 0), 10)
  template_id   = module.ubuntu_lxc_template.container_template
  tags          = ["k0s", "controller", local.env]
  ssh_keys      = [local.ssh_key]
  root_password = data.sops_file.secrets.data["root_password"]
  vlan_id       = local.vlan_id
  ip            = format("%s.%s.10/24", local.network, local.vlan_id)
  gateway       = format("%s.%s.1", local.network, local.vlan_id)
}

# 2 workers vms
module "workers" {
  depends_on = [module.controller]
  count      = 2
  source     = "./modules/vm"

  name         = format("%s-worker-%s", local.env, count.index + 1)
  id           = parseint(format("%s%s", local.vlan_id, count.index + 1), 10)
  image        = module.ubuntu_vm_image.vm_image
  cloud_config = module.cloud_init.cloud_init
  tags         = ["k0s", "worker", local.env]
  vlan_id      = local.vlan_id
  ip           = format("%s.%s.%s/24", local.network, local.vlan_id, count.index + 11)
  gateway      = format("%s.%s.1", local.network, local.vlan_id)
  memory       = 8192
  cpus         = 2
  size         = 50
}

# nfs server vm
module "nfs_server" {
  source = "./modules/vm"

  name         = format("%s-fast-nfs", local.env)
  id           = parseint(format("%s%s", local.vlan_id, local.vlan_id), 10)
  image        = module.ubuntu_vm_image.vm_image
  cloud_config = module.cloud_init.cloud_init
  tags         = ["fast-nfs", local.env]
  vlan_id      = local.vlan_id
  ip           = format("%s.%s.20/24", local.network, local.vlan_id)
  gateway      = format("%s.%s.1", local.network, local.vlan_id)
  memory       = 4096
  cpus         = 1
  size         = 300
}

# playbook
resource "null_resource" "playbook" {
  depends_on = [module.workers, module.controller]
  provisioner "local-exec" {
    command = "ansible-playbook bootstrap.yml -l ${terraform.workspace} -e first_init=true"
  }
}

# wait 15 seconds for k8s to be ready
resource "time_sleep" "sleep_after_playbook" {
  depends_on      = [null_resource.playbook]
  create_duration = "15s"
}

# bootstrap flux
resource "flux_bootstrap_git" "this" {
  depends_on           = [time_sleep.sleep_after_playbook]
  delete_git_manifests = false
  path                 = format("clusters/%s-cluster", terraform.workspace)
}
