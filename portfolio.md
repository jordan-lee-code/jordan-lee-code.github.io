---
layout: single
title: Experience
permalink: /portfolio/
toc: true
toc_label: "Companies"
toc_icon: "briefcase"
---

## The Access Group

**DevOps & Cloud Infrastructure Engineer** · May 2021 – Present · Pontefract, UK

Owning the Azure cloud infrastructure layer for a multi-product SaaS platform — managing infrastructure across 500+ repos and supporting 10–20 product teams.

### Terraform, Bicep & ARM Modules

- Maintaining a large library of reusable IaC modules covering API Management, App Service, Container Apps, CosmosDB, Key Vault, Redis, SQL, and virtual networking
- Modules published to Artifactory with semantic versioning, consumed by product pipelines — security fixes and improvements propagate to all consumers on the next apply cycle
- ARM templates used for subscription-level bootstrap and policy assignments

### Product Infrastructure

- Building and maintaining dedicated IaC repos for each product and service
- Ensures consistent, reproducible environments across all teams, aligned to the shared module library

### Azure Platform & DevOps

- Shared Azure Pipelines YAML template library standardising build, test, and deploy stages across all product repos
- Gated release workflows with environment promotion (dev → staging → production)
- Pipeline-driven Terraform and Bicep plan/apply with state management and PR-based approval gates
- Hosted build agent infrastructure — VMSS-based auto-scaling pools and containerised agents
- Subscription-level bootstrap tooling for onboarding new Azure environments
- API management configuration and backend-for-frontend infrastructure

### AI/ML Infrastructure & Tooling

- AI platform infrastructure: serverless GPU model hosting, LLM gateway configuration, agentic platform services on Azure
- **Claude Code** — subagent orchestration for parallel IaC changes across hundreds of repos simultaneously, reducing week-long rollouts to hours
- **Devin** — autonomous scaffolding for new product onboarding and pipeline template generation
- **GitHub Copilot** — inline acceleration for day-to-day Terraform, Bicep, and YAML authoring

---

## Link Group (LNK)

**Platform Engineer** · October 2020 – May 2021 · Leeds, UK

- Agile infrastructure role deploying version-controlled code via GitLab
- Wrote Terraform for fault-tolerant, region-resilient Azure solutions
- Sole responsibility for Windows Virtual Desktop — image management and access control — which became critical infrastructure during the pandemic shift to remote working
- Supported on-premises to Azure migrations across multiple internal EMEA domains
- Took end-to-end ownership of IT projects, surfacing blockers proactively to keep deliverables on track

---

## Piksel

**3rd Line Engineer** · February 2018 – June 2019 · York, UK

- Supported multi-customer Wintel environments across Azure, AWS, hybrid cloud, and on-premises
- Drove the team's shift toward a DevOps workflow using Kanban and GitLab-based CI/CD pipelines
- Built customer monitoring in Azure Monitor and automated the monthly patching cycle via SCCM using PowerShell
- Managed Linux servers (Ubuntu, Debian, RHEL) configured with Puppet
- Used Azure DevOps to validate server builds prior to deployment
- Handled SQL cluster migrations and Windows Server 2019 rollouts including domain functional upgrades
- Wrote technical documentation to shift incident handling to the service desk and reduce on-call load

---

## Computacenter

### 2nd Line Wintel Analyst · February 2013 – February 2018

Hatfield, UK

- Supported a broad range of customers across a shared service model
- Managed critical incidents and datacentre recovery and migration exercises
- Delivered multiple projects within required timescales, escalating blockers early
- Expanded technical scope through shift-left activities, taking on additional responsibility for messaging technologies

### Service Desk Analyst · June 2012 – January 2013

Hatfield, UK

- Improved first-time fix rates and reduced incorrect escalations via automated ticket routing and ITSM call templates
- Collaborated with 2nd and 3rd Line teams to raise the technical capability of the service desk
- Produced documentation that guided the team through the transition to Office 365

---

## Fujitsu UK

**1st Line Analyst** · July 2011 – June 2012 · Stevenage, UK

First point of contact for technical support across a shared service model. Collaborated with 2nd and 3rd Line teams to resolve escalations and build technical knowledge, laying the foundation for progression into infrastructure support roles.
