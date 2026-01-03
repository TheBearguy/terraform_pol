**`terraform plan` does not make variables global.**
They are global **before** planning even starts.

Terraform does not have “file-local scope” the way programming languages do.

---

### The real rule (the one that matters)

**All `.tf` files in the same directory are loaded together into a single module.**

Terraform first builds a **configuration graph**, *then* evaluates variables, *then* plans.

File boundaries are ignored.

---

### What actually happens (in order)

1. Terraform loads **every `.tf` file in the directory**

   * `variables.tf`
   * `ec2.tf`
   * `vpc.tf`
   * `outputs.tf`

2. It merges them into **one configuration namespace** (the root module).

3. All:

   * `variable` blocks
   * `resource` blocks
   * `locals`
   * `outputs`
     coexist in that module.

4. Only after this merge does Terraform evaluate:

   * variable values
   * expressions
   * dependency graph

`terraform plan` merely **prints** the result of that evaluation.
It does not create scope.

---

### Why your variable is visible everywhere

When you write:

```hcl
# variables.tf
variable "instance_type" {}
```

and elsewhere:

```hcl
# ec2.tf
resource "aws_instance" "x" {
  instance_type = var.instance_type
}
```

This works because:

* Both files are part of the **same module**
* `var.instance_type` is resolved from the module’s variable set
* Terraform never cared which file it came from

---

### Important contrast: modules

Variables are **not global across modules**.

If you do this:

```hcl
module "app" {
  source = "./app"
}
```

Then inside `./app`:

* Variables must be **declared again**
* Values must be **passed explicitly**

No implicit leakage.

That’s the real boundary.

---

### What *is* file scope used for?

Almost nothing.

Files are for:

* Human organization
* Git diffs
* Sanity

Terraform treats them as a **bag of declarations**.

---

### One-sentence truth anchor

**Terraform variables are module-scoped, not file-scoped; all `.tf` files in a directory are loaded together before planning ever begins.**

Once you internalize “directory = module”, Terraform stops feeling magical.



# Merits and Demerits of this context management: 

Demerits
1. Implicit coupling everywhere

Because everything shares one namespace:

Any resource can reference any other resource

There are no enforced boundaries

This leads to:

Accidental dependencies

Hidden coupling

Refactors becoming dangerous

You lose architectural discipline over time.

3. No reuse

You cannot:

Reuse VPC logic

Reuse EC2 patterns

Share infra across environments cleanly

Copy-paste becomes the reuse mechanism.
That scales poorly and rots silently.

4. Poor team scalability

For multiple engineers:

Everyone edits the same state

Everyone touches the same namespace

Merge conflicts become structural, not incidental

This is where Terraform pain stories begin.

5. Environment explosion

Handling:

dev

staging

prod

in a single flat module usually degenerates into:

Massive count / for_each conditionals

Boolean flags everywhere

Hard-to-reason plans

At that point, the module has exceeded its design envelope.

## MERITS: 
3. Fewer Terraform failure modes

Modules introduce:

Versioning problems

Interface drift

Input/output mismatches

Over-abstraction

A flat module avoids all of that.

Terraform is already declarative; adding abstraction too early compounds confusion.

1. Zero abstraction overhead

Everything is visible.
No indirection, no module interfaces, no variable plumbing.

This is excellent when:

You are learning Terraform

You are exploring an architecture

The system is small and evolving fast

Cognitive load stays low because:

var.x is defined somewhere nearby

Resource relationships are obvious