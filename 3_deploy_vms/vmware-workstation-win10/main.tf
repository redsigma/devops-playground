locals {
  environment = "${lookup(var.workspace_to_environment_map, terraform.workspace, "dev")}"
  size = "${local.environment == "dev" ? lookup(var.workspace_to_size_map, terraform.workspace, "") : var.environment_to_size_map[local.environment]}"
}


module "variables" {
  source = "modules/variables"
  environment = "${local.environment}"
  size        = "${local.size}"
}


terraform {
  required_providers {
    vmworkstation = {
      source  = "elsudano/vmworkstation"
      version = "1.0.4"
    }
  }
}

provider "vmworkstation" {
  user     = var.vmws_user
  password = var.vmws_password
  url      = var.vmws_url
  https    = false
  debug    = true
}

resource "vmworkstation_vm" "win10" {
  sourceid     = var.vm_source_id
  denomination = var.vm_name
  description  = "Windows 10 VM"
}