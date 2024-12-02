# Generic Variables
pdu       = "dc-cnv"
tenant_id = "96f1f6e9-1057-4117-ac28-80cdfe86f8c3"
subscription_id = {
  sbox = "c148e383-4df1-45fd-aa72-e060e8aa7fdd"
  devt = "0dd944af-384e-40b3-aad2-0b164916a51a"
  test = "d3149529-33df-4c0a-8959-ce626c696a02"
  stag = "92aa2c20-6016-4b42-9d2c-7673f39e98ac"
  prod = "4b43654a-ba5d-4b5f-9ca4-3d7708c175de"
}
ss_subscription_id = {
  sbox = "67e5f2ee-6e0a-49e3-b533-97f0beec351c"
  devt = "67e5f2ee-6e0a-49e3-b533-97f0beec351c"
  test = "67e5f2ee-6e0a-49e3-b533-97f0beec351c"
  stag = "7e97df51-9a8e-457a-ab7a-7502a771bb36"
  prod = "7e97df51-9a8e-457a-ab7a-7502a771bb36"
}
location = "uksouth"
# Asset Tag Variables
tags = {
  "Name"                    = "NGCC Conversational Platform"
  "Application"             = "Next Generation Contact Centre (current PSN-CC service)"
  "Function"                = "Digital Modernisation & Efficiency"
  "Persistence"             = "False"
  "Role"                    = "PDU Blueprint"
  "Spot_enabled"            = "False"
  "Business-Project"        = "PRJ0043667"
  # "Billing Identifier"     = "dc-cnv"
  # "Department"             = "Health"
  # "Environment Version"    = "1.0"
  # "Project Identifier"     = "Health Data & Analytics Platform"
  # "Service Name"           = "Health Data & Analytics Platform"
  # "Service Owner"          = "Stephen Southern"
  # "Service Window"         = "NOT SET"
}
# Selectors
enable_locks                 = false
spn_full_owner               = false # (should be false by default, PDU should not have the permission to change RBAC permissions, policies or network settings. If they need to do this after the envirnonment is deployed, set to true")
deploy_sqlmi_subnet          = false # sqlmi subnet addresses have been used for mysql-fs-01 so need to assign new addreses to that subnet before enabling this
deploy_redis_subnet          = true
deploy_modern_data_warehouse = false
deploy_fe03_subnet           = false
deploy_container_registry    = false
disable_nsg_policy           = true # should always be set to false, unless you need to delete a subnet and associated NSG.
deploy_azure_bastion = {
  sbox = false
  devt = false
  test = false
  stag = false
  prod = false
}
# Network Variables
vnet_address_spaces = {
  sbox = [
    "10.88.96.0/23",  # frontend
    "172.27.96.0/23", # backend
    "192.168.56.0/25" # spare
  ]
  devt = [
    "10.89.96.0/23",  # frontend
    "172.26.96.0/23", # backend
    # TODO: range below is included in AZ-CH-PNS-STAG
    "10.87.99.0/25" # spare
  ]
  test = [
    "10.102.96.0/23", # frontend
    "172.25.96.0/23", # backend
    "10.87.98.0/25"   # spare
  ]
  stag = [
    "10.103.96.0/23", # frontend
    "172.23.96.0/23", # backend
    "10.87.97.0/25"   # spare
  ]
  prod = [
    "10.105.96.0/23", # frontend
    "172.21.96.0/23", # backend
    "10.87.96.0/25"   # spare
  ]
}
vnet_dns_servers = {
  sbox = ["10.86.33.132", "10.86.33.133"]
  devt = ["10.86.33.132", "10.86.33.133"]
  test = ["10.86.33.132", "10.86.33.133"]
  stag = []
  prod = []
}
fe01_subnet_cidr = {
  sbox = ["10.88.96.0/26"]
  devt = ["10.89.96.0/26"]
  test = ["10.102.96.0/26"]
  stag = ["10.103.96.0/26"]
  prod = ["10.105.96.0/26"]
}
fe02_subnet_cidr = {
  sbox = ["10.88.97.0/26"]
  devt = ["10.89.97.0/26"]
  test = ["10.102.97.0/26"]
  stag = ["10.103.97.0/26"]
  prod = ["10.105.97.0/26"]
}
# FE03 subnet (first three octets from  fe02)
fe03_subnet_cidr = {
  sbox = ["10.88.97.64/26"]
  devt = ["10.89.97.64/26"]
  test = ["10.102.97.64/26"]
  stag = ["10.103.97.64/26"]
  prod = ["10.105.97.64/26"]
}
# / FE03 subnet
be01_subnet_cidr = {
  sbox = ["172.27.96.0/26"]
  devt = ["172.26.96.0/26"]
  test = ["172.25.96.0/26"]
  stag = ["172.23.96.0/26"]
  prod = ["172.21.96.0/26"]
}
be02_subnet_cidr = {
  sbox = ["172.27.97.0/26"]
  devt = ["172.26.97.0/26"]
  test = ["172.25.97.0/26"]
  stag = ["172.23.97.0/26"]
  prod = ["172.21.97.0/26"]
}
# SQL Managed Instance ( # first three octets should match backend address space)
## Note: these address spaces are used by mysql-fs-01
## so if you a subnet for sqlmi find other addresses
sqlmi01_subnet_cidr = {
  sbox = ["172.27.96.224/27"]
  devt = ["172.26.96.224/27"]
  test = ["172.25.96.224/27"]
  stag = ["172.23.96.224/27"]
  prod = ["172.21.96.224/27"]
}
# Redis Cache ( # first three octets should match backend address space)
redis01_subnet_cidr = {
  sbox = ["172.27.96.192/27"]
  devt = ["172.26.96.192/27"]
  test = ["172.25.96.192/27"]
  stag = ["172.23.96.192/27"]
  prod = ["172.21.96.192/27"]
}
# AzureBastionSubnet ( # first three octets should match spare address space)
bastion_subnet_cidr = {
  sbox = ["192.168.56.0/27"]
  devt = ["10.87.99.0/27"]
  test = ["10.87.98.0/27"]
  stag = ["10.87.97.0/27"]
  prod = ["10.87.96.0/27"]
}
# Monitor Variables #####################################################

