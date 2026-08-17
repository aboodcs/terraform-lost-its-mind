# Terraform Lost Its Mind

> An OCI infrastructure personality engine. Three integers decide whether you get a single public VM, a hardened private instance behind a Bastion, or a fully load-balanced pair — no code changes required.

![Architecture Overview](docs/images/architecture-overview.svg)

[![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.5.0-623CE4?logo=terraform)](https://www.terraform.io/)
[![OCI Provider](https://img.shields.io/badge/OCI%20Provider-~%3E6.0-F80000?logo=oracle)](https://registry.terraform.io/providers/oracle/oci/latest)
[![Oracle Cloud](https://img.shields.io/badge/Oracle%20Cloud-eu--amsterdam--1-F80000?logo=oracle)](https://www.oracle.com/cloud/)

---

## What Is This?

Most Terraform projects do one thing: create a VM, or a bucket, or a cluster.

This project does something different. It reads three numeric inputs — **budget**, **security_level**, and **chaos_level** — and from those alone selects a complete infrastructure personality. The networking topology, instance count, security groups, routing, bastion access, and load balancer configuration all change based on what you declare.

The same codebase produces five distinct named personalities, each with its own architecture. You do not need to edit any Terraform file between them. You change the numbers, and the infrastructure changes with them.

The deployed application is an nginx server that reports back which personality is running, what values were provided, and what the infrastructure thinks of you.

---

## Why I Built It

Terraform's real power is not in declaring individual resources — it is in the conditional logic that wraps them. Most tutorials show `resource "aws_instance" "web" {}` and call it a day. This project was built to explore what happens when you push Terraform's expression system further:

- `count` expressions driven by `locals`
- `for_each` iterating over dynamically-sized instance lists
- Splat expressions for collecting IPs across counted resources
- Chained ternary logic selecting subnets, NSGs, and gateways
- Conditional resource creation for entire resource blocks (NAT Gateway, Bastion, Load Balancer)
- `templatefile()` for both the bootstrap script and the served HTML
- NSG-to-NSG source rules for Load Balancer-to-backend traffic isolation

---

## How It Works

![How It Works](docs/images/how-it-works.svg)

![Personality Engine](docs/images/personality-engine.svg)

---

## Personality Engine

Personalities are selected by a single chained conditional expression in `locals.tf`. **The first matching condition wins.**

```hcl
personality = (
  var.budget         < 20 ? "BROKE STUDENT"     :
  var.security_level >= 80 ? "PARANOID ENGINEER" :
  var.budget         >= 500 ? "CLOUD BILLIONAIRE" :
  var.chaos_level    >= 80 ? "CHAOTIC"           :
  "NORMAL ENGINEER"
)
```

| Priority | Condition | Personality | Message |
|----------|-----------|-------------|---------|
| **1** | `budget < 20` | **BROKE STUDENT** | *"We are NOT paying for that."* |
| **2** | `security_level >= 80` | **PARANOID ENGINEER** | *"I don't trust the Internet."* |
| **3** | `budget >= 500` | **CLOUD BILLIONAIRE** | *"Availability first. Money later."* |
| **4** | `chaos_level >= 80` | **CHAOTIC** | *"I provision therefore I am."* |
| **5** | *(default)* | **NORMAL ENGINEER** | *"Let's build something reasonable."* |

> **Critical:** `budget = 10` with `security_level = 99` resolves to **BROKE STUDENT**, not PARANOID ENGINEER. Budget is evaluated first.

Two derived booleans drive infrastructure layout:

| Local | Expression | Effect |
|-------|-----------|--------|
| `is_paranoid` | `security_level >= 80` | Private networking + Bastion |
| `is_billionaire` | `personality == "CLOUD BILLIONAIRE"` | Load Balancer + 2 instances |

---

## Architecture Modes

![Architecture Modes](docs/images/architecture-modes.svg)

**Normal / Broke / Chaotic** — All three share the same infrastructure: 1 instance in the public subnet with a public IP, HTTP/80 open to the internet, SSH restricted to `allowed_ssh_cidr`. Personality differences are cosmetic — only the served HTML changes.

**Paranoid Engineer** — When `security_level >= 80` (and `budget >= 20`), networking flips to private. The instance gets no public IP, lives in `10.0.2.0/24`, and is only reachable through an OCI Bastion. NSG `private_app` permits SSH and HTTP only from the Bastion's private endpoint IP (`/32`). A NAT Gateway handles outbound traffic for bootstrap.

**Cloud Billionaire** — When `budget >= 500` (and `security_level < 80`, `budget >= 20`): 2 instances in the public subnet, an OCI flexible Load Balancer in front with round-robin distribution. NSG `main` accepts HTTP only from NSG `public_entry`, so traffic must pass through the LB — direct instance access on port 80 is blocked.

---

## Request Flow

![Request Flow](docs/images/request-flow.svg)

---

## Project Structure

```
terraform-lost-its-mind/
├── .gitignore
├── README.md
├── scripts/
│   └── bootstrap.sh              # cloud-init: installs nginx, writes HTML, firewalld
├── website/
│   └── index.html.tpl            # templatefile() personality-branded HTML
├── docs/
│   └── images/
│       ├── architecture-overview.svg
│       ├── personality-engine.svg
│       ├── architecture-modes.svg
│       ├── request-flow.svg
│       └── how-it-works.svg
└── terraform/
    └── environment/
        ├── provider.tf            # OCI provider, Terraform >= 1.5.0
        ├── variables.tf           # All inputs with validation blocks
        ├── locals.tf              # Personality engine, derived booleans
        ├── data.tf                # Availability domains, Oracle Linux 9 image
        ├── network.tf             # VCN, IGW, NAT GW, route tables, subnets
        ├── security.tf            # NSGs, security rules, OCI Bastion
        ├── compute.tf             # Compute instances (count-driven)
        ├── load-balancer.tf       # LB, backend set, backends, listener
        ├── cloud-init.tf          # templatefile() for script and HTML
        ├── outputs.tf             # All Terraform outputs
        └── .terraform.lock.hcl   # OCI provider 6.37.0
```

---

## Prerequisites

| Requirement | Detail |
|-------------|--------|
| Terraform | `>= 1.5.0` |
| OCI Provider | `~> 6.0` (locked to `6.37.0`) |
| OCI Account | Compartment with appropriate IAM policies |
| OCI API Key | RSA key pair for API signing |
| SSH key pair | Ed25519 or RSA public key |
| `allowed_ssh_cidr` | Your IP in CIDR notation, e.g. `203.0.113.5/32` |

---

## OCI Authentication

Credentials are supplied via `terraform.tfvars` (excluded by `.gitignore`). The provider does **not** read from `~/.oci/config` — all values come from variables:

```hcl
provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  region           = var.region
  private_key_path = var.private_key_path
}
```

> **Never commit** `terraform.tfvars`, `*.pem`, `*.tfstate`, or `*.tfstate.*`. The `.gitignore` already excludes all of them.

---

## Input Variables

### Authentication — required, sensitive

| Variable | Description |
|----------|-------------|
| `user_ocid` | OCID of the OCI user |
| `tenancy_ocid` | OCID of the OCI tenancy |
| `fingerprint` | API signing key fingerprint |
| `private_key_path` | Absolute path to the `.pem` private key |

### Infrastructure — required

| Variable | Validation | Description |
|----------|-----------|-------------|
| `compartment_id` | — | OCID of the target compartment |
| `allowed_ssh_cidr` | — | CIDR for SSH access |
| `ssh_public_key` | — | Public key written to instance metadata |
| `budget` | `>= 0` | Drives personality selection |
| `security_level` | `0–100` | Drives `is_paranoid` |
| `chaos_level` | `0–100` | Drives CHAOTIC personality |
| `environment` | `dev`, `test`, `staging` | Used in resource tags |

### Optional — with defaults

| Variable | Default | Description |
|----------|---------|-------------|
| `region` | `eu-amsterdam-1` | OCI region |
| `instance_shape` | `VM.Standard.E4.Flex` | Compute shape |
| `project_name` | `terraform-lost-its-mind` | Resource names and tags |
| `owner` | `abdulrehman-yahya` | Freeform tag |
| `managed_by` | `Terraform` | Freeform tag |
| `cloud_provider` | `OCI` | Freeform tag |

---

## Deployment

**1. Create `terraform/environment/terraform.tfvars`:**

```hcl
user_ocid        = "ocid1.user.oc1..aaaa..."
fingerprint      = "xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx"
tenancy_ocid     = "ocid1.tenancy.oc1..aaaa..."
private_key_path = "/home/youruser/.oci/oci_api_key.pem"

compartment_id   = "ocid1.compartment.oc1..aaaa..."
allowed_ssh_cidr = "203.0.113.5/32"
ssh_public_key   = "ssh-ed25519 AAAA... you@host"

budget         = 100
security_level = 50
chaos_level    = 30
environment    = "dev"
```

**2. Initialize, plan, apply:**

```bash
cd terraform/environment
terraform init
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

> Use `-out=tfplan` so that `apply` uses the exact same inputs as `plan`. Without it, Terraform will re-prompt for personality variables, potentially resolving a different personality.

---

## Example Personality Runs

| Budget | Security | Chaos | Personality | Infrastructure |
|--------|----------|-------|-------------|----------------|
| `10` | `99` | `99` | **BROKE STUDENT** | 1 instance, public. Budget wins. |
| `50` | `90` | `50` | **PARANOID ENGINEER** | 1 instance, private. Bastion + NAT. |
| `600` | `50` | `90` | **CLOUD BILLIONAIRE** | 2 instances, public. Load Balancer. |
| `50` | `50` | `90` | **CHAOTIC** | 1 instance, public. No LB, no Bastion. |
| `100` | `40` | `20` | **NORMAL ENGINEER** | 1 instance, public. Default fallthrough. |
| `50` | `80` | `90` | **PARANOID ENGINEER** | `security_level = 80` meets threshold exactly. |
| `500` | `79` | `30` | **CLOUD BILLIONAIRE** | `budget = 500` meets threshold exactly. |
| `19` | `90` | `90` | **BROKE STUDENT** | `budget < 20` wins despite everything else. |

---

## Outputs

| Output | Null when |
|--------|-----------|
| `personality` | — |
| `personality_message` | — |
| `architecture_mode` | — |
| `instance_count` | — |
| `instance_ids` | — |
| `private_ips` | — |
| `public_ips` | Paranoid (`[]`) |
| `load_balancer_ip` | Not billionaire |
| `application_url` / `website_url` | Paranoid (`null`) |
| `website_urls` | Paranoid (`[]`) |
| `vcn_id` / `public_subnet_id` / `internet_gateway_id` | — |
| `private_subnet_id` / `network_security_group_id` | Not paranoid |

---

## Accessing the Application

**Normal / Broke / Chaotic:**
```bash
terraform output website_url   # → http://<PUBLIC_IP>
```

**Cloud Billionaire:**
```bash
terraform output load_balancer_ip   # → http://<LOAD_BALANCER_IP>
```
Allow 2–3 minutes after apply for health checks to mark backends healthy.

**Paranoid Engineer** — `website_url` is `null`. Access via OCI Bastion port-forward:

1. Create a Managed SSH session in OCI Console targeting the private instance IP on port 22.
2. Open the tunnel:

```bash
ssh -i ~/.ssh/id_ed25519 \
  -N \
  -L 8080:<PRIVATE_IP>:80 \
  -p 22 \
  <SESSION_OCID>@host.bastion.<REGION>.oci.oraclecloud.com
```

3. Open `http://localhost:8080` in your browser.

---

## Security Model

All traffic rules live in NSGs only. The Security List attached to both subnets is intentionally empty (see comment in `network.tf`).

| Mode | SSH | HTTP | Instance IP |
|------|-----|------|-------------|
| Normal / Broke / Chaotic | From `allowed_ssh_cidr` | From `0.0.0.0/0` | Public |
| Paranoid | From Bastion endpoint `/32` | From Bastion endpoint `/32` | **None** |
| Billionaire | From `allowed_ssh_cidr` | From NSG `public_entry` only | Public |

In Billionaire mode, instances block direct HTTP from `0.0.0.0/0` — traffic must enter through the Load Balancer.

---

## Terraform Concepts Demonstrated

| Concept | File |
|---------|------|
| `validation` blocks on variables | `variables.tf` |
| Chained ternary conditionals | `locals.tf` |
| `count` for conditional resources | `network.tf`, `security.tf`, `load-balancer.tf` |
| `for_each` over dynamic instance map | `load-balancer.tf` |
| Splat expressions `[*]` | `outputs.tf` |
| `for` expressions in outputs | `outputs.tf` |
| `templatefile()` | `cloud-init.tf` |
| `base64encode()` for user_data | `compute.tf` |
| Data sources (ADs, OS image) | `data.tf` |
| NSG-to-NSG source rules | `security.tf` |
| `min()` to cap instance count | `locals.tf` |
| Flex shape `shape_config` | `compute.tf` |
| Conditional subnet + IP assignment | `compute.tf` |

---

## Troubleshooting

**`502 Bad Gateway` from the Load Balancer**
- Wait 2–3 minutes — health checks take time to pass after apply
- Check `systemctl status nginx` on both instances
- Check `/var/log/terraform-bootstrap.log` for bootstrap errors

**Bastion tunnel connects but browser returns nothing**
- Confirm the correct `<PRIVATE_IP>` from `terraform output private_ips`
- Confirm local port `8080` is not already in use
- Confirm the Bastion session has not expired

**SSH to instance hangs**
- Paranoid mode: instance has no public IP — SSH directly will never work, use the Bastion
- Normal mode: confirm your current IP matches `allowed_ssh_cidr`

**`terraform apply` re-prompts for variables**
- You ran `plan` without `-out=tfplan` — always save the plan: `terraform plan -out=tfplan`

**`401-NotAuthenticated` from OCI API**
- Verify `private_key_path`, `fingerprint`, `user_ocid`, and `tenancy_ocid` in `terraform.tfvars`

---

## Destroy

```bash
cd terraform/environment
terraform destroy
```

Terraform will re-prompt for all personality variables. Supply the same values used during apply, or the destroy plan may differ from the applied state.

> This permanently deletes all OCI resources: VCN, instances, Load Balancer, NAT Gateway, Bastion, NSGs, subnets.

---

## Cost Awareness

| Resource | Created when | Billing |
|----------|-------------|---------|
| Compute instance(s) | Always | Per OCPU-hour (E4.Flex) |
| Boot volumes | Always | Per GB-month |
| Load Balancer | Billionaire only | Hourly + bandwidth |
| NAT Gateway | Paranoid only | Per GB processed |
| OCI Bastion | Paranoid only | Per session-minute |

`VM.Standard.E4.Flex` is not part of the OCI Always Free tier. Run `terraform plan` and review before applying.
