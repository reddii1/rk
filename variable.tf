## Generic Variables #####################################################

variable "subscription_id" {
  description = "The subscription id of where the resources will be deployed"
}
variable "tenant_id" {

}
variable "ss_subscription_id" {
  description = "The Shared Services subscription id"
}
variable "tags" {
  description = "tags to be applied to resources for billing purposes"
}

variable "location" {
  description = "The location/region where the core network will be created. The full list of Azure regions can be found at https://azure.microsoft.com/regions"
  default     = "uksouth"
}
variable "pdu" {
  description = "short name of the pdu for resource naming eg dw-ccc, dd-fed (directorate-subdirectorate)"

}
variable "vnet_address_spaces" {
  description = "cidr ranges for the vnet address spaces eg: [10.102.232.0/22, 172.25.232.0/22, 10.87.232.128/25]"

}
##  Selectors ############################################################

variable "deploy_fe03_subnet" {
  description = "true to deploy fe03 subnet, otherwise it won't be deployed"
  default     = false
}
variable "deploy_modern_data_warehouse" {
  description = "true to deploy fe03 subnet specifically for Modern Data Warehouse, otherwise it won't be deployed"
  default     = false
}
variable "deploy_container_registry" {
  description = "set to true to deploy an ACR with access granted to the SPN"
  default     = false
}
variable "deploy_sqlmi_subnet" {
  description = "true to deploy, otherwise it won't be deployed"
  default     = false
}
variable "deploy_redis_subnet" {
  description = "true to deploy, otherwise it won't be deployed"
  default     = false
}

variable "deploy_azure_bastion" {
  description = "true to deploy Azure Bastion, otherwise it won't be deployed"
  default     = false
}
variable "use_shared_services_dns" {
  description = "true to integrate private DNS with Shared Services core subscription"
  default     = false
}
variable "vnet_dns_servers" {
  description = "configures the VNET DNS servers for the private DNS"
}
variable "enable_locks" {
  default = false
}
variable "disable_nsg_policy" {
  description = "Policy prevents removing an NSG from a vnet - set this to true to disable the policy. Only for exceptional circumstances (eg deleting a subnet)"
  default     = false
}
variable "spn_full_owner" {
  description = "Should be set to false by default. If the PDU has a need to amend RBAC roles and policies, excluded from PDU Owner role, then they will need full owner"
}
## Network variables #####################################################

variable "fe01_subnet_cidr" {
  description = "Example: 10.102.232.0/24"
}
variable "fe02_subnet_cidr" {
  description = "Example: 10.102.232.0/24"
}
variable "fe03_subnet_cidr" {
  description = "Example: 10.102.232.0/24"
}
variable "be01_subnet_cidr" {
  description = "Example: 172.102.232.0/24"
}
variable "be02_subnet_cidr" {
  description = "Example: 172.102.232.0/24"
}

variable "sqlmi01_subnet_cidr" {
  description = "Example: 172.102.232.0/24"
}
variable "redis01_subnet_cidr" {
  description = "Example: 172.102.232.0/24"
}

variable "bastion_subnet_cidr" {
  description = "Example: 172.102.232.0/24"
}
## Monitoring Variables ##################################################

variable "dwp_sre_actiongroup_rg" {
  description = "Resource group for read only access to SRE managed ActionGroups"
}

variable "sre_team_webhook" {
  description = "A pager duty webhook for the sre team alerts"
}

variable "sre_team_email" {
  description = "An email address for the SRE team alerts"
  default     = "sre.azure@engineering.digital.dwp.gov.uk"
}

variable "app_team_email" {
  default = "dwptest@engineering.digital.dwp.gov.uk"
}

variable "secmon_team_email" {
  default = "crc.smi@dwp.gov.uk"
}

variable "sre_team_alert_status" {
  default = "enabled"
}

variable "app_team_alert_status" {
  default = "enabled"
}

variable "secmon_team_alert_status" {
  default = "enabled"
}

## Monitoring Threshold Variables ########################################

# Azure Site Recovery - instances with RPO over 30 mins
variable "log_alert_asr_rpo_greater_than_30m_threshold" {
  default = 2
}

# Azure Site Recovery - instances with ReplicationHealthStatus or FailoverHealthStatus Critical
variable "log_alert_asr_replication_critical_threshold" {
  default = 2
}

# Azure Site Recovery - recovery job failure
variable "log_alert_asr_recovery_job_fail_threshold" {
  default = 2
}

# VM, Linux - % Inodes in use - Warning
variable "log_alert_vm_inodes_warning_threshold" {
  default = 85
}

# VM, Linux - % Inodes in use - Critical
variable "log_alert_vm_inodes_critical_threshold" {
  default = 90
}

# VM, Linux - Logical Volume space used - Warning
variable "log_alert_vm_logical_disk_warning_threshold" {
  default = 90
}

# VM, Linux - Logical Volume space used - Critical
variable "log_alert_vm_logical_disk_critical_threshold" {
  default = 95
}

# Environment tags
variable "environment_tags" {
  description = "Standard environment tags according to tagging policy"
}

# Application Tag
variable "application_tag" {
  default     = "Next Generation Contact Centre (current PSN-CC service)"
  description = "Standard application tag according to tagging policy"
}

# Function Tag
variable "function_tag" {
  default     = "Technology Services"
  description = "Standard function tag according to tagging policy"
}

# Role Tag
variable "role_tag" {
  default     = "NGCC Conversational Platform"
  description = "Standard role tag according to tagging policy"
}

# Keyvaut FW
# variable "azureagentip" {
#   type        = string
#   description = "Keyvault Azure Devops IP"
# }

variable "slack_email_address_nonprod" {
  description = "The slack_email_address of the environment defined in local tfvars"
  default     = "j3d1c3h2p2e7k4g8@dwpdigital.slack.com"
}

variable "slack_email_address_prod" {
  description = "The slack_email_address of the environment defined in local tfvars"
  default     = "b5g0p5p2i7z0z2u3@dwpdigital.slack.com"
}
