# PE Assignment 3: Multi-tier Architecture in the Cloud

## Introduction
This project implements a multi-tier architecture for a Flask CRUD application in AWS. The architecture consists of three tiers:
1. Front-end tier (public subnet): Application Load Balancer serving as a proxy
2. Middle tier (private subnet): ECS Fargate running the Flask application with Gunicorn WSGI server
3. Back-end tier (private subnet): RDS MySQL database

## Architecture Design

### Architecture Diagram
```
                                        Internet
                                           │
                                           ▼
                                     ┌──────────┐
                                     │   ALB    │
                                     │(Public   │
                                     │ Subnet)  │
                                     └────┬─────┘
                                          │
                                          ▼
┌───────────────┐                  ┌──────────┐
│ Bastion Host  │◄────────────────►│ECS Fargate│
│(Public Subnet)│                  │(Private   │
└───────┬───────┘                  │ Subnet)   │
        │                          └────┬──────┘
        │                               │
        │                               ▼
        │                          ┌──────────┐
        └─────────────────────────►│   RDS    │
                                   │(Private   │
                                   │ Subnet)   │
                                   └──────────┘
```

### Security Groups Configuration

| Security Group      | Purpose                          | Inbound Rules                                     | Outbound Rules     |
|---------------------|----------------------------------|---------------------------------------------------|-------------------|
| alb-sg              | Controls access to ALB           | HTTP (80) from 0.0.0.0/0, HTTPS (443) from 0.0.0.0/0 | All traffic       |
| ecs-sg              | Controls access to ECS containers | HTTP (8000) from alb-sg                           | All traffic       |
| db-sg               | Controls access to RDS           | MySQL (3306) from ecs-sg, MySQL (3306) from bastion-sg | All traffic       |
| bastion-sg          | Controls access to Bastion Host  | SSH (22) from your IP                              | All traffic       |

### Route Tables Configuration

| Route Table | Associated Subnets | Routes                                           |
|-------------|-------------------|--------------------------------------------------|
| Public RT   | Public Subnets    | Local VPC CIDR, 0.0.0.0/0 -> Internet Gateway    |
| Private RT  | Private Subnets   | Local VPC CIDR, 0.0.0.0/0 -> NAT Gateway         |

### IP Addressing

| Component            | CIDR Block / Address |
|----------------------|----------------------|
| VPC                  | 10.0.0.0/16          |
| Public Subnet 1      | 10.0.1.0/24          |
| Public Subnet 2      | 10.0.2.0/24          |
| Private Subnet 1     | 10.0.3.0/24          |
| Private Subnet 2     | 10.0.4.0/24          |

## Implementation Guide

### VPC Setup

#### AWS Management Console

1. **Create VPC:**
   - Go to VPC Dashboard > Click "Create VPC"
   - Name: flask-app-vpc
   - CIDR: 10.0.0.0/16
   - Enable DNS hostnames
   - Click "Create VPC"

2. **Create Subnets:**
   - Go to Subnets > Create Subnet
   - Create the following subnets in the VPC:
     - Name: flask-app-public1, AZ: us-east-1a, CIDR: 10.0.1.0/24
     - Name: flask-app-public2, AZ: us-east-1b, CIDR: 10.0.2.0/24
     - Name: flask-app-private1, AZ: us-east-1a, CIDR: 10.0.3.0/24
     - Name: flask-app-private2, AZ: us-east-1b, CIDR: 10.0.4.0/24

3. **Create Internet Gateway:**
   - Go to Internet Gateways > Create Internet Gateway
   - Name: flask-app-igw
   - Attach to flask-app-vpc

4. **Create NAT Gateway:**
   - Go to NAT Gateways > Create NAT Gateway
   - Subnet: flask-app-public1
   - Allocate Elastic IP
   - Click "Create NAT Gateway"

5. **Configure Route Tables:**
   - Create Public Route Table:
     - Name: flask-app-public-rt
     - Add route: 0.0.0.0/0 -> Internet Gateway
     - Associate with public subnets
   - Create Private Route Table:
     - Name: flask-app-private-rt
     - Add route: 0.0.0.0/0 -> NAT Gateway
     - Associate with private subnets

#### AWS CLI

