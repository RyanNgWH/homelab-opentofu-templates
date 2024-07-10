# Proxmox instances firewall configuration
# ---
# Firewall configurations on individual proxmox instances.

locals {
  proxmox_firewall_all_instances = merge(proxmox_virtual_environment_vm.cloud_init_instances, proxmox_virtual_environment_container.instances)

  # Every instance should have a firewall rules config file
  proxmox_firewall_instance_rules_configs = {
    for key, instance in local.proxmox_firewall_all_instances :
    key => {
      node_name = instance.node_name
      vm_id     = instance.id

      options = try(yamldecode(file("configs/firewall/${key}.rules.config.yaml")), { options = null }).options

      rules = concat(
        flatten([
          for preset in try(yamldecode(file("configs/firewall/${key}.rules.config.yaml")), { presets = [] }).presets :
          yamldecode(templatefile(
            "configs/firewall/instance.${preset.name}.rules.config.tftpl",
            {
              # Basic rules variables
              lan_airport_privilege_ipset = "${proxmox_virtual_environment_firewall_ipset.datacenter["lan_airport_privilege"].name}"
              host_alias                  = try(proxmox_virtual_environment_firewall_alias.datacenter["${instance.name}_${key}"].name, proxmox_virtual_environment_firewall_alias.datacenter["${instance.initialization[0].hostname}_${key}"].name)
              host_name                   = title(try(instance.name, instance.initialization[0].hostname))
              host_description            = instance.description

              # Uptime rules variables (to be changed when uptime vm is created)
              uptime_alias = "serene_uptime_kuma"
              uptime_name  = "Uptime Kuma"

              # Web rules variables
              source_alias          = try(preset.vars.source_alias, "\"\"")
              source_alias_is_ipset = try(preset.vars.source_alias_is_ipset, "false")
              source_description    = try(preset.vars.source_description, "")
              application           = try(preset.vars.application, "")
            }
          ))
        ]),
        try(yamldecode(file("configs/firewall/${key}.rules.config.yaml")), { specifics = [] }).specifics
      )
    }
  }
}

# Firewall rules
resource "proxmox_virtual_environment_firewall_rules" "all_instances" {
  # Skip instances which do not have any rules specified
  for_each = { for key, value in local.proxmox_firewall_instance_rules_configs : key => value if length(value.rules) > 0 }

  node_name = each.value.node_name
  vm_id     = each.value.vm_id

  dynamic "rule" {
    for_each = each.value.rules
    iterator = rule

    content {
      action  = try(rule.value.action, "")
      type    = try(rule.value.type, "")
      comment = "[Opentofu] ${try(rule.value.comment, "")}"
      dest    = try(rule.value.dest, "") == "" ? "" : "${rule.value.dest_ipset ? "+dc/${proxmox_virtual_environment_firewall_ipset.datacenter[rule.value.dest].name}" : "dc/${proxmox_virtual_environment_firewall_alias.datacenter[rule.value.dest].name}"}"
      dport   = try(rule.value.dest_port, "")
      log     = try(rule.value.log, "nolog")
      macro   = try(rule.value.macro, "")
      proto   = try(rule.value.protocol, "")
      source  = try(rule.value.source, "") == "" ? "" : "${rule.value.source_ipset ? "+dc/${proxmox_virtual_environment_firewall_ipset.datacenter[rule.value.source].name}" : "dc/${proxmox_virtual_environment_firewall_alias.datacenter[rule.value.source].name}"}"
      sport   = try(rule.value.source_port, "")
    }
  }
}

# Firewall options
resource "proxmox_virtual_environment_firewall_options" "all_instances" {
  # Skip instances which do not have any rules specified
  for_each = { for key, value in local.proxmox_firewall_instance_rules_configs : key => value if length(value.rules) > 0 }

  node_name = each.value.node_name
  vm_id     = each.value.vm_id

  enabled = try(each.value.options.enabled, true)

  dhcp          = try(each.value.options.dhcp, false)
  ndp           = try(each.value.options.ndp, false)
  ipfilter      = try(each.value.options.ipfilter, false)
  macfilter     = try(each.value.options.macfilter, true)
  log_level_in  = try(each.value.options.log_level_in, "nolog")
  log_level_out = try(each.value.options.log_level_out, "nolog")
  input_policy  = try(each.value.options.input_policy, "DROP")
  output_policy = try(each.value.options.output_policy, "ACCEPT")
  radv          = try(each.value.options.radv, false)
}
