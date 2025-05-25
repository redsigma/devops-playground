# variable "vmws_user" {
#   description = "Username for VMware Workstation"
# }
# variable "vmws_password" {
#   description = "Password for VMware Workstation"
#   sensitive   = true
# }
# variable "vmws_url" {
#   description = "URL of VMware Workstation"
#   type        = string
#   default     = "http://127.0.0.1:8697"
# }
# variable "vm_name" {
#   description = "Name of the new VM to create"
#   default     = "Win10-TF-VM"
# }
# variable "vm_source_id" {
#   description = "ID of the source (template) VM to clone from"
# }

variable "workspace_to_environment_map" {
  type = "map"

  default = {
    dev     = "dev"
    qa      = "qa"
    staging = "staging"
    prod    = "prod"
  }
}

variable "environment_to_size_map" {
  type = "map"

  default = {
    dev     = "small"
    qa      = "medium"
    staging = "large"
    prod    = "xlarge"
  }
}

variable "workspace_to_size_map" {
  type = "map"

  default = {
    dev = "small"
  }
}
