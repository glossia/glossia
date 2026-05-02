locals {
  ssh_public_key_path  = pathexpand(var.ssh_public_key_path)
  ssh_private_key_path = pathexpand(var.ssh_private_key_path)
  automatically_upgrade_os = (
    var.automatically_upgrade_os != null
    ? var.automatically_upgrade_os
    : var.control_plane_count >= 3
  )
}

module "kube_hetzner" {
  source = "git::https://github.com/kube-hetzner/terraform-hcloud-kube-hetzner.git?ref=8d32f4ca8a61926526171456e93ddf0a6680724a"

  providers = {
    hcloud = hcloud
  }

  hcloud_token = var.hcloud_token

  cluster_name              = var.cluster_name
  network_region            = var.network_region
  load_balancer_location    = var.location
  load_balancer_type        = var.load_balancer_type
  use_control_plane_lb      = true
  control_plane_lb_type     = var.control_plane_lb_type
  create_kubeconfig         = var.create_kubeconfig
  kubeconfig_server_address = var.kubeconfig_server_address

  ssh_public_key          = file(local.ssh_public_key_path)
  ssh_private_key         = file(local.ssh_private_key_path)
  microos_x86_snapshot_id = var.microos_x86_snapshot_id
  microos_arm_snapshot_id = var.microos_arm_snapshot_id

  ingress_controller                = "traefik"
  enable_cert_manager               = true
  enable_local_storage              = false
  allow_scheduling_on_control_plane = false
  automatically_upgrade_os          = local.automatically_upgrade_os

  etcd_s3_backup = var.etcd_s3_backup

  control_plane_nodepools = [
    {
      name        = "control-plane"
      server_type = var.control_plane_server_type
      location    = var.location
      labels      = []
      taints      = []
      count       = var.control_plane_count
    }
  ]

  agent_nodepools = [
    {
      name        = "app"
      server_type = var.app_node_server_type
      location    = var.location
      labels      = []
      taints      = []
      count       = var.app_node_count
    },
    {
      name        = "stateful"
      server_type = var.stateful_node_server_type
      location    = var.location
      labels      = ["node-role.glossia.ai/stateful=true"]
      taints      = ["node-role.glossia.ai/stateful=true:NoSchedule"]
      count       = var.stateful_node_count
    }
  ]

  traefik_merge_values = yamlencode({
    service = {
      annotations = {
        "load-balancer.hetzner.cloud/location" = var.location
      }
    }
  })
}
