# VPC module
# KMS module
# Kubernetes components - https://kubernetes.io/docs/concepts/overview/components/#:~:text=kube%2Dproxy%20is%20a%20network,or%20outside%20of%20your%20cluster.
# Add-ons
# coredns - https://docs.aws.amazon.com/eks/latest/userguide/managing-coredns.html
# vpc-cni - https://docs.amazonaws.cn/en_us/eks/latest/userguide/cni-iam-role.html
# Node Groups & Fargate configuration 
# Taints and tolerations are a mechanism that allows you to ensure that pods are not placed on inappropriate nodes. Taints are added to nodes, while tolerations are defined in the pod specification
# For example, most Kubernetes distributions will automatically taint the master nodes so that one of the pods that manages the control plane is scheduled onto them and not any other data plane pods deployed by users
# kubectl taint nodes nodename activeEnv=green:NoSchedule
# tolerations:
# - effect: NoSchedule
#   key: activeEnv
#   operator: Equal
#   value: green
# Update kubeconfig to connect to the EKS cluster
# aws eks update-kubeconfig --name masterclass-cluster --region eu-west-2 --kubeconfig ~/.kube/config --profile masterclass
# kubectl config get-contexts 
# kubectl config use-context arn:aws:eks:eu-west-2:832611670348:cluster/masterclass-cluster

############# Provider & Backend #############
########################################

# provider "aws" {
#   region = "eu-west-2"
# }

# terraform {
#   backend "local" {}
# }

# ############# Data Sources #############
# ########################################
# data "aws_eks_cluster" "default" {
#   name = module.eks.cluster_id
# }

# data "aws_eks_cluster_auth" "default" {
#   name = module.eks.cluster_id
# }

# provider "kubernetes" {
#   host                   = data.aws_eks_cluster.default.endpoint
#   cluster_ca_certificate = base64decode(data.aws_eks_cluster.default.certificate_authority[0].data)
#   token                  = data.aws_eks_cluster_auth.default.token
# }


# ############# EKS #############
# ########################################
# module "eks" {
#   source  = "terraform-aws-modules/eks/aws"
#   version = "~> 18.0"

#   cluster_name    = "masterclass-cluster"
#   cluster_version = "1.23"

#   cluster_endpoint_private_access = true
#   cluster_endpoint_public_access  = true

#   cluster_addons = {
#     coredns = {
#       resolve_conflicts = "OVERWRITE"
#     }
#     kube-proxy = {}
#     vpc-cni = {
#       resolve_conflicts = "OVERWRITE"
#     }
#   }

#   cluster_encryption_config = [{
#     provider_key_arn = "arn:aws:kms:eu-west-2:832611670348:key/1e5a5535-777f-4f25-989c-81d04c57c4c3"
#     resources        = ["secrets"]
#   }]

#   #TODO Use data source or interpolate from another module
#   vpc_id     = "vpc-0dd40889ba71c24b6"
#   subnet_ids = ["subnet-0e69cb88d1ebd8ec6", "subnet-00ed099af8ab68db1"]

#   # Self Managed Node Group(s)
#   self_managed_node_group_defaults = {
#     instance_type                          = "m6i.large"
#     update_launch_template_default_version = true
#     iam_role_additional_policies = [
#       "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
#     ]
#   }

#   self_managed_node_groups = {
#     one = {
#       name         = "mixed-1"
#       max_size     = 5
#       desired_size = 2

#       use_mixed_instances_policy = true
#       mixed_instances_policy = {
#         instances_distribution = {
#           on_demand_base_capacity                  = 0
#           on_demand_percentage_above_base_capacity = 10
#           spot_allocation_strategy                 = "capacity-optimized"
#         }

#         override = [
#           {
#             instance_type     = "m5.large"
#             weighted_capacity = "1"
#           },
#           {
#             instance_type     = "m6i.large"
#             weighted_capacity = "2"
#           },
#         ]
#       }
#     }
#   }

