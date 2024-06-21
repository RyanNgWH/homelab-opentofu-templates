# Proxmox datacenter firewall configuration
# ---
# Firewall configurations on the proxmox datacenter.

locals {
  # Instance aliases
  proxmox_firewall_datacenter_instance_aliases_configs = {
    for key, instance in proxmox_virtual_environment_vm.cloud_init_instances :
    key => {
      name    = instance.name
      cidr    = instance.ipv4_addresses[1][0]
      comment = "[${title(instance.name)}] ${instance.description}"
    }
  }

  # Manual aliases
  proxmox_firewall_datacenter_manual_aliases       = yamldecode(file("configs/firewall/datacenter.aliases.config.yaml"))
  proxmox_firewall_datacenter_manual_alias_configs = { for alias in local.proxmox_firewall_datacenter_manual_aliases : alias.name => alias }

  # All aliases
  proxmox_firewall_datacenter_all_aliases_configs = merge(local.proxmox_firewall_datacenter_instance_aliases_configs, local.proxmox_firewall_datacenter_manual_alias_configs)

  # Firewall ipsets
  proxmox_datacenter_firewall_ipsets        = yamldecode(file("configs/firewall/datacenter.ipsets.config.yaml"))
  proxmox_datacenter_firewall_ipset_configs = { for ipset in local.proxmox_datacenter_firewall_ipsets : ipset.name => ipset }
}

# Aliases
resource "proxmox_virtual_environment_firewall_alias" "datacenter" {
  for_each = local.proxmox_firewall_datacenter_all_aliases_configs

  name    = each.value.name
  cidr    = each.value.cidr
  comment = each.value.comment
}

# Firewall ipsets
resource "proxmox_virtual_environment_firewall_ipset" "datacenter" {
  for_each = local.proxmox_datacenter_firewall_ipset_configs

  name    = each.value.name
  comment = each.value.comment

  dynamic "cidr" {
    for_each = each.value.children
    iterator = child

    content {
      name    = proxmox_virtual_environment_firewall_alias.datacenter[child.value].name
      comment = proxmox_virtual_environment_firewall_alias.datacenter[child.value].comment
    }
  }
}
