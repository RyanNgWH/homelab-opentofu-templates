# Proxmox datacenter firewall configuration
# ---
# Firewall configurations on the proxmox datacenter.

locals {
  proxmox_firewall_datacenter_no_alias_list = [
    "ansible-lxc"
  ]

  # Instance aliases
  proxmox_firewall_datacenter_instance_aliases_configs = merge(
    # VM cloud-init instances
    {
      for key, instance in proxmox_virtual_environment_vm.cloud_init_instances :
      "${instance.name}_${key}" => {
        name    = "${instance.name}_${key}"
        cidr    = split("/", local.proxmox_cloud_init_instance_configs[key].cloud_init_ipv4)[0]
        comment = "[${title(instance.name)}] ${instance.description}"
      }
      # Ansible development environment does not need firewall alias
      if !contains(local.proxmox_firewall_datacenter_no_alias_list, key)
    },
    # LXC instances
    {
      for key, instance in proxmox_virtual_environment_container.instances :
      "${instance.initialization[0].hostname}_${key}" => {
        name    = "${instance.initialization[0].hostname}_${key}"
        cidr    = split("/", instance.initialization[0].ip_config[0].ipv4[0].address)[0]
        comment = "[${title(instance.initialization[0].hostname)}] ${trimspace(instance.description)}"
      }
      # Ansible development environment does not need firewall alias
      if !contains(local.proxmox_firewall_datacenter_no_alias_list, key)
    }
  )

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
  comment = "[Opentofu] ${each.value.comment}"
}

# Firewall ipsets
resource "proxmox_virtual_environment_firewall_ipset" "datacenter" {
  for_each = local.proxmox_datacenter_firewall_ipset_configs

  name    = each.value.name
  comment = "[Opentofu] ${each.value.comment}"

  dynamic "cidr" {
    for_each = each.value.children
    iterator = child

    content {
      name    = "dc/${proxmox_virtual_environment_firewall_alias.datacenter[child.value].name}"
      comment = proxmox_virtual_environment_firewall_alias.datacenter[child.value].comment
    }
  }
}
