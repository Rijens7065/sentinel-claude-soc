# VSCODE_PROMPT.md
# sentinel-claude-soc — VS Code Agentic Build Guide
# PUBLIC REPOSITORY — security rules enforced throughout

> Paste this file into your VS Code chat (Claude Code) at the start of each session.
> Each phase section contains an **exact prompt** you can use verbatim.
> Never skip the pre-phase approval step. Never bypass the CI/CD pipeline.
> This repo is PUBLIC — no real IDs, credentials, or sensitive values ever get committed.

---

## 🔁 SESSION BOOTSTRAP
> Paste this at the start of **every** VS Code chat session, before any phase prompt.

```
You are working on sentinel-claude-soc — a production Azure SOC platform built with Terraform and GitHub Actions. The GitHub repository is PUBLIC.

Ground rules:
- Read CLAUDE.md before doing anything else
- Default region is canadaeast
- All resource names follow: TYPE-PROJECT-ENV-REGION-001
- No secrets in code. Key Vault + Managed Identity only
- OIDC authentication only (app registration: azure-fortress-github-oidc)
- DRY_RUN=true on all Azure Functions until explicitly changed
- Every phase gets its own branch (phase-00-foundation through phase-09-release)
- Before any implementation, output a Pre-Phase Approval Summary and wait for my go-ahead
- Every deployment flows through the CI/CD pipeline — no manual applies except documented bootstrap steps
- Terraform provider: azurerm ~> 4.66, Terraform >= 1.9.0
- GitHub repo: Rijens7065/sentinel-claude-soc (PUBLIC)
- Use gh CLI for all pull requests

PUBLIC REPO SECURITY — these rules are absolute:
- Never hardcode subscription IDs, tenant IDs, client IDs, or any GUIDs in .tf files — use var.subscription_id etc.
- Never commit terraform.tfvars — only terraform.tfvars.example with fake placeholder values
- Never commit .env, local.settings.json, or any file with real credentials
- Never include real API keys anywhere in committed files, even in comments
- Never expose the Terraform state file
- GitHub Actions workflows must use ${{ secrets.* }} for all sensitive values
- GitHub Actions default permissions must be read-only; grant write only where needed
- Before every git commit, mentally verify no sensitive values are staged

Start by confirming you have read CLAUDE.md and are ready.
```

---

## PHASE 0 — Foundation: CI/CD, Remote State, Key Vault, Cost Alert

**Branch:** `phase-00-foundation`
**Deploys through pipeline:** Partially — storage account bootstrap is manual. Everything after uses the pipeline.

### What gets built
| Resource | Name Pattern | Action |
|---|---|---|
| Resource Group | RG-SENTINEL-SOC-PROD-CAE-001 | Create |
| Storage Account (Terraform state) | stsocprodcae001 | Create |
| Storage Container | terraform-state | Create |
| Key Vault | KV-SENTINEL-SOC-PROD-CAE-001 | Create |
| GitHub Actions Workflow (CI/CD) | `.github/workflows/terraform.yml` | Create |
| GitHub Actions Workflow (Drift) | `.github/workflows/drift-detection.yml` | Create |
| Cost Management Budget | $50/month notify-only | Create |
| .github/CODEOWNERS | `* @Rijens7065` | Create |
| .gitignore | hardened for public repo | Create |
| terraform.tfvars.example | fake placeholder values only | Create |

### Bootstrap steps (manual — run once before pipeline exists)
```bash
# 1. Create the Terraform state storage account
az group create --name RG-SENTINEL-SOC-PROD-CAE-001 --location canadaeast

az storage account create \
  --name stsocprodcae001 \
  --resource-group RG-SENTINEL-SOC-PROD-CAE-001 \
  --location canadaeast \
  --sku Standard_LRS \
  --allow-blob-public-access false \
  --min-tls-version TLS1_2

az storage container create \
  --name terraform-state \
  --account-name stsocprodcae001 \
  --auth-mode login

# 2. Confirm your 4 federated credentials are in place
az ad app federated-credential list \
  --id $(az ad app list --display-name azure-fortress-github-oidc --query "[0].appId" -o tsv)

# 3. Create the GitHub production environment (do this in GitHub UI:
#    Settings → Environments → New environment → "production"
#    Add yourself as required reviewer)
```