```bash
# Create VPC
VPC_ID=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=flask-app-vpc}]' --query 'Vpc.VpcId' --output text)
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames

# Create Subnets
PUBLIC_SUBNET1_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.1.0/24 --availability-zone us-east-1a --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=flask-app-public1}]' --query 'Subnet.SubnetId' --output text)
PUBLIC_SUBNET2_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.2.0/24 --availability-zone us-east-1b --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=flask-app-public2}]' --query 'Subnet.SubnetId' --output text)
PRIVATE_SUBNET1_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.3.0/24 --availability-zone us-east-1a --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=flask-app-private1}]' --query 'Subnet.SubnetId' --output text)
PRIVATE_SUBNET2_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.4.0/24 --availability-zone us-east-1b --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=flask-app-private2}]' --query 'Subnet.SubnetId' --output text)

# Create Internet Gateway
IGW_ID=$(aws ec2 create-internet-gateway --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=flask-app-igw}]' --query 'InternetGateway.InternetGatewayId' --output text)
aws ec2 attach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID

# Create and configure public route table
PUBLIC_RT_ID=$(aws ec2 create-route-table --vpc-id $VPC_ID --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=flask-app-public-rt}]' --query 'RouteTable.RouteTableId' --output text)
aws ec2 create-route --route-table-id $PUBLIC_RT_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID
aws ec2 associate-route-table --route-table-id $PUBLIC_RT_ID --subnet-id $PUBLIC_SUBNET1_ID
aws ec2 associate-route-table --route-table-id $PUBLIC_RT_ID --subnet-id $PUBLIC_SUBNET2_ID

# Allocate Elastic IP for NAT Gateway
EIP_ALLOC_ID=$(aws ec2 allocate-address --domain vpc --query 'AllocationId' --output text)

# Create NAT Gateway
NAT_GW_ID=$(aws ec2 create-nat-gateway --subnet-id $PUBLIC_SUBNET1_ID --allocation-id $EIP_ALLOC_ID --tag-specifications 'ResourceType=natgateway,Tags=[{Key=Name,Value=flask-app-nat}]' --query 'NatGateway.NatGatewayId' --output text)

# Create and configure private route table
PRIVATE_RT_ID=$(aws ec2 create-route-table --vpc-id $VPC_ID --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=flask-app-private-rt}]' --query 'RouteTable.RouteTableId' --output text)
aws ec2 create-route --route-table-id $PRIVATE_RT_ID --destination-cidr-block 0.0.0.0/0 --nat-gateway-id $NAT_GW_ID
aws ec2 associate-route-table --route-table-id $PRIVATE_RT_ID --subnet-id $PRIVATE_SUBNET1_ID
aws ec2 associate-route-table --route-table-id $PRIVATE_RT_ID --subnet-id $PRIVATE_SUBNET2_ID
```

### Database Tier Setup

#### AWS Management Console

1. **Create Security Group for RDS:**
   - Go to Security Groups > Create Security Group
   - Name: flask-db-sg
   - VPC: flask-app-vpc
   - Inbound rules: 
     - MySQL (3306) from ECS Security Group
     - MySQL (3306) from Bastion Security Group (if using)
   - Click "Create"

2. **Create DB Subnet Group:**
   - Go to RDS > Subnet Groups > Create DB Subnet Group
   - Name: flask-db-subnet-group
   - VPC: flask-app-vpc
   - Add private subnets
   - Click "Create"

3. **Create RDS Instance:**
   - Go to RDS > Databases > Create database
   - Standard create
   - MySQL engine
   - Version: 8.0
   - Templates: Free tier
   - DB identifier: flask-crud-db
   - Credentials: Set a master username and password
   - Instance configuration: db.t2.micro
   - Storage: 20 GB
   - Connectivity: 
     - VPC: flask-app-vpc
     - Subnet group: flask-db-subnet-group
     - Public access: No
     - Security group: flask-db-sg
   - Additional configurations:
     - Initial database name: flaskcrud
   - Click "Create database"

#### AWS CLI

