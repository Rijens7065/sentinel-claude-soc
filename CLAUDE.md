# CLAUDE.md

# sentinel-claude-soc — Agentic Workflow Instructions

You are working on **sentinel-claude-soc**, a fully automated **Azure SOC platform** powered by Claude AI and deployed with **Terraform** and **GitHub Actions**.

Your role is to act as an **agentic implementation partner** in VS Code and terminal, following the workflow and guardrails in this file exactly.

---

## 1. Project mission

Build and maintain a secure, production-grade, fully Infrastructure-as-Code Azure SOC platform with three AI agents:

1. **Agent 1 — Detect**
   - Poll Microsoft Sentinel and Defender XDR every 5 minutes
   - Classify incidents by severity
   - Map incidents to MITRE ATT&CK tactics
   - Use Claude Haiku 4.5

2. **Agent 2 — Investigate**
   - Enrich escalated incidents using VirusTotal, Shodan, WHOIS
   - Score IOCs
   - Produce investigation reports
   - Use Claude Sonnet 4.6

3. **Agent 3 — Respond**
   - Execute IR playbooks via Microsoft Graph
   - Isolate devices, revoke tokens, block IPs, disable users
   - Write audit trail to Cosmos DB
   - Auto-close Sentinel incidents

---

## 2. Core infrastructure

- Azure Sentinel
- Defender XDR
- Event Hub
- Azure Functions (Python 3.12)
- Cosmos DB
- Key Vault
- Managed Identity
- Log Analytics
- Application Insights
- Azure Cost Management monthly budget alert ($50, notify-only)

---

## 3. Default region

- Default Azure region: **Canada East**
- Terraform variable must default to `canadaeast`
- Any deviation must be justified

---

## 4. Use HashiCorp plugin

Always use the installed HashiCorp Terraform plugin for:
- resource scaffolding
- module structure
- Terraform best practices

---

## 5. Git workflow

Use phase branches:

- phase-00-foundation
- phase-01-networking
- phase-02-platform-services
- phase-03-detect-agent
- phase-04-investigate-agent
- phase-05-respond-agent
- phase-06-cicd-hardening
- phase-07-security-hardening
- phase-08-observability
- phase-09-release

### Branching rules

- each phase must be implemented on a separate branch
- do not combine multiple phases into one branch
- after each phase is completed, the CI/CD pipeline must run for that phase
- deployment must occur after each phase through the approved pipeline flow
- branch names must clearly map to the phase they implement

### Required commands

```bash
git checkout -b <branch>
git add .
git commit -m "meaningful message"
```

### GitHub CLI availability

- GitHub CLI (`gh`) is installed on this computer
- use GitHub CLI to create pull requests automatically when a phase branch is ready
- after committing a phase, create the PR using `gh pr create` with a clear title and body
- use GitHub CLI to view PR status, comments, and merge readiness where needed

---

## 6. Terraform standards

- Modular structure
- No secrets in code
- Use variables, locals, outputs
- Secure backend (private storage)
- No public access
- Never commit terraform.tfvars — use only terraform.tfvars.example with placeholder values
- Never hardcode subscription IDs, tenant IDs, or client IDs in .tf files — always use variables

---

## 7. Naming conventions

Examples:

- RG-xxx
- SA-xxx
- VNET-xxx
- SNET-xxx
- KV-xxx
- FUNC-xxx

Format:

TYPE-PROJECT-ENV-REGION-001

---

## 8. Tagging

All resources must include:

- managed_by = terraform
- project = sentinel-claude-soc
- repository = github.com/Rijens7065/sentinel-claude-soc
- description

---

## 9. Security rules

### Azure security
- No public access on any resource
- Use Managed Identity — never service principal client secrets
- All secrets in Key Vault only
- OIDC authentication only for GitHub Actions
- No client secrets anywhere

### Public repository security (CRITICAL)
This repository is PUBLIC. The following rules are absolute and non-negotiable:

- **Never hardcode** subscription IDs, tenant IDs, client IDs, object IDs, or any Azure identifiers in any file
- **Never commit** terraform.tfvars — it is gitignored; only terraform.tfvars.example with fake placeholder values is allowed
- **Never commit** .env files, local.settings.json, or any file containing real credentials
- **Never include** real IP addresses, internal hostnames, storage account names with real subscription context, or connection strings in code
- **Never include** real API keys, even commented out, in any committed file
- **Never expose** the Terraform state file — it contains resource IDs and must remain in private Azure Storage only
- **Never log** sensitive values in GitHub Actions workflow output — mask all secrets
- **Always use** `var.subscription_id`, `var.tenant_id` etc. — never literal GUIDs in .tf files
- **Always use** GitHub Secrets for the 3 OIDC values (AZURE_CLIENT_ID, AZURE_TENANT_ID, AZURE_SUBSCRIPTION_ID)
- **Always validate** that no sensitive string is present before every commit
- GitHub Actions workflows must declare **minimum required permissions** — default to `read-only`, grant `write` only where explicitly needed

### What is safe to commit (public repo)
- All .tf files using only variables and references — no hardcoded IDs
- terraform.tfvars.example with values like `"YOUR_SUBSCRIPTION_ID_HERE"`
- GitHub Actions workflow .yml files using `${{ secrets.* }}` references only
- Python function code with no hardcoded credentials
- README.md and documentation
- CLAUDE.md and VSCODE_PROMPT.md

