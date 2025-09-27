variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "sit722-rg"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "Australia East"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "container_registry_name" {
  description = "Name of the Azure Container Registry"
  type        = string
  default     = "sit722acr01"
}

variable "aks_cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
  default     = "sit722-aks"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
}

variable "node_count" {
  description = "Number of nodes in the default node pool"
  type        = number
  default     = 2
}

variable "vm_size" {
  description = "Size of the VMs in the node pool"
  type        = string
  default     = "Standard_D2s_v3"
}
