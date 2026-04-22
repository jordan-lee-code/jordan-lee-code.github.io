---
layout: post
title: "What Azure Cost Alerts Actually Tell You (and What They Don't)"
date: 2026-04-25
description: "Azure cost alerts are useful but limited in specific ways: what they surface, where the blind spots are, and what early-warning signals actually matter."
categories: [DevOps]
tags:
  - azure
  - devops
  - cloud
  - cost-management
---

Azure Cost Management has improved considerably over the last few years, and the alerting system is genuinely useful for catching spending problems before they become end-of-month surprises. But the limitations are specific and predictable, and understanding them is the difference between treating alerts as a meaningful signal and wondering why you didn't see a problem coming.

## Budget alerts: what they do well

Budget alerts fire when your actual or forecast spend crosses a threshold of a defined budget. The standard setup is a series of alerts at 50%, 80%, and 100% of forecast, and then 100% and 110% of actual. You configure them in Azure Cost Management + Billing, scope them to a subscription, resource group, or management group, and route them to Action Groups for email or webhook delivery.

For catching dramatic overspends, they work. If something deploys at three times the expected scale, or a runaway process generates egress at an unusual rate, a forecast-based alert will often fire before the actual charges catch up. The Azure forecasting model isn't perfect, but it's accurate enough that a forecast alert tracking to 120% of budget is a real signal worth investigating.

## The lag problem

The most important limitation to understand is that Azure cost data is not real-time. Depending on the service, actual charges take between 8 and 48 hours to appear in Cost Management. A budget alert set to fire at 100% of actual spend is always looking at yesterday's picture at best.

This matters most in two scenarios. Short-duration compute that spins up and terminates within hours can generate significant charges that don't reach the alert pipeline until the next day. Anything using Azure AI inference endpoints with per-token billing can accumulate costs faster than the alerting cadence.

The practical response is to set alerts well below 100% and use forecast-based thresholds as the primary signal. A forecast alert at 80% of budget gives you reaction time. Waiting for 100% actual is consistently too late to change anything.

## Anomaly detection

The cost anomaly alerts in Azure Advisor are separate from budget alerts and often more useful for day-to-day monitoring. They use a machine learning model to detect when spending on a particular meter or service deviates from established patterns, and they fire without requiring you to know the right budget threshold upfront.

The quality of anomaly detection improves with subscription age, because the model needs baseline data to work from. For new subscriptions or recently-onboarded workloads, anomaly alerts can be noisy for the first few weeks while the baseline establishes itself.

## What alerts don't tell you

The gap that catches most people is attribution. An alert fires telling you a subscription has crossed 90% of its monthly budget. It doesn't tell you which resource group, which resource, or which operation caused the increase. Getting from "the subscription is over budget" to "this specific App Service scaling event is responsible" requires opening Cost Management, switching to the cost analysis view, and drilling through the charge hierarchy manually.

Setting tags for cost attribution and using resource group cost breakdowns makes the investigation faster, but the alert itself contains none of that context. The alert is the smoke alarm. Cost Management is where you find the fire.

Reserved instance and savings plan accounting is another common source of confusion. If you have reserved capacity commitments, actual charges are split between the reservation cost, which posts regardless of usage, and the consumption cost, which posts based on what ran. Budget alerts against actual spend don't surface this split cleanly, so it's possible to have a budget that looks healthy while you're underutilising reservations and still paying for them.

## Orphaned resources

Nothing in the standard alert configuration catches orphaned resources specifically. Unattached managed disks, old snapshots, unused public IP addresses, and abandoned load balancers accumulate quietly. Their cost pattern is consistent from month to month, so anomaly detection doesn't fire on them. They're not anomalies; they're structural costs that just haven't been dealt with.

Azure Advisor surfaces orphaned resource recommendations, but they're in a different part of the portal and don't integrate with Cost Management alerts. Reviewing the Advisor cost recommendations periodically is separate work from monitoring your alerts dashboard.

## What's actually worth setting up

The setup that gives me the most useful signal: forecast-based budget alerts at 80% for early warning, anomaly detection alerts for per-service spikes that don't fit the usual pattern, and a weekly cost analysis review to do the attribution work that alerts can't do automatically.

The temptation is to configure alerts and then treat them as a complete monitoring picture. They're not. They're a partial picture and a starting point. What they tell you is that something changed. What changed, and whether it was intentional, is work you still have to do yourself.
