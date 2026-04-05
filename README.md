# sentinel-claude-soc

A production-grade Azure SOC (Security Operations Center) platform powered by Claude AI agents. Built with Terraform and deployed through GitHub Actions CI/CD.

## Overview

This platform automates the full incident response lifecycle — detection, investigation, and response — using three AI agents backed by Anthropic's Claude models. All infrastructure is deployed as code, with no public-facing resources and zero hardcoded credentials.

## Architecture

```
Microsoft Sentinel / Defender XDR
        |
        v
  [Detect Agent]  ── Claude Haiku 4.5
   Poll every 5 min, classify severity, MITRE ATT&CK mapping
        |
        v (Event Hub)
  [Investigate Agent]  ── Claude Sonnet 4.6
   VirusTotal, Shodan, WHOIS enrichment, IOC scoring
        |
        v (Event Hub)
  [Respond Agent]  ── Claude Haiku 4.5
   IR playbooks via MS Graph: isolate, revoke, block, disable
        |
        v
  Cosmos DB (audit trail) + Sentinel (auto-close)
```

## AI Agents

| Agent | Model | Trigger | Purpose |
|---|---|---|---|
| **Detect** | Claude Haiku 4.5 | Timer (5 min) | Poll Sentinel incidents, classify severity, map to MITRE ATT&CK |
| **Investigate** | Claude Sonnet 4.6 | Event Hub (High/Critical) | Enrich IOCs via VirusTotal/Shodan/WHOIS, score 0-100, generate reports |
| **Respond** | Claude Haiku 4.5 | Event Hub (IOC >= 75) | Execute IR playbooks via MS Graph, audit to Cosmos DB |

## Infrastructure

All resources deployed via Terraform in **Canada East**, with no public access:

- **Networking**: VNet with dedicated subnets for Functions and Private Endpoints, NSGs denying internet inbound
- **Sentinel**: Log Analytics Workspace + Microsoft Sentinel with Defender XDR connector
- **Event Hub**: Namespace with `incidents` and `alerts` hubs (Managed Identity auth)
- **Key Vault**: RBAC-enabled, purge protection, private endpoint only
- **Cosmos DB**: Audit trail and agent logs
- **Azure Functions**: Python 3.12 on Linux, VNet-integrated, Managed Identity
- **Application Insights**: Linked to Log Analytics for observability
- **Private DNS Zones**: All services resolve privately within the VNet

## Security

- **No public access** on any Azure resource
- **OIDC authentication** for GitHub Actions (no stored client secrets)
- **Managed Identity** for all service-to-service auth
- **Key Vault** for all secrets (API keys, connection details)
- **DRY_RUN=true** on all agents by default — no live actions without explicit opt-in
- **Private endpoints** for all data plane access
- **Cost alert**: $50/month budget with notifications at 80% and 100%

## CI/CD Pipeline

Every change flows through the pipeline — no manual Terraform applies:

```
PR to main --> fmt --> validate --> plan --> plan posted as PR comment
                                              |
                                         merge PR
                                              |
push to main --> fmt --> validate --> plan --> approval gate --> apply
```

- **Drift detection**: Daily at 6:00 AM UTC, opens GitHub Issue if drift found
- **CODEOWNERS**: All PRs require owner approval
- **Environment protection**: `production` environment with required reviewer

## Deployment Phases

| Phase | Branch | Status |
|---|---|---|
| 00 - Foundation | `phase-00-foundation` | Deployed |
| 01 - Networking | `phase-01-networking` | Deployed |
| 02 - Platform Services | `phase-02-platform-services` | Deployed |
| 03 - Detect Agent | `phase-03-detect-agent` | Planned |
| 04 - Investigate Agent | `phase-04-investigate-agent` | Planned |
| 05 - Respond Agent | `phase-05-respond-agent` | Planned |
| 09 - Release | `phase-09-release` | Planned |

## Resources Not Managed by Terraform

| Resource | Reason |
|---|---|
| Sentinel Data Connector — Microsoft Defender XDR | Auto-enabled on Sentinel onboarding. The azurerm provider has an internal kind mismatch that prevents import or creation. Enable via Azure Portal: Sentinel > Configuration > Data connectors. |
| Sentinel Data Connector — Azure Security Center | Same limitation as above. Enable via Azure Portal. |
| Storage Account `stsocprodcae001` | Terraform remote state backend — bootstrapped manually before Terraform can init. |

## Prerequisites

- Azure subscription with Sentinel and Defender XDR enabled
- Terraform >= 1.9.0
- Azure CLI
- GitHub CLI
- OIDC app registration for GitHub Actions authentication

## Naming Convention

All resources follow: `TYPE-PROJECT-ENV-REGION-001`

Examples: `RG-SENTINEL-SOC-PROD-CAE-001`, `kv-soc-prod-cae-001`, `evhns-soc-prod-cae-001`

## License

Private project.
