# Random suffix to guarantee a globally-unique Service Bus namespace name.
# Namespace names are a global DNS-style namespace across all of Azure, so
# "<project>-<environment>-sbns" alone will eventually collide with someone
# else's deployment. Persisting this in state means the suffix is generated
# once and then stays stable across subsequent plans/applies.
resource "random_id" "suffix" {
  byte_length = 3
}

# Service Bus - namespace
resource "azurerm_servicebus_namespace" "sbus" {
  name                = "${var.project}-${var.environment}-sbns-${random_id.suffix.hex}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = local.tags

  local_auth_enabled  = false
  minimum_tls_version = "1.2"
  network_rule_set {
    default_action                 = "Allow"
    public_network_access_enabled = true
    trusted_services_allowed      = false
  }
  public_network_access_enabled = true
  sku                            = "Standard"
}

# Service Bus - queue01
resource "azurerm_servicebus_queue" "queue01" {
  name         = "queue01"
  namespace_id = azurerm_servicebus_namespace.sbus.id

  default_message_ttl                     = "P14D"
  dead_lettering_on_message_expiration    = false
  duplicate_detection_history_time_window = "PT10M"
  enable_batched_operations               = true
  enable_partitioning                     = false
  lock_duration                           = "PT1M"
  max_delivery_count                      = 10
  max_size_in_megabytes                   = 1024
  requires_duplicate_detection            = false
  requires_session                        = false
}

# Service Bus - queue02
resource "azurerm_servicebus_queue" "queue02" {
  name         = "queue02"
  namespace_id = azurerm_servicebus_namespace.sbus.id

  default_message_ttl                     = "P14D"
  dead_lettering_on_message_expiration    = false
  duplicate_detection_history_time_window = "PT10M"
  enable_batched_operations               = true
  enable_partitioning                     = false
  lock_duration                           = "PT1M"
  max_delivery_count                      = 10
  max_size_in_megabytes                   = 1024
  requires_duplicate_detection            = false
  requires_session                        = false
}
