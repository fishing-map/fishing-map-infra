locals {
  # Common tags
  common_tags = [
    var.project_name,
    var.environment,
    "terraform"
  ]

  # Resource naming
  resource_prefix = "${var.project_name}-${var.environment}"

  # SSH key path
  ssh_public_key = fileexists(var.ssh_public_key_path) ? file(var.ssh_public_key_path) : ""
}
