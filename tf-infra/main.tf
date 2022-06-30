module "cluster" {
  source                              = "../tf-modules/cluster/"
  aks_rg_name                         = var.aks_rg_name
  log_analytics_workspace_name        = var.log_analytics_workspace_name
  aks_cluster_name                    = var.aks_cluster_name
  dns_prefix                          = var.dns_prefix
  agent_count                         = var.agent_count
#   aks_service_principal_app_id        = var.aks_service_principal_app_id
#   aks_service_principal_client_secret = var.aks_service_principal_client_secret
  location                            = var.location
  kubernetes_version                  = var.kubernetes_version
  #ssh_public_key                      = var.ssh_public_key
  tags                                = var.tags
  access_key                          = var.access_key
}