---
layout: page
title: Experience
permalink: /portfolio/
---

## The Access Group
**DevOps & Cloud Infrastructure Engineer** · May 2021 – Present · Pontefract, UK

Owning the Azure cloud infrastructure layer for a multi-product SaaS platform — managing infrastructure across 500+ repos and supporting 10–20 product teams. The work spans four main areas:

**Terraform, Bicep & ARM Modules** — Maintaining a large library of reusable Azure IaC modules (Terraform and Bicep) covering API Management, App Service, Container Apps, CosmosDB, Key Vault, Redis, SQL, and virtual networking. These form a shared infrastructure foundation consumed by product teams across the business, with ARM templates used for specific bootstrapping and policy assignments.

**Product Infrastructure** — Building and maintaining dedicated IaC repos for individual products and services, ensuring each team has consistent, reproducible environments aligned to the shared module library.

**Azure Platform & DevOps** — Running central platform tooling and CI/CD infrastructure for engineering teams across the business. This includes a shared library of Azure Pipelines YAML templates standardising build, test, and deploy stages across all product repos; gated release workflows with environment promotion (dev → staging → production); pipeline-driven Terraform and Bicep plan/apply with state management and PR-based approval gates; and subscription-level bootstrap tooling for onboarding new Azure environments consistently. Also responsible for hosted build agent infrastructure — managing both VMSS-based auto-scaling agent pools and containerised agents — as well as API management configuration and backend-for-frontend infrastructure.

**AI/ML Infrastructure** — Growing investment in AI platform infrastructure, including serverless GPU model hosting, LLM gateway configuration, and agentic platform services on Azure.

A significant part of this work involves hands-on use of AI coding and agentic tools to accelerate infrastructure delivery at scale:

- **Claude Code** — Used extensively for orchestrating large-scale infrastructure changes across multiple product repos simultaneously. Rather than working through repos sequentially, Claude Code's subagent model allows spawning parallel agents per product, each independently reading, planning, and applying Terraform changes to its own IaC repo. This has dramatically reduced the time needed to roll out module upgrades, naming convention changes, and policy enforcement across the full product estate.

- **Devin** — Applied to longer-running, more autonomous infrastructure tasks: generating boilerplate IaC for new product onboarding, drafting pipeline templates, and exploring unfamiliar module configurations with minimal supervision.

- **GitHub Copilot** — Integrated into day-to-day Terraform, Bicep, and YAML authoring, accelerating repetitive IaC patterns such as resource blocks, variable definitions, and pipeline stage scaffolding.

Across all three tools, the core pattern is the same: treating AI agents as force multipliers for platform work that would otherwise require significant manual effort to coordinate — particularly when a single module change needs propagating across hundreds of product infrastructure repos in parallel.

---

## Link Group (LNK)
**Platform Engineer** · October 2020 – May 2021 · Leeds, UK

Agile infrastructure role focused on Azure and version-controlled deployments via GitLab. Wrote Terraform to build fault-tolerant, region-resilient solutions in Azure. Solely responsible for Windows Virtual Desktop — including image management and access control — which became critical during the shift to remote working. Supported migrations from on-premises to Azure across multiple internal EMEA domains, and regularly took ownership of IT projects end-to-end, proactively surfacing blockers to keep deliverables on track.

---

## Piksel
**3rd Line Engineer** · February 2018 – June 2019 · York, UK

Supported multi-customer Wintel environments spanning Azure, AWS, hybrid cloud, and on-premises infrastructure. Moved the team toward a DevOps workflow using Kanban and GitLab-based CI/CD pipelines. Key achievements included building customer monitoring in Azure Monitor and automating the monthly patching cycle via SCCM using PowerShell. Managed Linux servers (Ubuntu, Debian, RHEL) with Puppet, supported multiple IIS instances, and used Azure DevOps to validate server builds prior to deployment. Also handled SQL cluster migrations and Windows Server 2019 rollouts, including domain functional upgrades. Wrote detailed technical documentation to shift incident handling to the service desk and reduce on-call load.

---

## Computacenter
**2nd Line Wintel Analyst** · February 2013 – February 2018 · Hatfield, UK

Supported a broad range of customers across a shared service model, covering everything from critical incident management to datacentre recovery and migration exercises. Managed customer expectations through complex, high-visibility incidents and delivered multiple projects within required timescales. Continuously expanded technical scope through shift-left activities, taking on additional responsibility for messaging technologies and broader infrastructure support.

**Service Desk Analyst** · June 2012 – January 2013 · Hatfield, UK

Improved first-time fix rates and reduced incorrect escalations by implementing automated ticket routing and call templates in the ITSM platform. Collaborated with 2nd and 3rd Line teams to raise the technical capability of the service desk, and produced support documentation that helped the team navigate the transition to Office 365.

---

## Fujitsu UK
**1st Line Analyst** · July 2011 – June 2012 · Stevenage, UK

First point of contact for technical support across a shared service model, handling incidents and service requests across a range of customer environments. Collaborated with 2nd and 3rd Line teams to resolve escalations and build personal technical knowledge, laying the foundation for progression into more complex infrastructure support roles.
