# Proxmox provider
# ---
# OpenTofu variables for infrastructure deployment on Proxmox
# Variable details can be found at https://registry.terraform.io/providers/bpg/proxmox/latest/docs

# Required variables
# ---
# Proxmox connection
proxmox_endpoint         = "https://your-server/"
proxmox_api_token_id     = "opentofu@pam!opentofu"
proxmox_api_token_secret = "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"

# SSH
proxmox_ssh_username    = "opentofu"
proxmox_ssh_private_key = "/path/to/your/ssh/private/key"

# Optional variables (default values are specified below)
# ---
