---
layout: post
title: "Managing Terraform Infrastructure Across 500+ Repos with a Shared Module Library"
date: 2026-04-16
categories: [DevOps]
tags:
  - terraform
  - azure
  - infrastructure-as-code
  - devops
---

When you're managing infrastructure for a single product, Terraform is straightforward enough. You write some modules, maybe copy a few patterns between environments, and get on with it. When you're doing the same across 500+ repos spanning 10-20 product teams, that approach falls apart pretty quickly.

This is the problem we hit at The Access Group, and the shared module library we built to solve it has become one of the most valuable pieces of platform infrastructure we own.

## The drift problem

Before centralising, each product team was largely responsible for defining their own Azure infrastructure. In practice that meant similar resources being defined in subtly different ways across repos. Different naming conventions, inconsistent tagging, varying security configurations, no shared baseline.

The consequences were exactly what you'd expect, and they weren't subtle. Security fixes had to be manually tracked down and applied across individual repos. New products reinvented the same infrastructure patterns from scratch. Any platform-wide change, whether a policy update or a new compliance requirement, meant opening dozens of codebases one by one.

## One repo per module, published to Artifactory

The solution was to extract every reusable pattern into its own dedicated Terraform module repository. Each module covers a specific Azure service or capability, things like Container Apps, CosmosDB, Key Vault, SQL, VNet, API Management, and lives in isolation with its own lifecycle.

Modules are versioned using [semantic versioning](https://semver.org/) and published to our internal Artifactory instance as a private Terraform registry. This gives us a clean, stable contract: a module at `1.4.2` will always behave exactly as it did when that version was tagged.

Product IaC repos consume modules directly from the registry:

```hcl
module "key_vault" {
  source  = "artifactory.example.internal/terraform/key-vault"
  version = "~> 2.0"

  name                = var.vault_name
  resource_group_name = var.resource_group_name
  location            = var.location
}
```

The `~> 2.0` constraint lets dependent repos absorb minor and patch updates automatically while protecting against breaking changes in a new major version.

## Why Artifactory and semver matter

Publishing to a registry rather than referencing Git directly might seem like extra overhead, but it makes a significant difference at scale.

With Git references like `?ref=main` or a commit SHA, there's no real visibility into what changed or whether it's safe to upgrade. With semver-tagged releases, the intent is explicit. A patch bump from `1.4.1` to `1.4.2` is safe to consume without review. A minor bump adds functionality. A major bump means teams need to assess the breaking changes before upgrading.

It also means security fixes and platform improvements propagate across the estate without any extra effort from product teams. When we patched a Key Vault module to enforce private endpoint requirements, every team on a compatible version received that fix on their next Terraform apply, without a single PR raised against a product repo.

## Pipeline-driven consumption

Modules aren't applied manually. Every product IaC repo runs through our shared Azure Pipelines template library, which handles the full plan/apply lifecycle. It initialises against the correct Artifactory registry, runs `terraform plan` on PR, and gates `terraform apply` behind environment promotion approvals.

Module upgrades get tested in staging before reaching production, and there's a full audit trail of what changed and when regardless of which product team's repo was involved.

## What this unlocks

The shift from per-team ad-hoc modules to a centralised, versioned library changes what platform work actually feels like:

- **A single security fix** applied to a module propagates to all consumers on the next apply cycle, with no coordination needed across individual teams.
- **New product onboarding** becomes a matter of composing existing modules rather than writing infrastructure from scratch.
- **Compliance and policy changes** are implemented once and inherited everywhere.
- **Platform engineers** can improve shared infrastructure without needing access to or context about every product repo.

The trade-off is that the module library becomes a critical dependency. If a module has a bug, it affects every consumer. That puts a real premium on testing modules thoroughly before publishing (we use Terratest for this) and on keeping semver discipline tight so teams know exactly what they're signing up for when they upgrade.

## Where it goes from here

With 500+ repos consuming modules, rolling out a new major version still requires coordination. That's a problem we've increasingly been solving with AI tooling, but that's a post for another day.

If you're managing Azure infrastructure across multiple teams and finding yourself copy-pasting Terraform patterns or applying the same fix in ten different places, a versioned module library published to a private registry is the most meaningful structural improvement I've made to this kind of work. The upfront investment is real, but the compounding returns are difficult to overstate.