```bash
# Create Security Group for RDS
DB_SG_ID=$(aws ec2 create-security-group --group-name flask-db-sg --description "Security group for Flask app database" --vpc-id $VPC_ID --query 'GroupId' --output text)
aws ec2 create-tags --resources $DB_SG_ID --tags Key=Name,Value=flask-db-sg

# Create DB Subnet Group
aws rds create-db-subnet-group --db-subnet-group-name flask-db-subnet-group --db-subnet-group-description "Subnet group for Flask app database" --subnet-ids $PRIVATE_SUBNET1_ID $PRIVATE_SUBNET2_ID

# Create RDS Instance
aws rds create-db-instance \
    --db-instance-identifier flask-crud-db \
    --db-name flaskcrud \
    --engine mysql \
    --master-username admin \
    --master-user-password YourStrongPassword123! \
    --db-instance-class db.t2.micro \
    --allocated-storage 20 \
    --vpc-security-group-ids $DB_SG_ID \
    --db-subnet-group-name flask-db-subnet-group \
    --no-publicly-accessible
```

### Application Tier Setup

#### AWS Management Console

1. **Create ECS Security Group:**
   - Go to Security Groups > Create Security Group
   - Name: flask-ecs-sg
   - VPC: flask-app-vpc
   - Inbound rules: 
     - Custom TCP (8000) from ALB Security Group
   - Click "Create"

2. **Create ECR Repository:**
   - Go to ECR > Create repository
   - Name: flask-app
   - Click "Create repository"

3. **Build and Push Docker Image:**
   - Configure AWS CLI and Docker on your local machine
   - In the Flask app directory, update the config.py file for RDS connection
   - Build and push the image using commands provided by ECR

4. **Create ECS Cluster:**
   - Go to ECS > Clusters > Create Cluster
   - Cluster name: flask-app-cluster
   - Networking only
   - Click "Create"

5. **Create Task Definition:**
   - Go to ECS > Task Definitions > Create new Task Definition
   - Type: Fargate
   - Name: flask-app-task
   - Task role: None
   - Task execution role: Create new or use existing
   - Task memory: 0.5GB
   - Task CPU: 0.25 vCPU
   - Container definitions:
     - Name: flask-app
     - Image: [your-ecr-repo-uri]
     - Port mappings: 8000
   - Click "Create"

6. **Create ECS Service:**
   - Go to ECS > Clusters > flask-app-cluster > Create Service
   - Launch type: Fargate
   - Service name: flask-app-service
   - Task Definition: flask-app-task
   - Number of tasks: 2
   - Deployment type: Rolling update
   - VPC: flask-app-vpc
   - Subnets: Private subnets
   - Security group: flask-ecs-sg
   - Load balancer: Application Load Balancer
   - Click "Create Service"

#### AWS CLI

```bash
# Create ECS Security Group
ECS_SG_ID=$(aws ec2 create-security-group --group-name flask-ecs-sg --description "Security group for Flask app ECS tasks" --vpc-id $VPC_ID --query 'GroupId' --output text)
aws ec2 create-tags --resources $ECS_SG_ID --tags Key=Name,Value=flask-ecs-sg

# Create ECR Repository
aws ecr create-repository --repository-name flask-app

# Authenticate Docker to ECR
aws ecr get-login-password | docker login --username AWS --password-stdin $(aws sts get-caller-identity --query 'Account' --output text).dkr.ecr.$(aws configure get region).amazonaws.com

# Update app/config.py for RDS connection
# Change the host, port, username, password, and database based on your RDS setup

# Build and push Docker image
docker build -t flask-app .
docker tag flask-app:latest $(aws sts get-caller-identity --query 'Account' --output text).dkr.ecr.$(aws configure get region).amazonaws.com/flask-app:latest
docker push $(aws sts get-caller-identity --query 'Account' --output text).dkr.ecr.$(aws configure get region).amazonaws.com/flask-app:latest

# Create ECS Cluster
aws ecs create-cluster --cluster-name flask-app-cluster

# Create Task Definition
aws ecs register-task-definition \
    --family flask-app-task \
    --network-mode awsvpc \
    --requires-compatibilities FARGATE \
    --cpu 256 \
    --memory 512 \
    --execution-role-arn arn:aws:iam::$(aws sts get-caller-identity --query 'Account' --output text):role/ecsTaskExecutionRole \
    --container-definitions "[{\"name\":\"flask-app\",\"image\":\"$(aws sts get-caller-identity --query 'Account' --output text).dkr.ecr.$(aws configure get region).amazonaws.com/flask-app:latest\",\"essential\":true,\"portMappings\":[{\"containerPort\":8000,\"hostPort\":8000,\"protocol\":\"tcp\"}],\"logConfiguration\":{\"logDriver\":\"awslogs\",\"options\":{\"awslogs-group\":\"/ecs/flask-app\",\"awslogs-region\":\"$(aws configure get region)\",\"awslogs-stream-prefix\":\"ecs\"}}}]"

# Create CloudWatch Logs Group
aws logs create-log-group --log-group-name /ecs/flask-app
```