### Phase 0 Prompt
```
Start Phase 0 — Foundation.

Branch: phase-00-foundation

Before implementing anything, output the Pre-Phase Approval Summary:
- Phase name and purpose
- Every Azure resource that will be created, with exact planned names
- Every file that will be created or modified
- Whether any step requires manual bootstrap (document it clearly)
- Confirm the CI/CD pipeline will be live by end of this phase
- Confirm no sensitive values will be committed (public repo check)

Wait for my approval before writing any code.

Once approved, implement in this order:

1. .gitignore — hardened for public repo:
   - *.tfvars (but NOT *.tfvars.example)
   - .terraform/
   - terraform.tfstate and backups
   - *.tfplan
   - .env
   - local.settings.json (but NOT local.settings.json.example)
   - *.pem, *.key, *.p12, *.pfx
   - .azure/
   - __pycache__/, *.pyc
   - .DS_Store, Thumbs.db

2. .github/CODEOWNERS:
   * @Rijens7065
   (Every PR — including ones opened by bots or forks — requires your approval)

3. terraform/variables.tf — declare all variables, no hardcoded sensitive defaults:
   - location (default: "canadaeast")
   - environment (default: "prod")
   - project (default: "sentinel-claude-soc")
   - subscription_id (no default — passed via environment)
   - tenant_id (no default — passed via environment)

4. terraform/terraform.tfvars.example — fake placeholder values only:
   subscription_id = "00000000-0000-0000-0000-000000000000"
   tenant_id       = "00000000-0000-0000-0000-000000000000"
   location        = "canadaeast"
   environment     = "prod"

5. terraform/backend.tf — azurerm backend, private storage, no public access

6. terraform/providers.tf — azurerm ~> 4.66, Terraform >= 1.9.0

7. terraform/main.tf — Resource Group, Key Vault (no public access, RBAC enabled, purge protection on)

8. terraform/cost_management.tf — $50/month budget alert, notify-only

9. terraform/outputs.tf

10. .github/workflows/terraform.yml:
    - Triggers: push to any phase-* branch, PR to main
    - Permissions declared explicitly:
        permissions:
          id-token: write
          contents: read
          pull-requests: write
    - Jobs: fmt → init → validate → plan (save plan artifact) → post plan as PR comment → manual approval gate (production environment) → apply using saved plan
    - Auth: OIDC only via ${{ secrets.AZURE_CLIENT_ID }}, ${{ secrets.AZURE_TENANT_ID }}, ${{ secrets.AZURE_SUBSCRIPTION_ID }}
    - Never echo secret values in any step

11. .github/workflows/drift-detection.yml:
    - Schedule: cron "0 6 * * *" (6:00 AM UTC daily)
    - Permissions: id-token: write, contents: read, issues: write
    - terraform plan -refresh-only
    - Open GitHub Issue if drift found — never auto-apply

After all files are created:
- git checkout -b phase-00-foundation
- git status (confirm no .tfvars, no .terraform/, no state files staged)
- git add .
- git commit -m "phase-00: foundation — remote state, Key Vault, CI/CD, cost alert, public repo hardening"
- gh pr create --title "Phase 00: Foundation" --body "Establishes Terraform remote state, Key Vault, CI/CD pipeline with OIDC auth, drift detection, $50 cost alert. CODEOWNERS and hardened .gitignore in place for public repo. Requires manual bootstrap of storage account before pipeline can run."

Then output the Next Phase summary.
```

---

## PHASE 1a — Networking

**Branch:** `phase-01-networking`

### Phase 1a Prompt
```
Start Phase 1a — Networking.

Branch: phase-01-networking

Output the Pre-Phase Approval Summary including public repo safety check. Wait for my approval.

Once approved:
1. terraform/modules/networking/main.tf:
   - VNet (10.0.0.0/16), canadaeast
   - Subnet Functions: 10.0.1.0/24
   - Subnet Private Endpoints: 10.0.2.0/24
   - Subnet Reserved: 10.0.3.0/24
   - No public IPs
   - All address spaces as variables
2. NSGs — deny all inbound from internet, allow VNet internal only
3. Private DNS zones stub
4. All resources tagged per CLAUDE.md
5. No GUIDs or real IDs hardcoded

Public repo check before commit:
- No GUIDs, real IDs, or credentials in any staged file
- terraform.tfvars not staged

Git + PR:
- git checkout -b phase-01-networking
- git status (verify clean)
- git add . && git commit -m "phase-01: networking — VNet, subnets, NSGs, private DNS stubs"
- gh pr create --title "Phase 01: Networking" --body "Deploys VNet VNET-SENTINEL-SOC-PROD-CAE-001 with three subnets and NSGs. No public access. All values parameterised — safe for public repo."

Output Next Phase summary.
```

