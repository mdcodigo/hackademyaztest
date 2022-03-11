terraform {
  backend "azurerm" {
    resource_group_name  = "rghackademytf"
    storage_account_name = "hacktamedysa0x008"
    container_name       = "tfstate"
    key                  = "prod.terraform.tfstate"
  }

  required_providers {
    azurerm = {
      version = "~> 2.19"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rghackamedy" {
  name     = "rghackademy"
  location = "eastus"
}

locals {
  common_tags = {
    Terraform   = "true"
    Environment = "hackademy"
  }
}

//// #1 LogAnalitics
module "LogAnalitycs" {
  source              = "./Modules/LogAnalitycs"
  name                = var.loganalytics_name
  depends_on          = [azurerm_resource_group.rghackamedy]        // Dependencia Explicita.
  resource_group_name = azurerm_resource_group.rghackamedy.name     // Dependencia implicita
  location            = azurerm_resource_group.rghackamedy.location // Dependencia implicita
  sku                 = "Standalone"
  tags                = local.common_tags
  solutions = [
    {
      solution_name = "AzureActivity",
      publisher     = "Microsoft",
      product       = "OMSGallery/AzureActivity",
    },
  ]
}
//////// LogAnalitics ////////

//////// #2 SQLServer ////////
module "SQLServer" {
  source                       = "./Modules/SQLServer"
  depends_on                   = [module.LogAnalitycs]
  location                     = azurerm_resource_group.rghackamedy.location //Dependencia implicita
  sc_name                      = "holaychao"
  sqlserver_name               = var.sqlserver_name //== null ? "sqlserver${random_string.str.result}" : var.sqlserver_name
  db_name                      = var.db_name
  admin_username               = var.admin_username
  admin_password               = var.admin_password
  sql_database_edition         = "Standard"
  sqldb_service_objective_name = "S1"
  resource_group_name          = azurerm_resource_group.rghackamedy.name
  log_analytics_workspace_id   = module.LogAnalitycs.resource_id
  log_retention_days           = 7

  firewall_rules = [
    {
      name             = "access-to-azure"
      start_ip_address = "0.0.0.0"
      end_ip_address   = "0.0.0.0"
    },
    {
      name             = "desktop-ip"
      start_ip_address = "190.105.33.1"
      end_ip_address   = "190.105.33.254"
    }
  ]
  tags = local.common_tags
}
//////// SQLServer ////////


/*
//// #5 FrontDoor
module "Frontdoor" {
  source              = "./modules/FrontDoor"
  tags                = local.common_tags
  frontdoorname       = var.frontdoor_name
  location            = "Global"
  resource_group_name = "rghackademy"
  enforcebpcert       = "false"
  backendpoolname     = "myservers"
  acceptedprotocols   = ["Http"]
  patternstomatch     = ["/*"]
  frontend_endpoint = {
    name      = var.frontdoor_name
    host_name = "${var.frontdoor_name}.azurefd.net"
  }

  routing_rule = {
    rr1 = {
      name               = var.frontdoor_name
      frontend_endpoints = [var.frontdoor_name]
      accepted_protocols = ["Http", "Https"]
      patterns_to_match  = ["/*"]
      enabled            = true
      configuration      = "Forwarding"
      forwarding_configuration = {
        backend_pool_name                     = "misservers"
        cache_enabled                         = false
        cache_use_dynamic_compression         = false
        cache_query_parameter_strip_directive = "StripNone"
        custom_forwarding_path                = ""
        forwarding_protocol                   = "MatchRequest"
      }
      redirect_configuration = {
        custom_host         = ""
        redirect_protocol   = "MatchRequest"
        redirect_type       = "Found"
        custom_path         = ""
        custom_query_string = ""
      }
    }
  }

  ///////////////////////////
  backend_pool_load_balancing = {
    lb1 = {
      name                            = "exampleLoadBalancingSettings1"
      sample_size                     = 4
      successful_samples_required     = 2
      additional_latency_milliseconds = 0
    }
  }
  ///////////////////////////

  backend_pool_health_probe = {
    hp1 = {
      name                = "exampleHealthProbeSetting1"
      path                = "/"
      protocol            = "Http"
      interval_in_seconds = 120
    }
  }
  ////////////////////////////
  front-door-object-backend-pool = {
    backend_pool = {
      bp1 = {
        name = "misservers"
        backend = {
          app1 = {
            enabled     = true
            address     = join(",", module.Appservice.*.RGCU001.app_service_default_site_hostname)
            host_header = join(",", module.Appservice.*.RGCU001.app_service_default_site_hostname)
            http_port   = 80
            https_port  = 443
            priority    = 1
            weight      = 50
          }
        }
        load_balancing_name = "exampleLoadBalancingSettings1"
        health_probe_name   = "exampleHealthProbeSetting1"

      }
    }
  }
}
//////////// FrontDoor ////////////
*/
