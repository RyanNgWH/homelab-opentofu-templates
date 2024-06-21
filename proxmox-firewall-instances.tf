# Proxmox instances firewall configuration
# ---
# Firewall configurations on individual proxmox instances.

locals {
  # Every instance should have a firewall rules config file
  proxmox_firewall_instance_vm_rules_configs = {
    for key, instance in proxmox_virtual_environment_vm.cloud_init_instances :
    key => {
      node_name = instance.node_name
      vm_id     = instance.id

      rules = concat(
        flatten([
          for preset in try(yamldecode(file("configs/firewall/${key}.rules.config.yaml")), { presets = [] }).presets :
          yamldecode(templatefile(
            "configs/firewall/instance.${preset.name}.rules.config.tftpl",
            {
              # Basic rules variables
              lan_airport_privilege_ipset = "${proxmox_virtual_environment_firewall_ipset.datacenter["lan_airport_privilege"].name}"
              host_alias                  = proxmox_virtual_environment_firewall_alias.datacenter[key].name
              host_name                   = title(instance.name)
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

resource "proxmox_virtual_environment_firewall_rules" "vm_instances" {
  # Skip instances which do not have any rules specified
  for_each = { for key, value in local.proxmox_firewall_instance_vm_rules_configs : key => value if length(value.rules) > 0 }

  node_name = each.value.node_name
  vm_id     = each.value.vm_id

  dynamic "rule" {
    for_each = each.value.rules
    iterator = rule

    content {
      action  = try(rule.value.action, "")
      type    = try(rule.value.type, "")
      comment = "[Opentofu] ${try(rule.value.comment, "")}"
      dest    = try(rule.value.dest, "") == "" ? "" : "${rule.value.dest_ipset ? "+" : ""}dc/${rule.value.dest}"
      dport   = try(rule.value.dport, "")
      log     = try(rule.value.log, "nolog")
      macro   = try(rule.value.macro, "")
      proto   = try(rule.value.proto, "")
      source  = try(rule.value.source, "") == "" ? "" : "${rule.value.source_ipset ? "+" : ""}dc/${rule.value.source}"
      sport   = try(rule.value.sport, "")
    }
  }
}
