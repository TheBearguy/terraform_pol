# What is Terraform?

- Terraform automates the manual processes of provisioning a cloud resource
- Its cloud agnostic
- It shines when there’s multiple cloud instances / servers to be created / managed
- It helps in connecting different cloud services through references
- Its easier than cloudformation or ansible coz this is type of an iterative development. there’s plan stage and then apply stage so it tells us clearly whats gonna happen if we apply the current config that we’ve written in code.
- The entire processing logic (the understanding of the terraform .tf code written by the developer, the environment management, parsing the code into actual actionables) all of it is handled by terraform.

The real problem that Terraform solves: 

**Terraform solves **state**, **drift**, and **intent**.**

Scripts: 

- execute instructions
- forget what they did
- cannot reason about the system as a whole

Terraform: 

- remembers what exists
- compares desired vs actual states
- converges reality to intent


# What problem does Terraform solve that scripts cannot?

- Scripts are imperative.
Terraform is declarative. 
You define what should exist. Not how to create it
- Terraform maintains state. 
It knows what resources already exists and what change. Scripts do not
- Terraform detects drifts. 
If someone changes infra manually. Terraform can detect and correct it.
- Terraform safely plans changes before applying them.
Scripts execute blilndly. Terraform previews consequences.
- Terraform composes infrastructure.
Resources reference each other as graphs. Not as brittle step sequences.
- Terraform enables reproducibility.
The same config can recreate identical infrastructure anytime.

>Terraform focuses on infrastructure lifecycle, not configuration management
>
Ansible is config management.