sre_team_webhook = {
  sbox = "https://events.pagerduty.com/integration/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX/enqueue"
  devt = "https://events.pagerduty.com/integration/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX/enqueue"
  test = "https://events.pagerduty.com/integration/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX/enqueue"
  stag = "https://events.pagerduty.com/integration/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX/enqueue"
  prod = "https://events.pagerduty.com/integration/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX/enqueue"
}

sre_team_email = {
  sbox = "sre.azure@engineering.digital.dwp.gov.uk"
  devt = "sre.azure@engineering.digital.dwp.gov.uk"
  test = "sre.azure@engineering.digital.dwp.gov.uk"
  stag = "sre.azure@engineering.digital.dwp.gov.uk"
  prod = "sre.azure@engineering.digital.dwp.gov.uk"
}

app_team_email = {
  sbox = "dwptest@engineering.digital.dwp.gov.uk"
  devt = "dwptest@engineering.digital.dwp.gov.uk"
  test = "dwptest@engineering.digital.dwp.gov.uk"
  stag = "dwptest@engineering.digital.dwp.gov.uk"
  prod = "dwptest@engineering.digital.dwp.gov.uk"
}

secmon_team_email = {
  sbox = "crc.smi@dwp.gov.uk"
  devt = "crc.smi@dwp.gov.uk"
  test = "crc.smi@dwp.gov.uk"
  stag = "crc.smi@dwp.gov.uk"
  prod = "crc.smi@dwp.gov.uk"
}

sre_team_alert_status = {
  sbox = false
  devt = false
  test = false
  stag = false
  prod = true
}

app_team_alert_status = {
  sbox = true
  devt = true
  test = true
  stag = true
  prod = true
}

secmon_team_alert_status = {
  sbox = true
  devt = true
  test = true
  stag = true
  prod = true
}

dwp_sre_actiongroup_rg = {
  sbox = "Role-PDU-TS-SRE-DEVT-ActionGroupReaders"
  devt = "Role-PDU-TS-SRE-DEVT-ActionGroupReaders"
  test = "Role-PDU-TS-SRE-DEVT-ActionGroupReaders"
  stag = "Role-PDU-TS-SRE-STAG-ActionGroupReaders"
  prod = "Role-PDU-TS-SRE-PROD-ActionGroupReaders"
}

## Monitoring Threshold Variables ########################################

# Azure Site Recovery - instances with RPO over 30 mins
log_alert_asr_rpo_greater_than_30m_threshold = {
  sbox = 2
  devt = 2
  test = 2
  stag = 2
  prod = 2
}

# Azure Site Recovery - instances with ReplicationHealthStatus or FailoverHealthStatus Critical
log_alert_asr_replication_critical_threshold = {
  sbox = 2
  devt = 2
  test = 2
  stag = 2
  prod = 2
}

# Azure Site Recovery - recovery job failure
log_alert_asr_recovery_job_fail_threshold = {
  sbox = 2
  devt = 2
  test = 2
  stag = 2
  prod = 2
}

# VM, Linux - % Inodes in use - Warning
log_alert_vm_inodes_warning_threshold = {
  sbox = 85
  devt = 85
  test = 85
  stag = 85
  prod = 85
}

# VM, Linux - % Inodes in use - Critical
log_alert_vm_inodes_critical_threshold = {
  sbox = 90
  devt = 90
  test = 90
  stag = 90
  prod = 90
}

# VM, Linux - Logical Volume space used - Warning
log_alert_vm_logical_disk_warning_threshold = {
  sbox = 90
  devt = 90
  test = 90
  stag = 90
  prod = 90
}

# VM, Linux - Logical Volume space used - Critical
log_alert_vm_logical_disk_critical_threshold = {
  sbox = 95
  devt = 95
  test = 95
  stag = 95
  prod = 95
}

environment_tags = {
  sbox = "Dev"
  devt = "Dev"
  test = "Test"
  stag = "Stage"
  prod = "Production"
}

file_share_size = {
    "omilia":          { "sbox": 50, "devt": 50, "test": 50, "stag": 50, "prod": 50 },
    "logs":            { "sbox": 100, "devt": 3400, "test": 100, "stag": 100, "prod": 3400 },
    "recordings":      { "sbox": 100, "devt": 3400, "test": 100, "stag": 100, "prod": 3400 },
  }

lb_ip = {
  devt = "10.86.48.200"
  test = "10.86.52.202"
  stag = "10.86.97.200"
  prod = "10.86.101.200"
}
