# k0s-proxmox-homelab
Homelab kubernetes cluster with k0s managed by terraform and ansible

### Terraform 
My homelab infrastructure is environment based:
- One **dev** cluster for testing future services.
- One **prod** cluster to keep alive important services.
For now, each cluster is composed of 1 control-plane and 2 workers.

I'm using the workspace feature of terraform to manage environments:

Create:
`terraform workspace create dev`
`terraform workspace create prod`

Switch:
`terraform workspace select dev`
`terraform workspace select prod`

And finally:
`terraform plan`
`terraform apply`

I don't want to destroy proxmox files (ISOs, Templates, Snippets), so I use:
`terraform destroy -target module.controller`
`terraform destroy -target module.workers`

### Ansible
The inventory is dynamic and hosts are grouped by tags.
I make use of those tags to target dev or prod vms:
`ansible-playbook site.yml --limit 'all:dev'`


### TODO
- [ ] Handle multiple kubeconfig (dev, prod)
- [ ] Handle mutliple worker tokens (dev, prod)
- [ ] Allow differents cni (callico, cilium)
- [ ] Disable PermitRootLogin on lxc (if possible)
- [ ] Differentiate resources per env properly in ansible roles
- [ ] On destroy worker token and kubeconfig should be deleted too
- [ ] Remove namespace after removing helm chart
- [ ] Fix ansible warning (helm diff, ipaddress filter)