---

## PHASE 1b — Platform Services: Sentinel + Event Hub

**Branch:** `phase-02-platform-services`

### Phase 1b Prompt
```
Start Phase 1b — Platform Services.

Branch: phase-02-platform-services

Output the Pre-Phase Approval Summary including public repo safety check. Wait for my approval.

Once approved:
1. terraform/modules/sentinel/main.tf:
   - Log Analytics Workspace (30-day retention, canadaeast)
   - Microsoft Sentinel enabled
   - Sentinel Defender XDR connector
   - Sentinel Microsoft Security Incidents connector
   - No hardcoded workspace IDs
2. terraform/modules/eventhub/main.tf:
   - Event Hub Namespace (Standard tier)
   - Event Hub: incidents (3 partitions)
   - Event Hub: alerts (3 partitions)
   - Managed Identity auth — no connection strings
3. Application Insights linked to LAW
4. Private endpoints for LAW and Event Hub into SNET-PE
5. All Managed Identity role assignments

Public repo check before commit:
- No workspace IDs, resource IDs, or connection strings hardcoded
- terraform.tfvars not staged

Git + PR:
- git checkout -b phase-02-platform-services
- git status (verify clean)
- git add . && git commit -m "phase-02: platform services — Sentinel, Event Hub, Defender connectors, App Insights"
- gh pr create --title "Phase 02: Platform Services" --body "Deploys Log Analytics + Sentinel, Event Hub, Defender XDR connector, App Insights. All private. No hardcoded identifiers — safe for public repo."

Output Next Phase summary.
```

---

## PHASE 2 — Detect Agent (Claude Haiku 4.5)

**Branch:** `phase-03-detect-agent`

### Phase 2 Prompt
```
Start Phase 2 — Detect Agent.

Branch: phase-03-detect-agent

Output the Pre-Phase Approval Summary including public repo safety check. Wait for my approval.

Once approved:

INFRASTRUCTURE (Terraform):
1. terraform/modules/detect_agent/main.tf:
   - Function App (Python 3.12, Linux)
   - Storage Account (private, TLS 1.2)
   - System-assigned Managed Identity
   - VNet integration into SNET-FUNC
   - App settings using Key Vault references @Microsoft.KeyVault(...) — no inline values
2. Key Vault secret: anthropic-api-key with value "REPLACE_ME"
3. Cosmos DB: sentinel-soc-db, container detect-agent-logs (partition key: /incidentId)
4. Role assignments: Sentinel Reader, Event Hub Data Receiver, Key Vault Secrets User, Cosmos DB Contributor

PYTHON FUNCTION (functions/detect_agent/):
5. poll_incidents/__init__.py:
   - Timer trigger: every 5 minutes
   - Pull incidents from Sentinel REST API
   - Classify severity
   - Map to MITRE ATT&CK using Claude Haiku 4.5
   - DRY_RUN guard: if env var DRY_RUN is "true" → log only, no writes
   - All credentials from environment variables — zero hardcoded values
   - Structured JSON logging, full error handling
6. requirements.txt
7. local.settings.json.example (fake values only)
8. tests/test_detect_agent.py

Public repo check before commit:
- local.settings.json NOT staged (only .example)
- No API keys or GUIDs in Python code

Git + PR:
- git checkout -b phase-03-detect-agent
- git status (verify local.settings.json absent)
- git add . && git commit -m "phase-03: detect agent — Haiku 4.5, poll Sentinel 5min, MITRE mapping, DRY_RUN"
- gh pr create --title "Phase 03: Detect Agent" --body "Deploys FUNC-DETECT-SOC-PROD-CAE-001. Polls Sentinel every 5 min, classifies incidents, MITRE ATT&CK via Claude Haiku 4.5. DRY_RUN=true. All credentials via Key Vault. Safe for public repo."

Output Next Phase summary.
```

