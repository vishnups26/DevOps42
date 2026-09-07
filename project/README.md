# Azure DevOps Pipeline + Terraform Deployment (Edited Version)

This is an edited/hardened version of the original "Azure DevOps Pipeline + Terraform Deployment"
project. It deploys an Azure Service Bus namespace + two queues via Terraform, orchestrated by
a multi-stage Azure DevOps YAML pipeline with a manual approval gate before apply.

## What was changed vs. the original

| # | Issue in the original | Fix in this version |
|---|---|---|
| 1 | `Terraform_Plan` job never ran `checkout: self` — `terraform init`/`plan` had no source to work against | Added `checkout: self` as the first step of the Plan job |
| 2 | `Apply` stage ran `terraform apply -auto-approve`, which **re-plans** at apply time — what gets approved isn't necessarily what gets applied | `Plan` now saves `-out=tfplan` and publishes it as a pipeline artifact; `Apply` downloads and applies that exact file — no drift between review and apply |
| 3 | Backend (`resource_group_name`, `storage_account_name`, etc.) hardcoded in `providers.tf` | Backend block left partial; values passed via `-backend-config` at `terraform init` time, so the same code deploys to any environment |
| 4 | Service Bus namespace name wasn't guaranteed globally unique | Added a `random_id` suffix, persisted in state |
| 5 | No format/syntax gate before touching Azure | Added a `Terraform_Validate` stage (`terraform fmt -check`, `terraform validate`) that runs first and fast-fails |
| 6 | Relied on whatever Terraform version happened to be preinstalled on the hosted agent | Pipeline pins and installs an explicit Terraform version (default `1.7.5`, overridable via parameter) |
| 7 | No root-level pipeline file — ADO's default "New pipeline" flow expects `azure-pipelines.yml` at repo root | Added `azure-pipelines.yml` at the repo root as the entry point for `env01` |
| 8 | No outputs after apply | Added `terraform/outputs.tf` (resource group name, namespace name/ID, queue names) |
| 9 | Real `.tfvars` files are (correctly) gitignored, leaving nothing to copy from | Added `terraform/tfdemo.env01.tfvars.example` |

Everything else — the overall topology, the Service Principal setup, the state-storage-account
setup, and the subscription permissions — is unchanged from the original tutorial and still
applies as written below.

---

## Repo layout

```
.
├── azure-pipelines.yml                     # NEW - root entry point (env01)
├── deploy/
│   ├── templates/
│   │   └── terraform-template.yml          # shared Validate/Plan/Apply template
│   └── tfdemo-env01-terraform.yml          # env01 pipeline (equivalent to root file)
└── terraform/
    ├── main.tf                             # resource group
    ├── providers.tf                        # partial backend config
    ├── servicebus.tf                       # namespace + 2 queues (+ random suffix)
    ├── variables.tf
    ├── outputs.tf                          # NEW
    └── tfdemo.env01.tfvars.example         # NEW - copy to tfdemo.env01.tfvars
```

---

## One-time setup (manual, in the Azure Portal)

### 1. Create the Service Principal

* **Microsoft Entra ID → App registrations → New registration**: `tfdemo-spn`
* Note the **Application (client) ID** and **Directory (tenant) ID**
* **Certificates & secrets → New client secret** named `ADO`; note the value

### 2. Create the Terraform state storage account

* Resource group: `tfstate-tfdemo-rg`
* Storage account: `tfstatetfdemostg` (must be globally unique — change if taken)
* Blob container: `tfstate`
* Grant the SPN the **Storage Blob Data Contributor** role on this storage account (**Access control (IAM)**)

Terraform creates the actual `tfdemo.env01.tfstate` file itself on first run — nothing to
pre-create there.

### 3. Grant subscription permissions

* On the target subscription → **Access control (IAM)** → new **role assignment** →
  grant the SPN the **Contributor** role.
* (Tighter alternative: pre-create the target resource group and scope the role assignment to
  just that resource group instead of the whole subscription.)

---

## Azure DevOps configuration

### Variable group

**Pipelines → Library → + Variable group**, name it `Terraform_SPN`, and add:

| Variable | Value |
|---|---|
| `ARM_CLIENT_ID` | SPN application (client) ID |
| `ARM_CLIENT_SECRET` | SPN client secret (mark as **secret**) |
| `ARM_SUBSCRIPTION_ID` | Target subscription ID |
| `ARM_TENANT_ID` | Directory (tenant) ID |

These four names are meaningful to Terraform's `azurerm` provider — when present as environment
variables on the agent, Terraform authenticates with them automatically.

### Environment + approval

**Pipelines → Environments → New environment**, name it `env01` → **Approvals and checks** →
add an **Approval** check with yourself (or the appropriate approvers) as the required reviewer.
This is what gives you a manual gate between `Plan` and `Apply`.

### Create the pipeline

* **Pipelines → New pipeline → Azure Repos Git** → select your repo
* **Existing Azure Pipelines YAML file** → select **`/azure-pipelines.yml`** (the new root file)
* **Save** (don't run yet if you want to review the name first)
* Rename the pipeline to something meaningful, e.g. `tfdemo-env01-terraform`, if you like

Before the first run, copy `terraform/tfdemo.env01.tfvars.example` to
`terraform/tfdemo.env01.tfvars` and adjust `project` / `environment` / `location` as needed
(this file is gitignored on purpose — it's environment-specific and can contain
environment-sensitive values in more complex setups).

---

## Running it

1. Trigger the pipeline (it defaults to `trigger: none`, so it's manual/triggered-only).
2. **Terraform_Validate** runs `fmt -check` and `validate` — fails fast on formatting/syntax issues.
3. **Terraform_Plan** initializes against the real backend, runs `terraform plan -out=tfplan`,
   and publishes `tfplan` as a pipeline artifact.
4. Review the plan output in the logs.
5. **Terraform_Apply** waits for your approval on the `env01` environment, then downloads the
   exact `tfplan` artifact and runs `terraform apply` against it — no re-planning, no surprises.
6. On first run, you'll be prompted to grant the pipeline access to the `Terraform_SPN` variable
   group and the `env01` environment — click **Permit**.

## Scaling to more environments

Copy `deploy/tfdemo-env01-terraform.yml` (or the root `azure-pipelines.yml`) to
`deploy/tfdemo-env02-terraform.yml`, and update only the `variables` block:
`tfvarsFile`, `adoEnvironment`, and `backendKey` (so each environment gets its own state file).
No Terraform code changes are required — that was the whole point of parameterizing the backend
and variables.

---

## 🛠️ Author & Community

Original tutorial by **[Harshhaa](https://github.com/NotHarshhaa)** 💡, part of the
[DevOps-Projects](https://github.com/NotHarshhaa/DevOps-Projects) repository.

* **GitHub**: [@NotHarshhaa](https://github.com/NotHarshhaa)
* **Blog**: [ProDevOpsGuy](https://blog.prodevopsguytech.com)
* **Telegram Community**: [Join Here](https://t.me/prodevopsguy)

If you found this useful, consider starring ⭐ the original repository.
