---
layout: single
title: "Managing Terraform Infrastructure Across 500+ Repos with a Shared Module Library"
date: 2026-04-20
author_profile: true
tags:
  - terraform
  - azure
  - infrastructure-as-code
  - devops
---

When you're managing infrastructure for a single product, Terraform is straightforward enough. You write some modules, maybe copy a few patterns between environments, and get on with it. When you're managing infrastructure across 500+ repos spanning 10–20 product teams, the approach needs to be fundamentally different — or things drift fast.

This is the problem we hit at The Access Group, and the shared module library we built to solve it has become one of the most valuable pieces of platform infrastructure we own.

## The drift problem

Before centralising, each product team was largely responsible for defining their own Azure infrastructure. In practice, this meant similar resources being defined in subtly different ways across repos — different naming conventions, inconsistent tagging, varying security configurations, and no shared baseline.

The consequences were predictable: security fixes had to be manually applied to each repo; new products reinvented the wheel; and any platform-wide change (a policy update, a new compliance requirement) meant touching dozens of codebases individually.

## One repo per module, published to Artifactory

The solution was to extract every reusable pattern into its own dedicated Terraform module repository. Each module covers a specific Azure service or capability — Container Apps, CosmosDB, Key Vault, SQL, VNet, API Management, and so on — and lives in isolation with its own lifecycle.

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

Publishing to a registry rather than referencing Git directly might seem like an overhead, but it makes a significant difference at scale.

With Git references (`?ref=main` or a commit SHA), there's no visibility into what changed or whether it's safe to upgrade. With semver-tagged releases, the intent is explicit: a patch bump (`1.4.1` → `1.4.2`) is safe to consume without review; a minor bump adds functionality; a major bump requires teams to assess the breaking changes.

It also means security fixes and platform improvements propagate across the estate without additional effort from product teams. When we patched a Key Vault module to enforce private endpoint requirements, every team consuming a compatible version received that fix on their next Terraform apply — without a single PR raised against a product repo.

## Pipeline-driven consumption

Modules aren't applied manually. Every product IaC repo runs through our shared Azure Pipelines template library, which handles the full plan/apply lifecycle: initialising against the correct Artifactory registry, running `terraform plan` on PR, and gating `terraform apply` behind environment promotion approvals.

This means module upgrades are tested in staging before reaching production, and there's a full audit trail of what changed and when — regardless of which product team's repo was involved.

## What this unlocks

The shift from per-team ad-hoc modules to a centralised, versioned library changes the nature of platform work significantly:

- **A single security fix** applied to a module propagates to all consumers on the next apply cycle, without coordinating with individual teams.
- **New product onboarding** becomes a matter of composing existing modules rather than writing infrastructure from scratch.
- **Compliance and policy changes** are implemented once and inherited everywhere.
- **Platform engineers** can improve shared infrastructure without needing access to or context about every product repo.

The trade-off is that the module library becomes a critical dependency — if a module has a bug, it affects every consumer. That puts a premium on testing individual modules thoroughly before publishing (we use Terratest for this) and on maintaining clear semver discipline so teams understand exactly what they're signing up for when they upgrade.

## Where it goes from here

With 500+ repos consuming modules, even rolling out a new major version requires coordination. That's a problem we've increasingly been solving with AI tooling — but that's a post for another day.

If you're managing Azure infrastructure across multiple teams and finding yourself copy-pasting Terraform or applying the same change in ten different places, a versioned module library published to a private registry is the most effective structural fix I've come across.
