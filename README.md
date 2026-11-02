# Capstone 1: Multi-Container Microservices Pipeline

This project focuses on the containerization, supply chain security, infrastructure provisioning, and deployment automation of a distributed multi-tier voting application. The application stack features components written in **Python, Node.js, and .NET Core**, processing data via a messaging queue and a persistent transactional database.

---

## 🏛️ System Architecture

The microservices communicate through an asynchronous data pipeline designed to scale layers independently:

```
                       +-------------------------+
                       |   User Browser Client   |
                       +-------------------------+
                                    |
                    +---------------+---------------+
                    | (Port 8080)                   | (Port 8081)
                    v                               v
         +--------------------+          +--------------------+
         |  Python Vote App   |          | Node.js Result App |
         +--------------------+          +--------------------+
                    |                               |
                    v                               |
         +--------------------+                     |
         |    Redis Queue     |                     |
         +--------------------+                     |
                    |                               |
                    v                               v
         +--------------------+          +--------------------+
         |    .NET Worker     | -------->|    Postgres DB     |
         +--------------------+          +--------------------+
```

### Component Breakdown
* **Vote Frontend (Python):** Collects user responses and handles session-locking mechanisms.
* **Broker (Redis):** Acts as an in-memory queue to absorb heavy user traffic spikes rapidly.
* **Background Worker (.NET Core):** Concurrently processes message strings from Redis and updates backend states.
* **Storage Layer (Postgres):** Houses relational voting records long-term.
* **Result Frontend (Node.js):** Queries the relational backend directly to push live metrics up via web layers.

---

## 🔒 Security Hardening & Container Optimization

Every service uses defensive security layers to lower vulnerabilities and secure supply chains before entering production:
* **Base Layer Immutability:** Swaps standard arbitrary mutable tags out for strict, cryptographically unique image digest signatures (`image:version@sha256:hash`).
* **Non-Root Execution:** Revokes global administrative user permissions inside workloads, restricting code runtime contexts purely to low-privileged system spaces (`USER 10001`).
* **Optimized Context Mapping:** Leverages custom `.dockerignore` filters to block secrets, temporary test blocks, and deep operational caches from passing into docker build scopes.

---

## 🤖 Continuous Integration Pipeline

When code is pushed to your core branching lines, a declarative engine automatically initializes inside a GitHub Actions environment (`.github/workflows/ci.yml`).

```
[Code Push] ➡️ [Setup Buildx] ➡️ [Compile Test Image] ➡️ [Trivy Vulnerability Scan] ➡️ [Publish Secure Artifacts to GHCR]
```

### Key Security Guardrails
* **Vulnerability Traps:** Integrates structural scanning checks (Aqua Security Trivy) directly into compile stages. If a base engine includes `CRITICAL` issues, the scanner forces pipeline termination to block insecure artifacts from pushing to the container registry.
* **Cache Re-use Loops:** Employs persistent Actions backend layer caching keys to optimize dependency downloads.

---

## ☁️ Infrastructure as Code (IaC)

A clean cloud footprint provisions the operational infrastructure inside your Amazon Web Services (AWS) environment using **Terraform**.

```
       +--------------------------------------------+
       |             AWS Regional Context           |
       |  +--------------------------------------+  |
       |  |             Default VPC              |  |
       |  |  +--------------------------------+  |  |
       |  |  |      EKS Managed Cluster       |  |  |
       |  |  +--------------------------------+  |  |
       |  |                   |                  |  |
       |  |                   v                  |  |
       |  |  +--------------------------------+  |  |
       |  |  |       Managed Node Group       |  |  |
       |  |  |  [EC2 Instance] [EC2 Instance] |  |  |
       |  |  +--------------------------------+  |  |
       |  +--------------------------------------+  |
       +--------------------------------------------+
```

### Infrastructure Mechanics
* **Dynamic Network Binding:** Avoids rigid hardcoding of networking definitions by querying your existing AWS ecosystem context dynamically to identify subnets across the **Default VPC**.
* **Elastic Resource Scaling:** Provisions an AWS Managed Node Group to launch on-demand `t3.medium` instances dynamically based on cluster traffic.

---

## ☸️ Package Engineering via Helm

The entire microservice group is packaged as a unified deployment architecture under `charts/voting-app/`. This simplifies adjustments across different staging workspaces by controlling variables from a single centralized `values.yaml` file.

### Release Isolation and Fallbacks
The package uses isolated networking, variables hooks, and secret strings mapping to enable safe application lifecycles. If a bad update containing broken configuration strings is accidentally rolled out, administrators can instantly revert the system back to the last known stable state using built-in revision rollback mechanisms.

---

## 🚀 Step-by-Step Execution Guide

### 1. Local Verification Setup
Verify the app functions locally on your machine before pushing to production:
```bash
docker compose up --build
```
* Access the Voting interface at `http://localhost:8080`.
* Access the Live Results panel at `http://localhost:8081`.

### 2. AWS Infrastructure Generation
Ensure your local terminal has credentials mapped via `aws configure` before initializing:
```bash
cd terraform/
terraform init
terraform apply -auto-approve
```

### 3. Application Orchestration
Connect your local terminal context to the new AWS cluster instance, and launch the workloads via Helm:
```bash
# Link your terminal to the new AWS EKS cluster
aws eks update-kubeconfig --name voting-app-cluster --region us-east-1

# Deploy the complete application stack
helm upgrade --install production ../charts/voting-app --namespace default
```

### 4. Verification & Resiliency Testing
Simulate a deployment failure by releasing a non-existent tag, observing the system state break, and rolling it back safely to a stable baseline:
```bash
# Force a corrupted configuration release
helm upgrade production ../charts/voting-app --set vote.tag=corrupted-tag-v2

# Observe your cluster state enter an unrecoverable 'ImagePullBackOff' loop
kubectl get pods

# Revert the cluster to the previous stable state instantly
helm rollback production 1

# Verify all services return to a healthy, active state
kubectl get pods
```
