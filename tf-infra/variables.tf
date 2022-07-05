variable "aks_rg_name" {
  default = "sadey2k-pipeline-rg"
}

variable "log_analytics_workspace_name" {
  default = "sadey2k-log-analytics-workspace"
}

variable "log_analytics_workspace_sku" {
  default = "PerGB2018"
}

variable "aks_cluster_name" {
  default = "sadey2k-aks-cluster"
}

variable "dns_prefix" {
  default = "sadey2k-aks"
}

variable "agent_count" {
  default = 2
}

# variable "aks_service_principal_app_id" {

# }

# variable "aks_service_principal_client_secret" {

# }

variable "location" {
  default = "ukwest"
}

variable "kubernetes_version" {
  default = "1.22"
}

# variable "ssh_public_key" {
#   default = "$HOME/.ssh/aks-prod-sshkeys/aksprodsshkey.pub"
# }

variable "tags" {
  default = "DEVELOPMENT"
}

variable "keyvault_rg" {
  default = "kv-rg-DEVELOPMENT"
}

variable "keyvault_name" {
  default = "keyvaultsade-DEVELOPMENT"
}

variable "access_key" {
  default = "backend-sa-access-key-DEVELOPMENT"
}

variable "sshkvsecret" {
  default = "aks-ssh-keysecret-DEVELOPMENT"
}

variable "clientidkv" {
  default = "keyvault-sp-id-DEVELOPMENT"
}

variable "spnkvsecret" {
  default = "keyvault-sp-secret-DEVELOPMENT"
}