module "cluster" {
  source                              = "../tf-modules/cluster/"
  aks_rg_name                         = var.aks_rg_name
  log_analytics_workspace_name        = var.log_analytics_workspace_name
  aks_cluster_name                    = var.aks_cluster_name
  dns_prefix                          = var.dns_prefix
  agent_count                         = var.agent_count
  location                            = var.location
  kubernetes_version                  = var.kubernetes_version
  tags                                = var.tags
  access_key                          = var.access_key
}