---

## PHASE 3 — Investigate Agent (Claude Sonnet 4.6)

**Branch:** `phase-04-investigate-agent`

### Phase 3 Prompt
```
Start Phase 3 — Investigate Agent.

Branch: phase-04-investigate-agent

Output the Pre-Phase Approval Summary including public repo safety check. Wait for my approval.

Once approved:

INFRASTRUCTURE (Terraform):
1. terraform/modules/investigate_agent/main.tf:
   - Function App (Python 3.12, Linux)
   - Storage Account (private, TLS 1.2)
   - System-assigned Managed Identity
   - VNet integration into SNET-FUNC
   - All app settings via Key Vault references only
2. Key Vault secrets: virustotal-api-key, shodan-api-key — both "REPLACE_ME"
3. Cosmos DB container: investigate-agent-logs (partition key: /incidentId)

PYTHON FUNCTION (functions/investigate_agent/):
4. enrich_incident/__init__.py:
   - Event Hub trigger for escalated High/Critical incidents
   - VirusTotal, Shodan, WHOIS enrichment
   - All API keys from environment only — never hardcoded
   - IOC scoring 0–100 composite
   - Claude Sonnet 4.6 investigation report
   - DRY_RUN guard
   - Retry logic: exponential backoff, max 3 retries
5. requirements.txt
6. local.settings.json.example (fake values only)
7. tests/test_investigate_agent.py

Public repo check before commit:
- No real API keys anywhere, even commented out
- local.settings.json not staged

Git + PR:
- git checkout -b phase-04-investigate-agent
- git status (verify clean)
- git add . && git commit -m "phase-04: investigate agent — Sonnet 4.6, VirusTotal+Shodan, IOC scoring, reports"
- gh pr create --title "Phase 04: Investigate Agent" --body "Deploys FUNC-INVEST-SOC-PROD-CAE-001. VirusTotal, Shodan, WHOIS enrichment. IOC 0-100 scoring. Reports via Claude Sonnet 4.6. DRY_RUN=true. All keys via Key Vault. Safe for public repo."

Output Next Phase summary.
```

---

## PHASE 4 — Respond Agent (Claude Haiku 4.5 + MS Graph)

**Branch:** `phase-05-respond-agent`

> ⚠️ DRY_RUN=true is critical. This agent isolates devices, revokes tokens, blocks IPs, disables users.

### Phase 4 Prompt
```
Start Phase 4 — Respond Agent.

Branch: phase-05-respond-agent

Output the Pre-Phase Approval Summary including public repo safety check. Wait for my approval.

Once approved:

INFRASTRUCTURE (Terraform):
1. terraform/modules/respond_agent/main.tf:
   - Function App (Python 3.12, Linux)
   - Storage Account (private, TLS 1.2)
   - System-assigned Managed Identity
   - VNet integration into SNET-FUNC
   - All app settings via Key Vault references
2. Key Vault secrets: graph-client-id, graph-client-secret — both "REPLACE_ME"
3. Cosmos DB container: audit-trail (partition key: /incidentId)
4. MS Graph permissions must be granted manually in Entra ID — document this in README

PYTHON FUNCTION (functions/respond_agent/):
5. execute_playbook/__init__.py:
   - Event Hub trigger for incidents with IOC score >= 75
   - Playbooks (all DRY_RUN guarded):
     isolate_device, revoke_tokens, block_ip, disable_user, close_sentinel_incident
   - DRY_RUN=true: log exact action only, never execute
   - Every action writes structured audit record to Cosmos DB
   - Claude Haiku 4.5 selects playbooks
   - Graph credentials from environment only
6. requirements.txt
7. local.settings.json.example (fake values only)
8. tests/test_respond_agent.py

Public repo check before commit:
- No MS Graph secrets or Entra IDs hardcoded
- local.settings.json not staged
- Audit trail never logs credential values

Git + PR:
- git checkout -b phase-05-respond-agent
- git status (verify clean)
- git add . && git commit -m "phase-05: respond agent — Haiku 4.5, MS Graph IR playbooks, audit trail, DRY_RUN"
- gh pr create --title "Phase 05: Respond Agent" --body "Deploys FUNC-RESPOND-SOC-PROD-CAE-001. IR playbooks via MS Graph. DRY_RUN=true. All audited to Cosmos DB. MS Graph permissions require manual Entra ID grant. Safe for public repo."

Output Next Phase summary.
```