### Front-end Tier Setup

#### AWS Management Console

1. **Create ALB Security Group:**
   - Go to Security Groups > Create Security Group
   - Name: flask-alb-sg
   - VPC: flask-app-vpc
   - Inbound rules: 
     - HTTP (80) from 0.0.0.0/0
     - HTTPS (443) from 0.0.0.0/0
   - Click "Create"

2. **Create Application Load Balancer:**
   - Go to EC2 > Load Balancers > Create Load Balancer
   - Select Application Load Balancer
   - Name: flask-app-alb
   - Schema: Internet-facing
   - Listeners: HTTP (80), HTTPS (443)
   - VPC: flask-app-vpc
   - Subnets: Select public subnets
   - Security group: flask-alb-sg
   - Target group:
     - Name: flask-app-tg
     - Target type: IP
     - Protocol: HTTP
     - Port: 8000
     - Health check: HTTP path /
   - Register targets: Skip (ECS service will register targets)
   - Click "Create"

3. **Create and Configure HTTPS (Optional):**
   - Request a certificate in ACM
   - Configure HTTPS listener on ALB
   - Add redirect from HTTP to HTTPS

#### AWS CLI

```bash
# Create ALB Security Group
ALB_SG_ID=$(aws ec2 create-security-group --group-name flask-alb-sg --description "Security group for Flask app ALB" --vpc-id $VPC_ID --query 'GroupId' --output text)
aws ec2 create-tags --resources $ALB_SG_ID --tags Key=Name,Value=flask-alb-sg
aws ec2 authorize-security-group-ingress --group-id $ALB_SG_ID --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $ALB_SG_ID --protocol tcp --port 443 --cidr 0.0.0.0/0

# Update security group rules
aws ec2 authorize-security-group-ingress --group-id $ECS_SG_ID --protocol tcp --port 8000 --source-group $ALB_SG_ID
aws ec2 authorize-security-group-ingress --group-id $DB_SG_ID --protocol tcp --port 3306 --source-group $ECS_SG_ID

# Create target group
TG_ARN=$(aws elbv2 create-target-group \
    --name flask-app-tg \
    --protocol HTTP \
    --port 8000 \
    --vpc-id $VPC_ID \
    --target-type ip \
    --health-check-path "/" \
    --health-check-interval-seconds 30 \
    --health-check-timeout-seconds 5 \
    --healthy-threshold-count 2 \
    --unhealthy-threshold-count 2 \
    --query 'TargetGroups[0].TargetGroupArn' \
    --output text)

# Create load balancer
ALB_ARN=$(aws elbv2 create-load-balancer \
    --name flask-app-alb \
    --subnets $PUBLIC_SUBNET1_ID $PUBLIC_SUBNET2_ID \
    --security-groups $ALB_SG_ID \
    --scheme internet-facing \
    --query 'LoadBalancers[0].LoadBalancerArn' \
    --output text)

# Create HTTP listener
HTTP_LISTENER_ARN=$(aws elbv2 create-listener \
    --load-balancer-arn $ALB_ARN \
    --protocol HTTP \
    --port 80 \
    --default-actions Type=forward,TargetGroupArn=$TG_ARN \
    --query 'Listeners[0].ListenerArn' \
    --output text)

# Create ECS service with load balancer
aws ecs create-service \
    --cluster flask-app-cluster \
    --service-name flask-app-service \
    --task-definition flask-app-task \
    --desired-count 2 \
    --launch-type FARGATE \
    --network-configuration "awsvpcConfiguration={subnets=[$PRIVATE_SUBNET1_ID,$PRIVATE_SUBNET2_ID],securityGroups=[$ECS_SG_ID],assignPublicIp=DISABLED}" \
    --load-balancers "targetGroupArn=$TG_ARN,containerName=flask-app,containerPort=8000"
```

### Bastion Host Setup (Optional)

#### AWS Management Console

1. **Create Bastion Security Group:**
   - Go to Security Groups > Create Security Group
   - Name: flask-bastion-sg
   - VPC: flask-app-vpc
   - Inbound rules: 
     - SSH (22) from Your IP
   - Click "Create"

