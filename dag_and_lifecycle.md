# Terraform Dependency, Graph Control, and Lifecycle

Terraform looks simple on the surface: you write files, run `apply`, and infrastructure appears. Underneath, it is **a graph engine**. Understanding that graph is the difference between safely evolving infrastructure and accidentally deleting production at 2 a.m.

This document explains **how Terraform thinks**, not just what commands to run.

---

## Dependency & Graph Control

Terraform is **declarative in syntax** but **procedural in execution**.

You do not tell Terraform *how* to create resources step by step. Instead, you describe **relationships**, and Terraform builds a **dependency graph** (a DAG) to decide:

* what can be created in parallel
* what must wait
* what must be destroyed first

If you misunderstand this graph, Terraform will still act confidently. It just won’t act correctly.

---

## Implicit vs Explicit Dependencies

### Implicit Dependencies (Preferred)

An **implicit dependency** is created when one resource **references an attribute** of another.

Example:

```hcl
resource "aws_iam_role" "lambda_role" {
  name = "lambda-role"
}

resource "aws_lambda_function" "etl" {
  role = aws_iam_role.lambda_role.arn
}
```

Terraform sees the reference and concludes:

> "I cannot create the Lambda until the IAM role exists."

You did not say this explicitly. Terraform inferred it.

**This is the ideal case.**

Why implicit dependencies are good:

* They are self-documenting
* They survive refactors
* They match Terraform’s mental model

If Terraform can infer a dependency, **let it**.

---

### Reference-Based Dependency Resolution

Terraform scans expressions and builds edges in the graph.

It treats these as dependencies:

* `resource.attribute`
* `module.output`
* `data.source.attribute`

It does **not** care about:

* file order
* folder order
* where the code lives

All `.tf` files in a module are merged into a single graph.

This is why “putting things at the top of the file” does nothing.

---

### Explicit Dependencies (`depends_on`)

`depends_on` forces Terraform to respect an ordering **even if no attribute reference exists**.

Example:

```hcl
resource "aws_lambda_function" "etl" {
  depends_on = [aws_iam_role_policy.lambda_policy]
}
```

Use this **only when**:

* The dependency is **real**
* Terraform cannot infer it

Legitimate use cases:

* IAM permissions that must exist before first use
* Side-effect resources (log groups, policies)
* Eventual-consistency problems in cloud APIs

Bad use cases:

* “Just to be safe”
* Masking a design flaw
* Controlling order emotionally

`depends_on` is a **manual override**. Treat it like one.

---

## Resource Graph & Ordering

### How Terraform Builds the DAG

Terraform creates a **Directed Acyclic Graph**:

* Nodes = resources, data sources, modules
* Edges = dependencies

Rules:

* No cycles allowed
* Independent nodes run in parallel
* Destruction follows the reverse graph

This is why Terraform can create 20 resources at once without you asking.

---

### Why Circular Dependencies Happen

Cycles usually come from **mutual knowledge**.

Example pattern:

* Resource A needs output from Resource B
* Resource B needs output from Resource A

Common real-world causes:

* Security groups referencing each other
* IAM roles and policies cross-wiring
* Modules leaking internal details

Terraform refuses to guess. It errors out.

---

### Breaking Cycles Cleanly

Correct strategies:

1. **Split responsibilities**

   * One resource owns creation
   * Another attaches or configures

2. **Use data sources**

   * Read instead of create

3. **Introduce a stable boundary**

   * Pre-create shared infrastructure

4. **Refactor modules**

   * Cycles often mean bad abstractions

Avoid hacks. If Terraform detects a cycle, it is telling you something is wrong.

---

## Lifecycle & Change Control

Terraform destroys infrastructure **by default** when definitions change.

This section is about stopping Terraform from doing something technically correct but operationally catastrophic.

---

## Resource Lifecycle Meta-Arguments

Lifecycle blocks modify how Terraform treats changes.

They are not defaults. They are **exceptions**.

---

### `create_before_destroy`

Without it:

* Old resource is destroyed
* New resource is created

With it:

* New resource is created first
* Old resource is destroyed after

```hcl
lifecycle {
  create_before_destroy = true
}
```

Use when:

* Downtime is unacceptable
* Resources support parallel existence

Risk:

* Temporary duplicates
* Quota exhaustion

---

### `prevent_destroy`

This blocks destruction entirely.

```hcl
lifecycle {
  prevent_destroy = true
}
```

Terraform will error instead of deleting.

Use for:

* Databases
* State buckets
* Critical prod resources

This forces **human intent** before irreversible actions.

---

### `ignore_changes`

Tells Terraform to ignore drift for specific attributes.

```hcl
lifecycle {
  ignore_changes = [tags]
}
```

Use when:

* Another system manages that field
* The value changes constantly

Danger:

* Terraform stops being the source of truth

Use narrowly. Document why.

---

## Safe Refactoring

Refactoring Terraform is not renaming files. It is **editing state relationships**.

---

### Renaming Resources Without Recreation

Naively renaming a resource tells Terraform:

> "Delete the old one and create a new one"

That is often unacceptable.

---

### `moved` Blocks

`moved` tells Terraform that a resource identity changed, not the resource itself.

```hcl
moved {
  from = aws_s3_bucket.old
  to   = aws_s3_bucket.new
}
```

This updates state **without touching infrastructure**.

This is the correct way to refactor names.

---

### State Move Patterns

Older or advanced workflows may require manual state movement:

```bash
terraform state mv old_address new_address
```

Use when:

* Splitting modules
* Merging modules
* Large structural refactors

Rules:

* Backup state first
* Never experiment in prod
* Understand the graph before moving

---

## Mental Model to Keep

* Terraform is a graph engine
* References create edges
* Lifecycle rules override defaults
* State is the source of truth

If you respect the graph, Terraform is boring.
If you fight it, Terraform is destructive.

That is not a coincidence.