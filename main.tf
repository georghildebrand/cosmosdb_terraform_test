provider "azurerm" {
    version = "=2.23"
    features {}
    subscription_id = var.subid
}

variable "subid" {
    type = string
    description = "The subscription ID"
}

locals {
  rg_name = "cosmostest"
  location =  "westeurope"
  failover_location = "northeurope"
}


resource "azurerm_resource_group" "rg" {
  name     = local.rg_name
  location = local.location
}

resource "random_integer" "ri" {
  min = 10000
  max = 99999
}

resource "azurerm_cosmosdb_account" "db" {
  name                = "tfex-cosmos-db-${random_integer.ri.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  enable_automatic_failover = true

  capabilities {
    name = "EnableGremlin" # this one is really important
  }

  consistency_policy {
    consistency_level       = "BoundedStaleness"
    max_interval_in_seconds = 301
    max_staleness_prefix    = 100001
  }

  geo_location {
    location          = local.failover_location
    failover_priority = 1
  }

  geo_location {
    prefix            = "tfex-cosmos-db-${random_integer.ri.result}-customid"
    location          = azurerm_resource_group.rg.location
    failover_priority = 0
  }
}


resource "azurerm_cosmosdb_gremlin_database" "gremlindb" {
  name                = "gremlindb-cosmos"
  resource_group_name = azurerm_cosmosdb_account.db.resource_group_name
  account_name        = azurerm_cosmosdb_account.db.name
}

resource "azurerm_cosmosdb_gremlin_graph" "gremlingraph" {
  name                = "gremlindb-cosmos-graph"
  resource_group_name = azurerm_cosmosdb_account.db.resource_group_name
  account_name        = azurerm_cosmosdb_account.db.name
  database_name       = azurerm_cosmosdb_gremlin_database.gremlindb.name
  partition_key_path  = "/Example" # this is needed to split on the 25GB partition size limit
  throughput          = 400

  index_policy {
    automatic      = true
    indexing_mode  = "Consistent"
    included_paths = ["/*"]
    excluded_paths = ["/\"_etag\"/?"]
  }

  conflict_resolution_policy {
    mode                     = "LastWriterWins"
    conflict_resolution_path = "/_ts"
  }

# https://docs.microsoft.com/de-de/azure/cosmos-db/unique-keys
  unique_key {
    paths = ["/definition/id1", "/definition/id2"]
  }
}
