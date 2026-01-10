module "eks" {

    # import the module template
    source = "terraform-aws-modules/eks/aws"
    version = "21.12.0"

    # cluster info (control plane)
    name = "my-eks-cluster" 
    kubernetes_version = "1.33"

    # cluster_addons = {
    #     vpc-cni = {
    #         most_recent = true
    #     }
    #     kube_proxy = {
    #         most_recent = true
    #     }
    #     core-dns = {
    #         most_recent = true
    #     }
    # }

    # Optional
    endpoint_public_access = true

    # Optional: Adds the current caller identity as an administrator via cluster access entry
    enable_cluster_creator_admin_permissions = true

    compute_config = {
        enabled    = true
        node_pools = ["general-purpose"]
    }

    vpc_id     = module.vpc.vpc_id 
    # subnet_ids = ["subnet-abcde012", "subnet-bcde012a", "subnet-fghi345a"]
    subnet_ids = module.vpc.private_subnets + module.vpc.public_subnets

    # control plane network
    control_plane_subnet_ids = module.vpc.intra_subnets
    
    # eks_managed_node_groups = ["t3.micro"]
    node_security_group_enable_recommended_rules = true

    # managing nodes in the cluster
    eks_managed_node_groups = {
        eks-cluster-ng = {
            # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
            ami_type       = "AL2023_x86_64_STANDARD"
            instance_types = ["t3.micro"]

            min_size     = 2
            max_size     = 3
            desired_size = 2
            capacity_type = "SPOT"
        }
    }

    # cluster_addons = {
    #     vpc-cni = {
    #         most_recent = true
    #     }
    #     kube_proxy = {
    #         most_recent = true
    #     }
    #     coredns = {
    #         most_recent = true
    #     }
    # }
    
    tags = {
        Environment = local.env
        Terraform   = "true"
    }
}