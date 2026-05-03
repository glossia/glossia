variable "hcloud_token" {
  description = "Hetzner Cloud API token with read/write access."
  type        = string
  sensitive   = true
}

variable "cluster_name" {
  description = "Shared prefix for the Kubernetes cluster resources."
  type        = string
  default     = "glossia"
}

variable "location" {
  description = "Hetzner location used for both nodes and load balancers."
  type        = string
  default     = "fsn1"
}

variable "network_region" {
  description = "Hetzner network region for the private cluster network."
  type        = string
  default     = "eu-central"
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key used for cluster access."
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "ssh_private_key_path" {
  description = "Path to the SSH private key used for cluster access."
  type        = string
  default     = "~/.ssh/id_ed25519"
}

variable "microos_x86_snapshot_id" {
  description = "Optional Hetzner image ID for the x86 MicroOS snapshot. When unset, kube-hetzner discovers the latest labeled snapshot."
  type        = string
  default     = ""
}

variable "microos_arm_snapshot_id" {
  description = "Optional Hetzner image ID for the ARM MicroOS snapshot. When unset, kube-hetzner discovers the latest labeled snapshot."
  type        = string
  default     = ""
}

variable "kubeconfig_server_address" {
  description = "Optional DNS name for the kubeconfig server endpoint."
  type        = string
  default     = ""
}

variable "create_kubeconfig" {
  description = "Whether Terraform should write a kubeconfig file locally."
  type        = bool
  default     = true
}

variable "automatically_upgrade_os" {
  description = "Whether kube-hetzner should keep MicroOS automatic upgrades enabled. Defaults to true for HA control planes and false for smaller clusters."
  type        = bool
  default     = null
  nullable    = true
}

variable "control_plane_count" {
  description = "Odd number of control plane nodes for etcd quorum."
  type        = number
  default     = 3
}

variable "control_plane_server_type" {
  description = "Hetzner server type for control plane nodes."
  type        = string
  default     = "cx23"
}

variable "app_node_count" {
  description = "Number of general-purpose worker nodes for the web workload."
  type        = number
  default     = 2
}

variable "app_node_server_type" {
  description = "Hetzner server type for the app worker pool."
  type        = string
  default     = "cx23"
}

variable "stateful_node_count" {
  description = "Number of worker nodes reserved for stateful workloads."
  type        = number
  default     = 3
}

variable "stateful_node_server_type" {
  description = "Hetzner server type for the stateful worker pool."
  type        = string
  default     = "cx33"
}

variable "load_balancer_type" {
  description = "Hetzner load balancer type for ingress traffic."
  type        = string
  default     = "lb11"
}

variable "control_plane_lb_type" {
  description = "Hetzner load balancer type for the Kubernetes API."
  type        = string
  default     = "lb11"
}

variable "etcd_s3_backup" {
  description = "Optional k3s etcd snapshot configuration for an S3-compatible object store."
  type        = map(string)
  default     = {}
  sensitive   = true
}
