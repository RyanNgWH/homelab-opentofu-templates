# Proxmox node firewall configuration
# ---
# Firewall configurations on node machines.

locals {
  # Nodes configuration
  proxmox_nodes_config = yamldecode(file("proxmox-firewall-nodes.config.yaml"))

  # LXC templates to upload
  proxmox_firewall_all_nodes = { for key, node in local.proxmox_nodes_config.nodes : key => node }

  # Every node should have a firewall rules config file
  proxmox_firewall_node_rules_configs = {
    for key, node in local.proxmox_firewall_all_nodes :
    key => {
      node_name = node.name

      options = try(yamldecode(file("configs/firewall/node.${node.name}.rules.config.yaml")), { options = null }).options

      rules = concat(
        flatten([
          for preset in try(yamldecode(file("configs/firewall/node.${node.name}.rules.config.yaml")), { presets = [] }).presets :
          yamldecode(templatefile(
            "configs/firewall/instance-preset.${preset.name}.rules.config.tftpl",
            {
              # Basic rules variables
              lan_airport_privilege_ipset = "${proxmox_virtual_environment_firewall_ipset.datacenter["lan_airport_privilege"].name}"
              host_alias                  = "${proxmox_virtual_environment_firewall_alias.datacenter["${node.name}_proxmox"].name}"
              host_name                   = title("${node.name}")
              host_description            = node.description

              # Uptime rules variables
              uptime_alias = try(proxmox_virtual_environment_firewall_alias.datacenter["uptime-kuma"].name, "serene_uptime-kuma")
              uptime_name  = "Uptime Kuma"

              # Node-exporter variables
              prometheus_alias = try(proxmox_virtual_environment_firewall_alias.datacenter["prometheus"].name, "melanie_prometheus")
              prometheus_name  = "Prometheus"

              # Web rules variables
              source_alias          = try(preset.vars.source_alias, "\"\"")
              source_alias_is_ipset = try(preset.vars.source_alias_is_ipset, "false")
              source_description    = try(preset.vars.source_description, "")
              application           = try(preset.vars.application, "")
            }
          ))
        ]),
        try(yamldecode(file("configs/firewall/node.${node.name}.rules.config.yaml")), { specifics = [] }).specifics
      )
    }
  }
}

# Firewall rules
resource "proxmox_virtual_environment_firewall_rules" "all_nodes" {
  # Skip nodes which do not have any rules specified
  for_each = { for key, value in local.proxmox_firewall_node_rules_configs : key => value if length(value.rules) > 0 }

  node_name = each.value.node_name

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
      source  = try(rule.value.source, null) == null ? "" : "${rule.value.source_ipset ? "+dc/${proxmox_virtual_environment_firewall_ipset.datacenter[rule.value.source].name}" : "dc/${proxmox_virtual_environment_firewall_alias.datacenter[rule.value.source].name}"}"
      sport   = try(rule.value.source_port, "")
    }
  }
}
