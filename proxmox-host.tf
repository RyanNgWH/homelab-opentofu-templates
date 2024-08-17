# Proxmox host configuration
# ---
# Proxmox host configurations on the cluster/datacenter.

locals {
  # LXC configuration
  proxmox_host_configs = yamldecode(file("proxmox-host.config.yaml"))
}

# DNS configuration
resource "proxmox_virtual_environment_dns" "all_nodes" {
  for_each = local.proxmox_host_configs

  node_name = each.key

  domain  = each.value.dns_domain
  servers = each.value.dns_servers
}

# Hosts file configuration
resource "proxmox_virtual_environment_hosts" "all_nodes" {
  for_each = local.proxmox_host_configs

  node_name = each.key

  dynamic "entry" {
    for_each = each.value.hosts
    iterator = entry

    content {
      address   = entry.value.address
      hostnames = entry.value.hostnames
    }
  }
}

# Time configuration
resource "proxmox_virtual_environment_time" "all_nodes" {
  for_each = local.proxmox_host_configs

  node_name = each.key

  time_zone = each.value.time_zone
}
