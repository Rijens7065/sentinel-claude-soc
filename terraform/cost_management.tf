resource "azurerm_consumption_budget_resource_group" "main" {
  name              = "budget-sentinel-soc-prod-001"
  resource_group_id = azurerm_resource_group.main.id

  amount     = 50
  time_grain = "Monthly"

  time_period {
    start_date = formatdate("YYYY-MM-01'T'00:00:00'Z'", timestamp())
  }

  notification {
    enabled        = true
    threshold      = 80
    operator       = "GreaterThan"
    threshold_type = "Actual"

    contact_emails = []
    contact_roles  = ["Owner", "Contributor"]
  }

  notification {
    enabled        = true
    threshold      = 100
    operator       = "GreaterThan"
    threshold_type = "Actual"

    contact_emails = []
    contact_roles  = ["Owner", "Contributor"]
  }

  lifecycle {
    ignore_changes = [time_period]
  }
}
