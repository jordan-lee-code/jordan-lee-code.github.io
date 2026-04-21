---
title: About
icon: fas fa-user-circle
order: 1
---

I'm a DevOps & Cloud Infrastructure Engineer based in Leeds, UK, with a decade of experience working on Azure infrastructure for large-scale SaaS platforms. My work centres on reusable Terraform and Bicep modules, shared CI/CD tooling, and an expanding AI platform layer, built around automation, consistency, and giving product teams the foundation they need to move at real scale.

I'm a woman working in tech, and that perspective shapes both the work I write about here and the way I think about the people doing it alongside me.

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
