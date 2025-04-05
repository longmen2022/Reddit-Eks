# Define IAM Policy Document for Assume Role
data "aws_iam_policy_document" "assume_role" {
  # Define a policy statement to allow EKS service to assume a role
  statement {
    effect = "Allow"

    # Specify the service principal (EKS) that can assume the role
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }

    # Grant the permission to assume the role
    actions = ["sts:AssumeRole"]
  }
}

# Define IAM Role for EKS Cluster
resource "aws_iam_role" "eks_cluster_role" {
  # Name of the IAM role for the EKS cluster
  name               = "eks-cluster-cloud-2"
  
  # Attach the assume role policy to the IAM role
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# Attach EKS Cluster Policy to IAM Role
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  # Attach the pre-defined AmazonEKSClusterPolicy to the IAM role
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

# Retrieve Default VPC
data "aws_vpc" "default" {
  # Use the default VPC in the AWS account
  default = true
}

# Create a Public Subnet with Auto-Assign Public IPs
resource "aws_subnet" "public" {
  vpc_id                  = data.aws_vpc.default.id
  cidr_block              = "172.31.2.0/24" # Valid CIDR block within the VPC range
  map_public_ip_on_launch = true            # Enable auto-assign public IPs
  availability_zone       = "us-east-1a"    # Adjust to your desired region
  tags = {
    Name = "Public Subnet with Public IPs"
  }
}

# Create an additional public subnet in another AZ
resource "aws_subnet" "public_2" {
  vpc_id                  = data.aws_vpc.default.id
  cidr_block              = "172.31.11.0/24" # Adjust this CIDR block to avoid conflicts
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1b" # Different AZ from the first subnet
  tags = {
    Name = "Public Subnet 2 with Public IPs"
  }
}


resource "aws_eks_cluster" "eks_cluster" {
  name     = "EKS_CLOUD"
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids = [
      aws_subnet.public.id,
      aws_subnet.public_2.id
    ] # Subnets in at least two different AZs
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
  ]
}


# Define IAM Role for Node Group
resource "aws_iam_role" "eks_node_group_role" {
  # Name of the IAM role for the node group
  name = "eks-node-group-cloud-2"

  # Attach an assume role policy to the IAM role
  assume_role_policy = jsonencode({
    Statement = [
      {
        # Allow EC2 service to assume the role
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
    # Specify the policy version
    Version = "2012-10-17"
  })
}

# Attach Required Policies for Node Group Role
resource "aws_iam_role_policy_attachment" "eks_worker_policy" {
  # Attach AmazonEKSWorkerNodePolicy to the node group IAM role
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  # Attach AmazonEKS_CNI_Policy to allow CNI plugin operations
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "ecr_readonly_policy" {
  # Attach AmazonEC2ContainerRegistryReadOnly for pulling container images
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_group_role.name
}

# Create Node Group
resource "aws_eks_node_group" "eks_node_group" {
  # Name of the associated EKS cluster
  cluster_name    = aws_eks_cluster.eks_cluster.name
  
  # Name of the node group
  node_group_name = "Node-cloud"
  
  # IAM role for the node group
  node_role_arn   = aws_iam_role.eks_node_group_role.arn

  # Specify the subnet for the node group (public subnet for public IPs)
  subnet_ids      = [aws_subnet.public.id]

  # Define the scaling configuration for the node group
  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  # Specify the instance type for the worker nodes
  instance_types = ["t2.medium"]

  # Ensure IAM policies are attached before creating the node group
  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.ecr_readonly_policy,
  ]
}
