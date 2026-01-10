Below is a **ground-up, mechanical explanation** of Terraform modules, then a **non-trivial example** that reflects how modules are actually used in real systems. No workspaces.

---

## 1. What a Terraform module really is

A **module is just a directory** containing Terraform files.

Nothing more.

Terraform has exactly **one special module**:

* the **root module** → the directory where you run `terraform apply`

Every other module is just a **child module**.

---

## 2. Why modules exist (the real reason)

Modules exist to solve **four concrete problems**:

1. **Reuse**
   Same infrastructure pattern used many times

2. **Isolation**
   Clear ownership boundaries (blast radius control)

3. **Abstraction**
   Hide low-level resources behind a clean interface

4. **Graph control**
   Force correct dependency ordering across large systems

Modules are **not** for “clean code” or “organization”.
They are for **state and dependency control**.

---

## 3. What a module contains

A module usually has:

```text
main.tf      → resources
variables.tf → inputs
outputs.tf   → outputs
```

This is convention, not a rule.

Terraform loads **all `.tf` files** in a directory as one unit.

---

## 4. How modules actually work

Think of a module as a **pure function**:

```text
inputs  → infrastructure → outputs
```

### Inputs

* Variables passed from the parent
* Read-only inside the module

### Outputs

* Values explicitly exported
* Used by parent or other modules

### Isolation rule (critical)

A module:

* Cannot see parent resources directly
* Cannot access sibling modules
* Only sees:

  * Its inputs
  * Its own resources
  * Its outputs

This is intentional and strict.

---

## 5. Module call syntax

From the root module:

```hcl
module "vpc" {
  source = "./modules/vpc"

  cidr_block = "10.0.0.0/16"
}
```

This does **not** “import code”.
It instantiates **another graph** inside the root graph.

Each module call is a **namespaced instance**.

---

## 6. How state is stored for modules

Important internal detail.

In `.tfstate`:

```json
module.vpc.aws_vpc.this
module.vpc.aws_subnet.public[0]
```

Modules do **not** have separate state files.

* One state file
* One graph
* Namespaced addresses

Modules are **logical boundaries**, not state boundaries.

---

## 7. When you should create a module

Create a module when:

* A pattern repeats ≥ 2 times
* A resource group must be owned by one team
* You want to prevent accidental coupling
* You want stable inputs and outputs

Do **not** create modules for:

* Single resources
* Early prototypes
* One-off experiments

---

## 8. Intermediate–complex example

We will build:

* A reusable **VPC module**
* A reusable **EC2 application module**
* A root module that wires them together

No workspaces. One environment.

---

## 9. Directory structure

```text
infra/
 ├── main.tf
 ├── variables.tf
 ├── outputs.tf
 │
 └── modules/
      ├── vpc/
      │    ├── main.tf
      │    ├── variables.tf
      │    └── outputs.tf
      │
      └── app/
           ├── main.tf
           ├── variables.tf
           └── outputs.tf
```

---

## 10. VPC module (infrastructure foundation)

### `modules/vpc/variables.tf`

```hcl
variable "cidr_block" {
  type = string
}

variable "public_subnets" {
  type = list(string)
}

variable "private_subnets" {
  type = list(string)
}
```

---

### `modules/vpc/main.tf`

```hcl
resource "aws_vpc" "this" {
  cidr_block = var.cidr_block
}

resource "aws_subnet" "public" {
  count             = length(var.public_subnets)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.public_subnets[count.index]
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private" {
  count      = length(var.private_subnets)
  vpc_id     = aws_vpc.this.id
  cidr_block = var.private_subnets[count.index]
}
```

---

### `modules/vpc/outputs.tf`

```hcl
output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}
```

This module:

* Owns the entire network
* Exposes only what consumers need
* Prevents direct manipulation

---

## 11. App module (consumer)

### `modules/app/variables.tf`

```hcl
variable "subnet_id" {
  type = string
}

variable "instance_count" {
  type = number
}

variable "ami" {
  type = string
}

variable "instance_type" {
  type = string
}
```

---

### `modules/app/main.tf`

```hcl
resource "aws_instance" "app" {
  count         = var.instance_count
  ami           = var.ami
  instance_type = var.instance_type
  subnet_id     = var.subnet_id
}
```

---

### `modules/app/outputs.tf`

```hcl
output "instance_ids" {
  value = aws_instance.app[*].id
}
```

---

## 12. Root module wiring

### `main.tf`

```hcl
module "vpc" {
  source = "./modules/vpc"

  cidr_block = "10.0.0.0/16"

  public_subnets  = ["10.0.1.0/24"]
  private_subnets = ["10.0.2.0/24"]
}

module "app" {
  source = "./modules/app"

  subnet_id     = module.vpc.private_subnet_ids[0]
  instance_count = 2
  ami            = "ami-0abcdef"
  instance_type  = "t3.micro"
}
```

---

## 13. Dependency graph (important)

Terraform infers:

```text
module.vpc → module.app
```

Why?

Because:

```hcl
module.app.subnet_id = module.vpc.private_subnet_ids[0]
```

No `depends_on` needed.

Modules create **explicit, safe ordering**.

---

## 14. Why this is “intermediate-complex”

This example includes:

* Multiple modules
* Module-to-module wiring
* Output consumption
* Namespaced state
* Reusable patterns
* No global coupling

This is how **real Terraform codebases** are structured.

---

## 15. Final mental model

* Module = directory
* Module call = graph instantiation
* Inputs = contract
* Outputs = contract
* State = shared, namespaced
* Isolation = enforced by design

Once you understand modules this way, Terraform becomes scalable instead of fragile.