---
title: About
icon: fas fa-user-circle
order: 1
---

I'm a DevOps & Cloud Infrastructure Engineer based in Leeds, UK, specialising in Azure infrastructure for large-scale SaaS platforms. I build and maintain reusable Terraform, Bicep, and ARM-based infrastructure, shared CI/CD tooling, and an emerging AI platform layer — with a focus on automation, consistency, and enabling product teams to move at scale.

Currently at **The Access Group**, where I've owned the cloud infrastructure layer since May 2021.

## Technical Skills

{% for skill in site.data.cv.skills %}
### {{ skill.category }}

{% for item in skill.items %}- {{ item }}
{% endfor %}
{% endfor %}

## Certifications

{% for cert in site.data.cv.certifications %}- {{ cert }}
{% endfor %}

### In Progress

{% for cert in site.data.cv.certifications_in_progress %}- {{ cert }}
{% endfor %}

## Education

{% for edu in site.data.cv.education %}**{{ edu.institution }}** — {{ edu.subject }} ({{ edu.years }})
{% endfor %}
