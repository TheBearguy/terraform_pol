Below is a **clean mental model** of how **multiple Terraform states** coexist, how they **share DynamoDB**, and how **locking actually scales** without collisions.

---

## First: what “a different Terraform state” actually means

A **Terraform state is uniquely defined by its backend configuration**, not by DynamoDB.

Specifically, a state is identified by the tuple:

```
(backend type, backend config)
```

For S3 backends, the **true state identity** is:

```
S3 bucket + S3 key
```

Example:

```hcl
bucket = "tf-state-prod"
key    = "network/terraform.tfstate"
```

That `key` is the **state address**.

Everything else (including DynamoDB) is auxiliary.

---

## Multiple Terraform states: the normal pattern

In real systems you almost always have:

* One state per **layer**
* One state per **lifecycle boundary**
* One state per **blast radius**

Example layout:

```
infra/
 ├── vpc/
 │    └── backend key: vpc/terraform.tfstate
 ├── eks/
 │    └── backend key: eks/terraform.tfstate
 ├── db/
 │    └── backend key: db/terraform.tfstate
 └── app/
      └── backend key: app/terraform.tfstate
```

Each directory = **independent Terraform state**.

They may:

* Use the **same S3 bucket**
* Use the **same DynamoDB table**
* Still be **fully isolated**

---

## How DynamoDB locking works across multiple states

### Critical fact

**DynamoDB does not store “a lock”**
It stores **many locks**, keyed by `LockID`.

### What is the LockID?

Terraform computes:

```
LockID = <S3 bucket>/<S3 key>
```

Example:

```json
LockID: "tf-state-prod/vpc/terraform.tfstate"
```

Another state:

```json
LockID: "tf-state-prod/eks/terraform.tfstate"
```

These are **different partition keys**.

Therefore:

* Same DynamoDB table
* Same AWS account
* Same region
* Same time

➡ **Zero interference**

---

## DynamoDB table structure (important)

Terraform expects:

```text
Partition key: LockID (String)
```

No sort key.
No GSIs required.
No TTL required.

Each Terraform state occupies **exactly one row** at a time.

---

## Lock lifecycle per state

For **each Terraform operation**:

1. Terraform computes backend config
2. Resolves S3 bucket + key
3. Computes LockID
4. Attempts:

```text
PutItem with condition: attribute_not_exists(LockID)
```

### Outcomes

* Success → lock acquired
* Failure → another writer exists → abort

This happens **per state**, not globally.

---

## Two Terraform states running concurrently

### Scenario

* State A: `vpc/terraform.tfstate`
* State B: `eks/terraform.tfstate`

Both use:

```hcl
dynamodb_table = "terraform-locks"
```

### Result

| State | LockID                | Allowed concurrently? |
| ----- | --------------------- | --------------------- |
| VPC   | tf-state-prod/vpc/... | ✅                     |
| EKS   | tf-state-prod/eks/... | ✅                     |

They **do not block each other**.

Terraform does **not** serialize across states.

---

## When locking *does* block

Blocking happens **only when**:

* Same backend
* Same bucket
* Same key

Example:

* Two users run Terraform in **same directory**
* Or same CI pipeline triggered twice
* Or workspace collision (more below)

---

## Workspaces: same backend, multiple logical states

Workspaces are often misunderstood.

### Backend behavior with workspaces

Terraform rewrites the key internally:

```text
key = "app/terraform.tfstate"
```

Becomes:

```text
env:/dev/app/terraform.tfstate
env:/prod/app/terraform.tfstate
```

Each workspace gets:

* Different S3 object
* Different LockID
* Different DynamoDB row

So:

* `dev` and `prod` do not block each other
* Two `dev` applies will block

---

## Cross-state dependencies (important connection point)

Now the **real reason states interact**.

Terraform states **never share memory**.

They connect via:

* `terraform_remote_state`
* Or data sources reading live infra

Example:

```hcl
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "tf-state-prod"
    key    = "vpc/terraform.tfstate"
    region = "ap-south-1"
  }
}
```

Key properties:

* **Read-only**
* No locking required
* No write access
* No state mutation

You can safely read remote state **even while it is locked**.

---

## Why remote-state reads don’t lock

Reason:

* Locking exists to prevent **write-write conflicts**
* Reads are safe
* Terraform pulls the S3 object version directly

If a write is in progress:

* Either old version or new version is read
* Never a partial write (S3 guarantees atomic overwrite)

---

## Failure modes you must understand

### 1. Two states managing same resource

This bypasses locking entirely.

Example:

* State A creates EC2 instance
* State B imports same instance

Now:

* Both states think they own it
* Locking cannot help
* Destruction is inevitable

This is a **design error**, not a tooling issue.

---

### 2. Shared DynamoDB table deleted

Result:

* Terraform still runs
* **No locking**
* Silent race conditions

This is catastrophic.

Always protect the lock table with:

* IAM deny delete
* SCPs if possible

---

### 3. Stale locks

Caused by:

* Power loss
* CI job killed
* SIGKILL

Resolution:

```bash
terraform force-unlock <LOCK_ID>
```

Only do this when **certain** no other process is running.

---

## Final consolidated model

* Each Terraform state = one S3 object
* Each state = one DynamoDB row when active
* DynamoDB table is **multi-tenant**
* Locking is **per-state**, not global
* States coordinate only through explicit reads
* Terraform is **single-writer per state**, not distributed consensus

If you understand this, you understand Terraform’s operational core.