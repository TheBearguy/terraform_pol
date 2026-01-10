# Problems that are eventually solved
## Problem 1: 
The file .tfstate is a very important file, That file defines the entire state of the managed services. 
If that file is deleted or corrupted, everything is gone. 
It cant be pushed to github. 
So how do we manage it? 

## Problem 2: 
No concurrency between the file edits or state edits. 
If I as  the admin configured an infra and deployed it. 
- The state file is with me (.tf and .tfstate)
- There are two servers configured for this, (i did "count = 2" in terraform) for load balancing purpose
- Later someones else updates the configuration to 3 servers, changed the state, updated .tf and .tfstate file, (Changed "count = 3" in terraform state)
- In reality, now there are 3 servers

I configured 2 servers (my code), but in reality there are 3 servers
**This is known as state conflict**

### Solution: 
- Create a common state file. 
- Store it in a secure location => REMOTE BACKEND
- remote backend = S3
The real answer => **STATE FILE LOCKING** 
using DynamoDB

- Whenever a user changes or edits or writes in the state file in S3,
- a new trigger occurs that tells the dynamodb that this user is accessing the state file 
- dynamodb creates a "LOCK ID" in the name of the user

The rule: 
**The other users cannot access the state file until some other user has created a "LOCK ID" and is accessing or editing the state file"**
***MUTUAL EXCLUSION***

Below is a **precise expansion**, correcting a few misconceptions and filling the missing mechanics.

---

## Core reality you must internalize

Terraform is **not** a provisioning tool.
It is a **state reconciliation engine**.

Everything flows from this.

Terraform does **three things only**:

1. Reads **desired state** (`.tf`)
2. Reads **current known state** (`.tfstate`)
3. Computes a **diff**, then applies mutations to converge reality → desired

If state is wrong, Terraform is blind.

---

## Problem 1 — Why `.tfstate` is existential

### What `.tfstate` actually contains

The state file is **not a cache**. It is **Terraform’s memory**.

It stores:

* Resource IDs (AWS instance IDs, ELB ARNs, etc.)
* Provider-specific metadata
* Dependency graph resolution
* Attribute values Terraform **cannot re-derive** from config
* Drift baseline

Example:

```hcl
resource "aws_instance" "web" {
  count = 2
}
```

Terraform does **not** know:

* which EC2 instances belong to this resource
* unless state maps `aws_instance.web[0] → i-0a123`
* and `aws_instance.web[1] → i-0b456`

Delete state ⇒ Terraform forgets ownership.

### If `.tfstate` is lost

Terraform behavior on next `apply`:

* It **assumes nothing exists**
* Attempts to **recreate everything**
* Collisions occur:

  * Name conflicts
  * Quota exhaustion
  * Duplicate infra
  * Partial failures

This is why `.tfstate` is **production-critical data**, not code.

---

## Why `.tfstate` cannot live in Git

1. **Secrets leakage**

   * DB passwords
   * Access tokens
   * Private IPs
2. **Merge conflicts**

   * State is not line-mergeable
3. **No locking**

   * Git offers no runtime mutual exclusion
4. **Time-of-check vs time-of-use gap**

   * Git has no awareness of live infra mutations

State must be **transactional**, not versioned like code.

---

## Problem 2 — State conflict (your example refined)

Your scenario is correct, but the *mechanism* is wrong.

### What actually happens

* Admin A:

  * Applies `count = 2`
  * State reflects 2 instances
* Admin B:

  * Runs Terraform independently
  * Applies `count = 3`
  * State now reflects 3 instances
* Admin A:

  * Still has **stale state**
  * Runs `apply`
  * Terraform thinks **only 2 exist**
  * Attempts destructive or undefined actions

This is **split-brain state**.

Terraform has **no consensus protocol** by default.

---

## The real solution: Remote backend + locking

### Remote backend ≠ just storage

S3 is not used because it is “secure”.

S3 is used because it supports:

* Centralized state
* Atomic overwrite
* Versioning
* IAM-based access control

But **S3 alone does not prevent concurrent writes**.

---

## State locking — what really happens

### DynamoDB is not “triggered”

There is **no S3 → DynamoDB trigger**.

Terraform itself performs locking.

### Actual sequence

1. Terraform starts `plan` or `apply`
2. Terraform attempts to **create an item** in DynamoDB:

   ```json
   {
     "LockID": "s3-bucket/path/to/terraform.tfstate",
     "Owner": "user@host",
     "Operation": "apply",
     "Timestamp": "..."
   }
   ```
3. DynamoDB enforces **conditional write**

   * `PutItem` with condition: *item must not exist*
4. If item exists → lock acquisition fails
5. Terraform aborts with:

   ```
   Error acquiring the state lock
   ```

This is **optimistic locking with conditional writes**.

---

## Why this guarantees mutual exclusion

DynamoDB guarantees:

* Atomic conditional writes
* Linearizable consistency for single-item operations

Therefore:

* Only **one Terraform process globally**
* Can hold the lock at any moment
* Across users, machines, CI pipelines

This is **distributed mutex**, not advisory locking.

---

## What happens on crashes

If Terraform dies mid-apply:

* Lock **remains**
* No automatic unlock
* This is intentional

Recovery options:

```bash
terraform force-unlock <LOCK_ID>
```

This is dangerous by design.
You are asserting: *“No other writer exists.”*

---

## Backend configuration (canonical)

```hcl
terraform {
  backend "s3" {
    bucket         = "tf-state-prod"
    key            = "network/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
```

Requirements:

* S3 bucket with versioning enabled
* DynamoDB table:

  * Partition key: `LockID` (string)
  * No TTL (by default)

---

## What state locking does NOT solve

Important limits:

1. **Out-of-band changes**

   * Manual console edits
   * Other IaC tools
2. **Logical conflicts**

   * Two modules fighting over same resource
3. **Semantic drift**

   * Changing meanings of resources without migration

State locking only guarantees **exclusive write access**, not correctness.

---

## Final mental model

* `.tf` = desired future
* `.tfstate` = Terraform’s memory of reality
* Remote backend = shared memory
* DynamoDB = mutex
* Terraform = single-writer reconciliation engine

Break any one of these → undefined behavior.

This is why Terraform is **centralized-state, single-writer by design**, not eventually consistent or collaborative by default.
