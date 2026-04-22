---
layout: post
title: "The Azure Private DNS Output Pattern"
date: 2026-04-27
description: "Wiring Azure private endpoints to central DNS zones via a structured Terraform output pattern: the approach, the pipeline contract, and the gotchas."
categories: [DevOps]
tags:
  - azure
  - terraform
  - devops
  - networking
  - dns
  - private-endpoints
---

Private endpoints are the right way to secure Azure services from public internet access, and the DNS side of them is where the actual complexity lives. Creating the endpoint resource is straightforward. Getting A records registered reliably in the right central DNS zones, across many services, many repos, and many teams, is the part that gets messy without a clear approach.

This post describes the pattern I've landed on: a structured `private_dns` output from every Terraform module that owns a private endpoint, consumed by the deployment pipeline after apply to register DNS centrally. There are enough non-obvious gotchas in the details that writing them down properly feels worthwhile.

## Why Terraform can't own the records

The obvious approach is to create `azurerm_private_dns_a_record` resources directly in each Terraform root, pointing at the central DNS zone via a cross-subscription provider alias. Some repos started there. The problem is that Terraform needs destroy permissions to manage resources in state, and central IT won't grant destroy on the central DNS zones. The moment Terraform needs to remove or replace a record, the apply fails. You end up in a position where Terraform can create records but can't clean up after itself, which means state drift, import ceremonies, and manual intervention every time something changes.

The solution was to take DNS record management out of Terraform state entirely. Each apply emits structured data about the records it needs; a separate pipeline task handles the actual writes to the central zones using only add and update permissions. Terraform never owns the records, so it never needs to destroy them. The secondary benefit is that the registration logic lives in one place rather than scattered across however many repos touch private endpoints, but that's a consequence of the constraint, not the reason for the approach.

## The output schema

Every module or root that owns private endpoints exposes a `private_dns` output shaped like this:

```hcl
output "private_dns" {
  description = "Private DNS records for pipeline DNS registration"
  value = [
    {
      domain = string        # privatelink zone, e.g. "privatelink.azurewebsites.net"
      name   = string        # hostname only, not FQDN
      type   = string        # always "A"
      value  = list(string)  # private IP addresses
    }
  ]
}
```

The pipeline reads `terraform output -json private_dns` after apply and passes the list to the registration task. The task handles idempotency, so re-running produces the same state.

## Common zone names

The zones you'll encounter most often:

| Service | Zone |
|---------|------|
| App Service / Functions | `privatelink.azurewebsites.net` |
| Key Vault | `privatelink.vaultcore.azure.net` |
| Storage (blob) | `privatelink.blob.core.windows.net` |
| Azure SQL | `privatelink.database.windows.net` |
| Service Bus | `privatelink.servicebus.windows.net` |
| Container Registry | `privatelink.azurecr.io` |
| Cosmos DB | `privatelink.documents.azure.com` |
| Azure OpenAI | `privatelink.openai.azure.com` |
| AI Services | `privatelink.cognitiveservices.azure.com` |
| Container Apps | `privatelink.<region>.azurecontainerapps.io` |

The Container Apps zone is region-scoped. More on that shortly.

## The gotchas

### App Service needs two records

Azure's built-in `private_dns_zone_group` auto-registration creates the base hostname record. It does not create the `.scm` companion record required for Kudu, the deployment engine. Missing the `.scm` record causes deployment slot access failures with unhelpful error messages that don't point at DNS as the cause.

For any App Service private endpoint, the output needs both:

```hcl
output "private_dns" {
  value = [
    {
      domain = "privatelink.azurewebsites.net"
      name   = local.app_name
      type   = "A"
      value  = [azurerm_private_endpoint.app.private_service_connection[0].private_ip_address]
    },
    {
      domain = "privatelink.azurewebsites.net"
      name   = "${local.app_name}.scm"
      type   = "A"
      value  = [azurerm_private_endpoint.app.private_service_connection[0].private_ip_address]
    }
  ]
}
```

Both records point to the same IP. The `.scm` registration is what Azure's auto-registration silently skips.

### Container Apps zones are region-scoped

The zone name for a Container Apps Environment private endpoint includes the Azure region: `privatelink.uksouth.azurecontainerapps.io` for UK South, `privatelink.westeurope.azurecontainerapps.io` for West Europe, and so on. Each region where you deploy a Container Apps Environment has its own distinct zone.

The A-record name is the environment's auto-generated DNS prefix, which is not the same as the `azurerm_container_app_environment.name` attribute. You need to derive it from `azurerm_container_app_environment.default_domain` rather than constructing it from the resource name. Get it from the upstream module's output and forward it directly; don't reconstruct it from first principles.

### AI Services registers in three zones at once

A single Azure AI Services private endpoint covers multiple services simultaneously. You need A records in `privatelink.cognitiveservices.azure.com`, `privatelink.openai.azure.com`, and `privatelink.services.ai.azure.com`. All three use the resource's `custom_subdomain_name` as the record name, not the Terraform resource name.

```hcl
output "private_dns" {
  value = [
    for zone in [
      "privatelink.cognitiveservices.azure.com",
      "privatelink.openai.azure.com",
      "privatelink.services.ai.azure.com"
    ] : {
      domain = zone
      name   = azurerm_cognitive_account.this.custom_subdomain_name
      type   = "A"
      value  = [azurerm_private_endpoint.this.private_service_connection[0].private_ip_address]
    }
  ]
}
```

Registering only the cognitiveservices zone leaves the OpenAI and AI Foundry endpoints unreachable from within the private network.

### The ordering hazard

If the pipeline flag that enables DNS registration is committed without the `private_dns` output in the same PR, the pipeline attempts to read an output that doesn't exist. The Terraform apply succeeds, the DNS step errors, and depending on error handling the failure may not be immediately obvious.

Commit `outputs.tf` containing the `private_dns` output in the same PR as the pipeline flag that enables registration, or before it. Never after.

## Before writing any code

For any repo you're adding this pattern to, grep the Terraform source first:

```bash
# Find all private endpoint resources and which files contain them
grep -r "azurerm_private_endpoint" src/ --include="*.tf" -l

# Check whether private_dns outputs already exist
grep -r "output \"private_dns\"" src/ --include="*.tf"

# Find any hand-rolled central DNS A records
grep -r "azurerm_private_dns_a_record" src/ --include="*.tf"
```

Any hand-rolled `azurerm_private_dns_a_record` resources writing into a central zone should be removed once the pipeline pattern is validated, but not in the same PR. Validate the pipeline step first, then raise a follow-up to remove the duplicate writes.

## Why it's worth the setup cost

The pattern makes DNS registration self-documenting. Instead of tracking down which private endpoint maps to which DNS record and why it was registered a particular way, the information lives in the module output as structured data. Any module that owns a private endpoint declares exactly what DNS records it needs. The pipeline handles registration the same way regardless of which service or which repo it came from.

The `.scm` record for App Service and the three-zone requirement for AI Services are the ones that catch almost everyone the first time. Getting them right once, in the module output, is considerably cheaper than diagnosing missing records per deployment.
