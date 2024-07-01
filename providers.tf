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