---

## PHASE 5 — Reporting, README, LinkedIn Assets

**Branch:** `phase-09-release`

### Phase 5 Prompt
```
Start Phase 5 — Reporting, README, and LinkedIn Assets.

Branch: phase-09-release

Output the Pre-Phase Approval Summary. Wait for my approval.

Once approved:

1. functions/report_generator/__init__.py:
   - Post-incident PDF report generator
   - Pulls from Cosmos DB, generates via Claude Sonnet 4.6
   - Output to private Blob container: reports
   - DRY_RUN guard, no hardcoded credentials

2. README.md:
   - Project overview, architecture diagram (Mermaid)
   - Prerequisites and deployment guide
   - Agent descriptions
   - Security controls
   - Public repo safety section explaining what is and is not safe to commit
   - How to set DRY_RUN=false (with warning)
   - No real subscription IDs, tenant IDs, or resource IDs in README

3. docs/architecture.md

4. docs/linkedin/LINKEDIN_WRITEUP.md:
   - 3-paragraph LinkedIn post
   - Screenshot guide
   - Suggested hashtags

Public repo check before commit:
- README has no real Azure identifiers
- Architecture uses generic names only

Git + PR:
- git checkout -b phase-09-release
- git status (verify clean)
- git add . && git commit -m "phase-09: release — PDF reports, README, architecture, LinkedIn assets"
- gh pr create --title "Phase 09: Release" --body "Adds post-incident PDF report generator, polished README, architecture diagram, LinkedIn launch assets. Project ready for public portfolio."

Output project completion summary.
```

---

## 🔑 KEY VAULT SECRETS — SET MANUALLY IN YOUR TERMINAL ONLY

Never type or paste these in the VS Code Claude Code chat.

```bash
KV="KV-SENTINEL-SOC-PROD-CAE-001"

az keyvault secret set --vault-name $KV --name "anthropic-api-key"    --value "sk-ant-YOUR-KEY"
az keyvault secret set --vault-name $KV --name "virustotal-api-key"   --value "YOUR-VT-KEY"
az keyvault secret set --vault-name $KV --name "shodan-api-key"       --value "YOUR-SHODAN-KEY"
az keyvault secret set --vault-name $KV --name "graph-client-id"      --value "YOUR-GRAPH-CLIENT-ID"
az keyvault secret set --vault-name $KV --name "graph-client-secret"  --value "YOUR-GRAPH-SECRET"
```

---

## 🏷️ GITHUB ACTIONS SECRETS — SET ONCE

Settings → Secrets and variables → Actions:

| Secret name | Value |
|---|---|
| `AZURE_CLIENT_ID` | Client ID of `azure-fortress-github-oidc` |
| `AZURE_TENANT_ID` | Your Azure Tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Your Azure Subscription ID |

These 3 are the only secrets that ever go in GitHub. Nothing else.

---

## 🔒 PUBLIC REPO — SAFE VS NEVER COMMIT

| Safe to commit ✅ | Never commit ❌ |
|---|---|
| .tf files using `var.*` references | terraform.tfvars with real values |
| terraform.tfvars.example with fake GUIDs | .terraform/ directory |
| GitHub Actions .yml using `${{ secrets.* }}` | terraform.tfstate or .backup |
| Python code reading from env variables | .env files |
| local.settings.json.example with fake values | local.settings.json with real values |
| README with generic architecture | Any file with real subscription/tenant IDs |
| CLAUDE.md and VSCODE_PROMPT.md | API keys anywhere in code |

---

## ⛔ GUARDRAILS — NEVER DO THESE

- Never run `terraform apply` manually (except Phase 0 bootstrap)
- Never commit terraform.tfvars or any file with real credentials
- Never hardcode GUIDs or Azure identifiers in .tf files
- Never create resources with public IP addresses
- Never combine multiple phases in one branch or PR
- Never merge a phase branch without the pipeline running and plan reviewed
- Never set `DRY_RUN=false` on Respond Agent without deliberate review
- Never skip the Pre-Phase Approval Summary

---

*sentinel-claude-soc VSCODE_PROMPT.md — public repo edition — Rijens7065/sentinel-claude-soc*