#   # EKS Managed Node Group(s)
#   eks_managed_node_group_defaults = {
#     disk_size      = 50
#     instance_types = ["t3.large", "m5.large"]
#   }

#   eks_managed_node_groups = {
#     blue = {}
#     green = {
#       min_size     = 1
#       max_size     = 10
#       desired_size = 1

#       instance_types = ["t3.large"]
#       capacity_type  = "SPOT"
#     }
#   }

#   # Fargate Profile(s)
#   fargate_profiles = {
#     default = {
#       name = "default"
#       selectors = [
#         {
#           namespace = "default"
#         }
#       ]
#     }
#   }

#   # aws-auth configmap
#   manage_aws_auth_configmap = true
# #   create_aws_auth_configmap = true

#   aws_auth_roles = [
#     {
#       rolearn  = "arn:aws:iam::832611670348:role/AllowLambdaAndS3"
#       username = "LambdaToS3"
#       groups   = ["system:masters"]
#     },
#   ]

#   aws_auth_users = [
#     {
#       userarn  = "arn:aws:iam::832611670348:user/masterclass"
#       username = "masterclass"
#       groups   = ["system:masters"]
#     },
#   ]

#   #   aws_auth_accounts = [
#   #     "777777777777",
#   #     "888888888888",
#   #   ]

#   tags = {
#     Environment = "dev"
#     Terraform   = "true"
#   }
# }








//////////////////////////////////////////////////////////
/////////////////////////////////////////////////////

provider "aws" {
  region = "eu-east-2"
}

locals {
  cluster_name = "EKS-Cluster"
}

data "aws_availability_zones" "azs" {
  state = "available"
}


################# VPC MODULES #################
##############################################            

module "vpc" {
  source              = "terraform-aws-modules/vpc/aws"
  version             = "3.2.0"
  name                = "Demo-VPC"
  cidr                = "10.0.0.0/16"
  azs                 = data.aws_availability_zones.available.names
  private_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets      = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  enable_nat_gateway  = true
  single_nat_gateway  = true
  enable_dns_hostname = true
  tags = {
    "Name" = "Demo-VPC"
  }
  public_subnet_tags = {
    "Name" = "Demo-Public-Subnet"
  }
  private_subnet_tags = {
    "Name" = "Demo-Private-Subnet"
  }
}

################# SECURITY GROUPS ####################
######################################################

resource "aws_security_group" "worker_group_mgmt_one" {
  name_prefix = "worker_group_mgmt_one"
  vpc_id      = module.vpc.vpc_id
  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = [
      "10.0.0.0/8"
    ]
  }
}
resource "aws_security_group" "worker_group_mgmt_two" {
  name_prefix = "worker_group_mgmt_two"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = [
      "10.0.0.0/8"
    ]
  }
}
resource "aws_security_group" "all_worker_mgmt" {
  name_prefix = "all_worker_management"
  vpc_id      = module.vpc.vpc_id
  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = [
      "10.0.0.0/8"
    ]
  }
}

############# Data Sources #############
########################################
data "aws_eks_cluster" "default" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "default" {
  name = module.eks.cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.default.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.default.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.default.token
}

################ OUTPUT #################
############################################


output "cluster_id" {
  value = module.eks.cluster_id
}
output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}


################# EKS #################
#######################################

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "17.1.0"
  cluster_name    = local.cluster_name
  cluster_version = "1.20"
  subnets         = module.vpc.private_subnets
  tags = {
    Name = "Demo-EKS-Cluster"
  }
  vpc_id = module.vpc.vpc_id
  workers_group_defaults = {
    root_volume_type = "gp2"
  }
  worker_group = [
    {
      name                          = "Worker-Group-1"
      instance_type                 = "t2.micro"
      asg_desired_capacity          = 2
      additional_security_group_ids = [aws_security_group.worker_group_mgmt_one.id]
    },
    {
      name                          = "Worker-Group-2"
      instance_type                 = "t2.micro"
      asg_desired_capacity          = 1
      additional_security_group_ids = [aws_security_group.worker_group_mgmt_two.id]
    },
  ]
}


