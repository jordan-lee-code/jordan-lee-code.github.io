---
layout: post
title: "Managing Terraform Infrastructure Across 500+ Repos with a Shared Module Library"
date: 2026-04-15
description: "How we built a shared Terraform module library to manage infrastructure consistency across 500+ repos at The Access Group."
categories: [DevOps]
tags:
  - terraform
  - azure
  - infrastructure-as-code
  - devops
---

When you're managing infrastructure for a single product, Terraform is straightforward enough. You write some modules, copy a few patterns between environments, and get on with it. When you're doing the same across 500+ repos spanning 10 to 20 product teams, that approach disintegrates fast and the debris lands everywhere.

This is the problem we ran into at The Access Group. The shared module library my team built to solve it has become, without question, one of the most valuable things we own. It is also the thing that quietly makes the rest of my colleagues' work go faster, which matters more to me than the elegance of the structure.

## The drift problem

Before centralising any of it, each product team was largely responsible for defining their own Azure infrastructure inside their own repo. In practice what that meant was similar resources being defined in subtly different ways across the estate, with different naming conventions, inconsistent tagging across the board, varying security configurations from one team to the next, and no shared baseline that anybody could rely on as a starting point for new work.

The consequences were exactly what you'd expect, and they weren't subtle. Security fixes had to be manually tracked down and applied across individual repos. New products reinvented the same infrastructure patterns from scratch. Any platform-wide change, whether a policy update or a new compliance requirement, meant somebody on the platform team opening dozens of codebases one by one. That somebody was usually one of us, working the kind of late evenings nobody talks about, and the cost of that work was real even when it was invisible from the org chart.

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

Publishing to a registry rather than referencing Git directly might seem like extra overhead, but at scale it changes everything.

With Git references like `?ref=main` or a raw commit SHA, there is no real visibility into what changed between two versions or whether the change is safe for downstream consumers to absorb. With semver-tagged releases the intent of the change is explicit at a glance, so that a patch bump from `1.4.1` to `1.4.2` is something the consumer can take in without ceremony, a minor bump tells them something has been added that they can choose to use, and a major bump warns them that there are breaking changes inside they will want to assess carefully before upgrading.

It also means security fixes and platform improvements propagate across the estate without any extra effort from product teams. When we patched a Key Vault module to enforce private endpoint requirements, every team on a compatible version received that fix on their next Terraform apply, without a single PR raised against a product repo. There is something I love about that, the way a small careful change to one piece of code can quietly travel out to dozens of teams and protect each of them in turn, none of them needing to know anything about it.

## Pipeline-driven consumption

Modules are never applied manually in this setup, which is something I want to be deliberate about. Every product IaC repo runs through our shared Azure Pipelines template library, which handles the full plan and apply lifecycle from a single trusted place. The pipeline initialises against the correct Artifactory registry, runs `terraform plan` on every PR so that reviewers can see exactly what will change, and gates the `terraform apply` itself behind environment promotion approvals from the people who own the environment in question.

Module upgrades get tested in staging before reaching production, and there's a full audit trail of what changed and when regardless of which product team's repo was involved.

## What this unlocks

The shift from per-team ad-hoc modules to a centralised, versioned library changes what platform work actually feels like:

- **A single security fix** applied to a module propagates to all consumers on the next apply cycle, with no coordination needed across individual teams.
- **New product onboarding** becomes a matter of composing existing modules rather than writing infrastructure from scratch.
- **Compliance and policy changes** are implemented once and inherited everywhere.
- **Platform engineers** can improve shared infrastructure without needing access to or context about every product repo.

The trade-off is that the module library becomes load-bearing infrastructure for the entire estate. If a module has a bug, it touches every consumer simultaneously, which is a deeply uncomfortable feeling the first time it happens. That puts a real premium on testing thoroughly before publishing (we use Terratest) and on keeping semver discipline tight enough that teams know exactly what they're absorbing when they upgrade.

## Where it goes from here

With 500+ repos consuming modules, rolling out a new major version still requires coordination. That's a problem we've increasingly been solving with AI tooling, but that's a post for another day.

If you're managing Azure infrastructure across multiple teams and finding yourself copy-pasting Terraform patterns or applying the same fix in ten different places, a versioned module library published to a private registry is the single most effective structural change I have made to this kind of work, and I think you would feel that change inside the first month. The upfront investment is real, but the compounding returns are difficult to overstate.

I am still thinking, even now, about how much of platform engineering turns out to be the work of giving other engineers fewer reasons to be paged at three in the morning, and I do not have a clean theory of it yet, but I know what it looks like when it goes right. The people on the receiving end of those returns are the engineers who never have to be woken up about a thing the module library quietly handles for them, and that is the kind of outcome I most want to be designing for, in this work and in everything else my team and I build together.