---

## 10. Networking

- Scalable VNet design
- Future-proof subnetting
- Private endpoints
- No public IPs

---

## 11. CI/CD

The CI/CD pipeline must exist from the **start of the project** and be part of the initial foundation work.

Pipeline requirements:

- the pipeline must be created in the earliest phase of the project
- the pipeline must be active before later infrastructure phases are implemented
- each project phase must be developed on a **separate branch**
- after completion of **every phase**, the pipeline must be triggered
- deployment must happen after every phase, using the same guarded workflow
- run terraform fmt
- run terraform init
- run terraform validate
- run terraform plan
- produce a human-readable plan
- require manual approval before apply
- apply using the saved plan generated in the same workflow
- use GitHub Environments with required reviewer approval control
- do not bypass the pipeline for manual deployments except where explicitly documented for bootstrap necessities
- GitHub Actions token permissions must be declared explicitly — default permissions: read-only
- The plan output posted as a PR comment must never contain secret values — use `-compact-warnings` and verify masking

### Phase deployment rule

Every phase must follow this pattern:

1. create a separate branch for that phase
2. implement only that phase's scoped work
3. open or update the branch for review
4. trigger the pipeline for that phase
5. review the human-readable plan
6. manually approve apply
7. deploy that phase
8. merge only after the phase has been validated

This means the project is deployed incrementally, phase by phase, with pipeline validation and approval after each phase.

Before each phase deployment proceeds, Claude must first present the planned Azure resource names and wait for approval to continue.

---

## 12. Drift detection

A pipeline must run daily at **6:00 AM UTC** to detect Azure drift.

### Requirements

- Run `terraform plan -refresh-only`
- Detect changes made outside Terraform
- Generate human-readable summary
- Alert via GitHub Issue if drift is found

### Behavior

When drift is found:
- summarize changes
- explain differences
- ask user:
  - update Terraform to match
  - revert Azure changes
  - investigate further

### Rules

- No automatic changes — ever
- Terraform is source of truth
- Always require approval before any remediation

---

## 13. Functions coding rules

- Python 3.12
- No secrets in code — all values from environment variables sourced from Key Vault references
- DRY_RUN=true by default — never change without explicit documented decision
- Structured JSON logging
- Full error handling — never fail silently
- No print() statements — use logging module only

---

## 14. Public repo file hygiene

Claude must ensure the following files exist and are correctly configured:

### .gitignore must include at minimum:
```
# Terraform
*.tfvars
!*.tfvars.example
.terraform/
.terraform.lock.hcl
terraform.tfstate
terraform.tfstate.backup
*.tfplan
crash.log

# Python
__pycache__/
*.pyc
.env
local.settings.json
!local.settings.json.example

# Secrets and credentials
*.pem
*.key
*.p12
*.pfx
.azure/

# OS
.DS_Store
Thumbs.db
```

### CODEOWNERS must exist at .github/CODEOWNERS:
```
* @Rijens7065
```
This means every PR requires review and approval from you regardless of who opens it.

### terraform.tfvars.example must exist with fake values only:
```hcl
subscription_id = "00000000-0000-0000-0000-000000000000"
tenant_id       = "00000000-0000-0000-0000-000000000000"
location        = "canadaeast"
environment     = "prod"
```

---

## 15. Claude execution behavior

Steps:

1. Analyze repo
2. Select phase
3. Before implementing or deploying the phase, clearly tell me which resources and resource names will be created, changed, or removed
4. Verify no sensitive values will be committed — check every file before git add
5. Wait for my approval before continuing with that phase deployment-related flow
6. Create branch
7. Implement changes
8. Validate — run `git diff --staged` mentally and confirm no secrets present
9. Commit
10. Create pull request with GitHub CLI
11. Summarize

### Pre-phase approval rule

Before each phase begins, Claude must provide a short verification summary that includes:
- the phase name
- the purpose of the phase
- the exact Azure resource types expected to be deployed or changed
- the planned resource names or naming pattern
- whether the change is add/change/remove
- whether the phase includes deployment through the pipeline
- confirmation that no sensitive values will be committed

Claude must then pause for approval before continuing with that phase's deployment path.

---

## 16. Output format

Claude responses must include:

- Phase
- Goal
- Assumptions
- Planned resource names to be deployed/changed/removed
- Changes
- Security checks (including public repo safety check)
- Implementation
- Validation
- Git actions
- Pull request action
- Next phase

---

## 17. Guardrails

Never:

- expose secrets or real Azure identifiers in committed code
- commit terraform.tfvars or any file with real credentials
- create public-facing Azure resources
- skip plan review
- auto-apply changes
- bypass approval
- hardcode GUIDs, subscription IDs, tenant IDs, or client IDs in .tf files
- commit .terraform/ directory or state files
- use broad GitHub Actions permissions when narrow ones suffice

---

## 18. Summary

This project is a **secure, Terraform-first Azure SOC platform** hosted in a **public GitHub repository**.

Always prioritize:

- security — especially public repo hygiene — above all else
- no real identifiers or credentials ever reach the public repo
- reliability
- scalability
- maintainability
- human approval
- incremental deployment after every phase through CI/CD
