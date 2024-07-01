terraform destroy \
  -target module.workers \
  -target module.controller \
  -target flux_bootstrap_git.this