2. **Create EC2 Key Pair:**
   - Go to EC2 > Key Pairs > Create Key Pair
   - Name: bastion-key
   - File format: .pem
   - Download and save the key file securely

3. **Launch EC2 Instance:**
   - Go to EC2 > Instances > Launch Instances
   - Name: flask-app-bastion
   - AMI: Amazon Linux 2
   - Instance type: t2.micro
   - Key pair: bastion-key
   - VPC: flask-app-vpc
   - Subnet: Public subnet
   - Auto-assign public IP: Enable
   - Security group: flask-bastion-sg
   - Click "Launch instance"

#### AWS CLI

```bash
# Create Bastion Security Group
BASTION_SG_ID=$(aws ec2 create-security-group --group-name flask-bastion-sg --description "Security group for bastion host" --vpc-id $VPC_ID --query 'GroupId' --output text)
aws ec2 create-tags --resources $BASTION_SG_ID --tags Key=Name,Value=flask-bastion-sg
aws ec2 authorize-security-group-ingress --group-id $BASTION_SG_ID --protocol tcp --port 22 --cidr $(curl -s ifconfig.me)/32

# Update DB security group to allow access from bastion
aws ec2 authorize-security-group-ingress --group-id $DB_SG_ID --protocol tcp --port 3306 --source-group $BASTION_SG_ID

# Create key pair
aws ec2 create-key-pair --key-name bastion-key --query 'KeyMaterial' --output text > bastion-key.pem
chmod 400 bastion-key.pem

# Get latest Amazon Linux 2 AMI ID
AMI_ID=$(aws ec2 describe-images --owners amazon --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" "Name=state,Values=available" --query "sort_by(Images, &CreationDate)[-1].ImageId" --output text)

# Launch EC2 instance
INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --count 1 \
    --instance-type t2.micro \
    --key-name bastion-key \
    --security-group-ids $BASTION_SG_ID \
    --subnet-id $PUBLIC_SUBNET1_ID \
    --associate-public-ip-address \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=flask-app-bastion}]' \
    --query 'Instances[0].InstanceId' \
    --output text)
```

### HTTPS Configuration (Optional)

#### AWS Management Console

1. **Request SSL Certificate:**
   - Go to ACM > Request a certificate
   - Request a public certificate
   - Add domain name(s)
   - Choose DNS validation or email validation
   - Complete validation process

2. **Configure HTTPS on ALB:**
   - Go to EC2 > Load Balancers > flask-app-alb
   - Click on "Listeners" tab > Add listener
   - Protocol: HTTPS
   - Port: 443
   - Default actions: Forward to flask-app-tg
   - Select your certificate
   - Security policy: Recommended policy
   - Click "Add"

3. **Configure HTTP to HTTPS Redirect:**
   - Go to EC2 > Load Balancers > flask-app-alb
   - Click on "Listeners" tab > Edit the HTTP:80 listener
   - Default actions: Redirect to HTTPS:443
   - Click "Update"

#### AWS CLI

```bash
# Request a certificate
CERT_ARN=$(aws acm request-certificate \
    --domain-name your-domain.com \
    --validation-method DNS \
    --query 'CertificateArn' \
    --output text)

# Wait for certificate validation

# Create HTTPS listener
aws elbv2 create-listener \
    --load-balancer-arn $ALB_ARN \
    --protocol HTTPS \
    --port 443 \
    --certificates CertificateArn=$CERT_ARN \
    --ssl-policy ELBSecurityPolicy-2016-08 \
    --default-actions Type=forward,TargetGroupArn=$TG_ARN

# Modify HTTP listener to redirect to HTTPS
aws elbv2 modify-listener \
    --listener-arn $HTTP_LISTENER_ARN \
    --port 80 \
    --protocol HTTP \
    --default-actions "Type=redirect,RedirectConfig={Protocol=HTTPS,Port=443,Host='#{host}',Path='/#{path}',Query='#{query}',StatusCode=HTTP_301}"
```

## Connecting to Database (for Administration)

To connect to the RDS database from the bastion host:

```bash
# Connect to bastion host
ssh -i bastion-key.pem ec2-user@<BASTION_PUBLIC_IP>

# Install MySQL client
sudo yum install mysql -y

# Connect to RDS
mysql -h <RDS_ENDPOINT> -u admin -p
``` 