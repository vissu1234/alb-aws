variable "config_data" {
  type = map(object({
    location       = string
    common_labels  = optional(map(string), {})

    storage_pool = object({
      create_pool        = optional(bool, false)
      name               = string
      network_name       = optional(string)
      network_project_id = optional(string)
      service_level      = optional(string)
      size               = optional(number)
      description        = optional(string)
      labels             = optional(map(string), {})
      ldap_enabled       = optional(bool, false)
      ad_id              = optional(string)
      kms_config         = optional(string)
      zone               = optional(string)
      replica_zone       = optional(string)
      allow_auto_tiering = optional(bool)
    })

    storage_volumes = optional(map(object({

      name               = string
      size               = number
      share_name         = string
      protocols          = list(string)
      labels             = optional(map(string), {})
      smb_settings       = optional(list(string))
      unix_permissions   = optional(string)
      description        = optional(string)
      snapshot_directory = optional(bool)
      security_style     = optional(string)
      kerberos_enabled   = optional(bool)
      restricted_actions = optional(list(string))
      deletion_policy    = optional(string)

      backup_policies          = optional(list(string))
      backup_vault             = optional(string)
      scheduled_backup_enabled = optional(bool, true)

      multiple_endpoints = optional(bool)
      large_capacity     = optional(bool)

      export_policy_rules = optional(map(object({
        allowed_clients       = optional(string)
        has_root_access       = optional(string)
        access_type           = optional(string)
        nfsv3                 = optional(bool)
        nfsv4                 = optional(bool)
        kerberos5_read_only   = optional(bool)
        kerberos5_read_write  = optional(bool)
        kerberos5i_read_only  = optional(bool)
        kerberos5i_read_write = optional(bool)
        kerberos5p_read_only  = optional(bool)
        kerberos5p_read_write = optional(bool)
      })))

      snapshot_policy = optional(object({
        enabled = optional(bool, false)

        hourly_schedule = optional(object({
          snapshots_to_keep = optional(number)
          minute            = optional(number)
        }))

        daily_schedule = optional(object({
          snapshots_to_keep = optional(number)
          minute            = optional(number)
          hour              = optional(number)
        }))

        weekly_schedule = optional(object({
          snapshots_to_keep = optional(number)
          minute            = optional(number)
          hour              = optional(number)
          day               = optional(string)
        }))

        monthly_schedule = optional(object({
          snapshots_to_keep = optional(number)
          minute            = optional(number)
          hour              = optional(number)
          days_of_month     = optional(string)
        }))
      }))

      restore_parameters = optional(object({
        source_snapshot = optional(string)
        source_backup   = optional(string)
      }))

      tiering_policy = optional(object({
        cooling_threshold_days = number
        tier_action            = string
      }))

    })), {})
  }))
}
