output "cluster_name" {
  description = "Shared suffix used across Hetzner and Kubernetes resources."
  value       = module.kube_hetzner.cluster_name
}

output "ingress_public_ipv4" {
  description = "Public IPv4 address for Traefik's Hetzner load balancer."
  value       = module.kube_hetzner.ingress_public_ipv4
}

output "control_plane_lb_ipv4" {
  description = "Public IPv4 address for the Kubernetes API load balancer."
  value       = module.kube_hetzner.lb_control_plane_ipv4
}

output "network_id" {
  description = "Hetzner private network backing the cluster."
  value       = module.kube_hetzner.network_id
}

output "kubeconfig" {
  description = "Kubeconfig content for the provisioned cluster."
  value       = module.kube_hetzner.kubeconfig
  sensitive   = true
}
