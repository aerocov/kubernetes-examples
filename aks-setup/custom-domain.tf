locals {
  app_names = ["helloworld", "goodbyeworld"]
}

resource "azurerm_cdn_frontdoor_custom_domain" "app_domain" {
  for_each = toset(local.app_names)
  name                     = each.key
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.aks_frontdoor.id
  dns_zone_id              = azurerm_dns_zone.aks_dns_zone.id
  host_name                = "${each.key}.example.com"

  tls {
    certificate_type    = "ManagedCertificate"
    minimum_tls_version = "TLS12"
  }
}

resource "azurerm_cdn_frontdoor_endpoint" "frontdoor_endpoint" {
  for_each = toset(local.app_names)
  name                     = "${each.key}endpoint"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.aks_frontdoor.id
}

resource "azurerm_cdn_frontdoor_origin_group" "frontdoor_origin_group" {
  for_each = toset(local.app_names)
  name                                                      = "${each.key}-origin-group"
  cdn_frontdoor_profile_id                                  = azurerm_cdn_frontdoor_profile.aks_frontdoor.id
  session_affinity_enabled                                  = true
  restore_traffic_time_to_healed_or_new_endpoint_in_minutes = 5

  load_balancing {
    additional_latency_in_milliseconds = 0
    sample_size                        = 16
    successful_samples_required        = 3
  }
}

resource "azurerm_cdn_frontdoor_origin" "frontdoor_origin" {
  for_each = toset(local.app_names)
  name                          = "${each.key}-origin"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.frontdoor_origin_group[each.key].id
  enabled                       = true
  certificate_name_check_enabled = true

  host_name          = azurerm_public_ip.app_gateway_public_ip.ip_address
  http_port          = 80
  https_port         = 443
  priority           = 1
  weight             = 1000
}

resource "azurerm_cdn_frontdoor_route" "frontdoor_route" {
  for_each = toset(local.app_names)
  name                          = "${each.key}-route"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.frontdoor_endpoint[each.key].id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.frontdoor_origin_group[each.key].id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.frontdoor_origin[each.key].id]
  enabled                       = true

  forwarding_protocol    = "HttpOnly"
  https_redirect_enabled = true
  patterns_to_match      = ["/*"]
  supported_protocols    = ["Http", "Https"]

  cdn_frontdoor_custom_domain_ids = [azurerm_cdn_frontdoor_custom_domain.app_domain[each.key].id]
}

resource "azurerm_cdn_frontdoor_custom_domain_association" "custom_domain_association" {
  for_each = toset(local.app_names)
  cdn_frontdoor_custom_domain_id = azurerm_cdn_frontdoor_custom_domain.app_domain[each.key].id
  cdn_frontdoor_route_ids        = [azurerm_cdn_frontdoor_route.frontdoor_route[each.key].id]
}

resource "azurerm_dns_cname_record" "custom_domain_cname_record" {
  for_each = toset(local.app_names)
  name                = each.key
  zone_name           = azurerm_dns_zone.aks_dns_zone.name
  resource_group_name = azurerm_resource_group.rg.name
  ttl                 = 3600
  target_resource_id  = azurerm_cdn_frontdoor_endpoint.frontdoor_endpoint[each.key].id

  depends_on = [azurerm_cdn_frontdoor_route.frontdoor_route]
}

resource "azurerm_dns_txt_record" "domain_txt_record" {
  for_each = toset(local.app_names)
  name                = "_dnsauth.${each.key}"
  zone_name           = azurerm_dns_zone.aks_dns_zone.name
  resource_group_name = azurerm_resource_group.rg.name
  ttl                 = 3600
  record {
    value = azurerm_cdn_frontdoor_custom_domain.app_domain[each.key].validation_token
  }

  depends_on = [azurerm_cdn_frontdoor_route.frontdoor_route]
}