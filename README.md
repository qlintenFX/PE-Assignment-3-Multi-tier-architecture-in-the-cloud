# PE Assignment 3: Multi-tier Architecture in the Cloud

## Introduction
This project implements a scalable and secure multi-tier architecture for a Flask CRUD application in AWS. The implementation features three distinct tiers that ensure separation of concerns, improved security, and high availability.

## Architecture Design

### Architecture Diagram
![Multi-tier Architecture Diagram](diagramOpdracht3.png)

### Security Groups Configuration

| Security Group | Purpose | Inbound Rules | Outbound Rules |
|----------------|---------|---------------|----------------|
| flask-alb-sg | Controls access to ALB | HTTP (80) from 0.0.0.0/0, HTTPS (443) from 0.0.0.0/0 | All traffic |
| flask-ecs-sg | Controls access to ECS containers | HTTP (8000) from flask-alb-sg | All traffic |
| flask-db-sg | Controls access to RDS | MySQL (3306) from flask-ecs-sg, MySQL (3306) from flask-bastion-sg | All traffic |
| flask-bastion-sg | Controls access to Bastion Host | SSH (22) from my IP | All traffic |

### Route Tables Configuration

| Route Table | Associated Subnets | Routes |
|-------------|-------------------|--------|
| flask-public-rtb (rtb-0518fa459a4c60e8e) | Public Subnets (10.0.1.0/24, 10.0.2.0/24) | Local VPC CIDR, 0.0.0.0/0 → Internet Gateway |
| flask-rtb-1 (rtb-00a0e06aa7eb862d7) | Private App Subnets (10.0.3.0/24, 10.0.4.0/24) | Local VPC CIDR, 0.0.0.0/0 → NAT Gateway |
| flask-db-rt-1 (rtb-08604774e031a077a) | Database Subnets (10.0.5.0/24, 10.0.6.0/24) | Local VPC CIDR |

### IP Addressing

| Component | CIDR Block / Address |
|-----------|----------------------|
| VPC | 10.0.0.0/16 |
| Public Subnet 1 (us-east-1a) | 10.0.1.0/24 |
| Public Subnet 2 (us-east-1b) | 10.0.2.0/24 |
| Private App Subnet 1 (us-east-1a) | 10.0.3.0/24 |
| Private App Subnet 2 (us-east-1b) | 10.0.4.0/24 |
| Database Subnet 1 (us-east-1a) | 10.0.5.0/24 |
| Database Subnet 2 (us-east-1b) | 10.0.6.0/24 |
| Bastion Host | 98.83.119.96 |
| NAT Gateway | 52.7.199.129 |
| RDS Endpoint | flask-crud-db.czyocqcwwzna.us-east-1.rds.amazonaws.com |
| Load Balancer DNS | flask-app-alb-1035767056.us-east-1.elb.amazonaws.com |

## Technology Choices

### Front-end Tier: Application Load Balancer
- **Why**: ALB provides layer 7 routing, native HTTPS support, and health checks to ensure high availability. It can distribute traffic across multiple availability zones for better reliability.
- **Access**: The application is accessible via `https://flask-app-alb-1035767056.us-east-1.elb.amazonaws.com`

### Middle Tier: ECS Fargate with Gunicorn
- **Why**: Fargate eliminates server management for containers, allowing easy scaling and improved security. Gunicorn was chosen as the WSGI server as it's production-ready, supports multiple worker processes, and has good performance characteristics.
- **Changes**: Modified the Flask app's config.py to connect to the RDS database and added ProxyFix middleware to handle forwarded requests correctly.

### Back-end Tier: RDS MySQL
- **Why**: RDS provides automated backups, patches, and multi-AZ deployment options. MySQL was chosen for its compatibility with the Flask app's existing code and its performance for CRUD operations.
- **Access**: The database is only accessible from the ECS service or through the bastion host.

### Additional Features
- **HTTPS**: Implemented with an ACM certificate and HTTP to HTTPS redirection for secure data transmission.
- **Multi-AZ Database Replication**: Implemented database replication across multiple availability zones for improved reliability and fault tolerance.
- **Bastion Host**: Provides secure SSH access to the private subnets for administration purposes.

## Accessing the Application

The deployed application is accessible at:
- HTTPS: `https://flask-app-alb-1035767056.us-east-1.elb.amazonaws.com`
- HTTP: `http://flask-app-alb-1035767056.us-east-1.elb.amazonaws.com` (redirects to HTTPS)

I will demonstrate the working application during the evaluation.

## Database Access via Bastion Host

For secure access to the private RDS database, I've implemented a bastion host in the public subnet:

![Bastion Host Architecture](bastioninstance.png)

The bastion host:
- Runs Amazon Linux 2
- Is located in public subnet (10.0.1.0/24)
- Has IP: 98.83.119.96
- Allows SSH access with the bastion-key-new.pem key

### Database Query Script

I've created a PowerShell script `show_database.ps1` that provides easy access to the database:

```powershell
# Command to access database contents
.\show_database.ps1
```

Output from the script:
```
===== CONNECTING TO DATABASE VIA BASTION HOST =====

=================== DATABASES ===================
Database
flaskcrud
information_schema
mysql
performance_schema
sys
=================== TABLES IN flaskcrud ===================
Tables_in_flaskcrud
entry
=================== TABLE STRUCTURE ===================
Field   Type    Null    Key     Default Extra
id      int     NO      PRI     NULL    auto_increment
title   varchar(64)     NO      MUL     NULL
description     varchar(120)    NO      MUL     NULL
status  tinyint(1)      YES             NULL
=================== TABLE DATA ===================
id      title   description     status
4       dzqdzdzq        dzqdqz  1
5       test    test    0
7       bling bling     wwowowwww       1
```

This script establishes an SSH connection to the bastion host, which then connects to the RDS instance in the private subnet. This maintains the security of our database while allowing authorized administrative access.

## Environment Variables and Security

This project uses environment variables to manage sensitive configuration. To set up your environment:

1. Copy `.env.example` to `.env` in both the root and flask-app directories
2. Fill in your actual credentials in the `.env` files
3. Never commit the actual `.env` files to version control

Required environment variables:
- `SECRET_KEY`: Flask application secret key
- `DATABASE_URL`: MySQL database connection string

The application will load these variables from the .env file at runtime, or you can set them directly in your environment.

For security best practices:
- Store credentials in a password manager, not in code
- Use different credentials for development and production
- Consider using AWS Secrets Manager for production deployments

## Implementation Guide

### AWS Management Console Implementation

#### 1. VPC Setup
1. Create VPC named "flask-vpc-1" with CIDR 10.0.0.0/16
2. Create subnets:
   - Public subnets in two AZs:
     * flask-subnet-1 (10.0.1.0/24) in us-east-1a
     * flask-subnet-2 (10.0.2.0/24) in us-east-1b
   - Private app subnets in two AZs:
     * flask-private-subnet-1 (10.0.3.0/24) in us-east-1a
     * flask-private-subnet-2 (10.0.4.0/24) in us-east-1b
   - Database subnets in two AZs:
     * flask-db-subnet-1 (10.0.5.0/24) in us-east-1a
     * flask-db-subnet-2 (10.0.6.0/24) in us-east-1b
3. Create Internet Gateway (flask-iwg-1) and attach to VPC
4. Create NAT Gateway (flask-nat-gateway-1) in a public subnet
5. Create and configure route tables:
   - Public route table (flask-public-rtb) with route to IGW for public subnets
   - Private route table (flask-rtb-1) with route to NAT Gateway for private app subnets
   - Database route table (flask-db-rt-1) with local routes only for database subnets

#### 2. Database Tier
1. Create Security Group "flask-db-sg"
2. Create DB Subnet Group using database subnets (10.0.5.0/24, 10.0.6.0/24)
3. Create RDS MySQL instance:
   - DB identifier: flask-crud-db
   - Engine: MySQL 8.0
   - Instance class: db.t3.micro
   - Multi-AZ: Yes (for improved reliability)
   - Initial database name: flaskcrud
   - Security group: flask-db-sg
   - Subnet group: Database subnets
   - Storage: 20GB gp2, encrypted

#### 3. Middle Tier
1. Create Security Group "flask-app-sg"
2. Create ECR repository for Docker image
3. Modify Flask application:
   - Update config.py to connect to RDS
   - Add ProxyFix middleware to handle headers from ALB
4. Build and push Docker image with Gunicorn
5. Create ECS cluster "flask-app-cluster"
6. Create Task Definition:
   - Fargate compatible
   - 512MB memory, 0.25 vCPU
   - Container:
     - Port mapping: 8000
     - Environment variables for DB connection
     - CloudWatch logging enabled to group "/ecs/flask-app"
7. Create ECS Service with 2 tasks in private app subnets (10.0.3.0/24, 10.0.4.0/24)

#### 4. Front-end Tier
1. Create Security Group "flask-alb-sg"
2. Create Application Load Balancer:
   - Name: flask-app-alb
   - Internet-facing
   - Public subnets (10.0.1.0/24, 10.0.2.0/24)
   - Security group: flask-alb-sg
   - Target group with health check to port 8000
3. Create ACM certificate for domain flask.quinten-de-meyer.be
4. Add HTTPS listener with certificate
5. Configure redirect from HTTP to HTTPS

#### 5. Bastion Host
1. Create Security Group "bastion-sg"
2. Create EC2 key pair named "bastion-key-new"
3. Launch EC2 instance in public subnet (10.0.1.0/24) with Amazon Linux 2
4. Assign Elastic IP: 98.83.119.96
5. Configure security group to allow SSH access

### AWS CLI Implementation

```bash
# 1. VPC Setup
VPC_ID=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=flask-vpc-1}]' --query 'Vpc.VpcId' --output text)
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames

# Create Subnets
PUBLIC_SUBNET1_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.1.0/24 --availability-zone us-east-1a --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=flask-subnet-1}]' --query 'Subnet.SubnetId' --output text)
PUBLIC_SUBNET2_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.2.0/24 --availability-zone us-east-1b --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=flask-subnet-2}]' --query 'Subnet.SubnetId' --output text)
PRIVATE_SUBNET1_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.3.0/24 --availability-zone us-east-1a --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=flask-private-subnet-1}]' --query 'Subnet.SubnetId' --output text)
PRIVATE_SUBNET2_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.4.0/24 --availability-zone us-east-1b --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=flask-private-subnet-2}]' --query 'Subnet.SubnetId' --output text)
DB_SUBNET1_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.5.0/24 --availability-zone us-east-1a --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=flask-db-subnet-1}]' --query 'Subnet.SubnetId' --output text)
DB_SUBNET2_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.6.0/24 --availability-zone us-east-1b --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=flask-db-subnet-2}]' --query 'Subnet.SubnetId' --output text)

# Create Internet Gateway
IGW_ID=$(aws ec2 create-internet-gateway --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=flask-iwg-1}]' --query 'InternetGateway.InternetGatewayId' --output text)
aws ec2 attach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID

# Create and configure public route table
PUBLIC_RT_ID=$(aws ec2 create-route-table --vpc-id $VPC_ID --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=flask-public-rtb}]' --query 'RouteTable.RouteTableId' --output text)
aws ec2 create-route --route-table-id $PUBLIC_RT_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID
aws ec2 associate-route-table --route-table-id $PUBLIC_RT_ID --subnet-id $PUBLIC_SUBNET1_ID
aws ec2 associate-route-table --route-table-id $PUBLIC_RT_ID --subnet-id $PUBLIC_SUBNET2_ID

# Allocate Elastic IP for NAT Gateway
EIP_ALLOC_ID=$(aws ec2 allocate-address --domain vpc --query 'AllocationId' --output text)

# Create NAT Gateway
NAT_GW_ID=$(aws ec2 create-nat-gateway --subnet-id $PUBLIC_SUBNET1_ID --allocation-id $EIP_ALLOC_ID --tag-specifications 'ResourceType=natgateway,Tags=[{Key=Name,Value=flask-nat-gateway-1}]' --query 'NatGateway.NatGatewayId' --output text)

# Create and configure private app subnet route table
PRIVATE_RT_ID=$(aws ec2 create-route-table --vpc-id $VPC_ID --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=flask-rtb-1}]' --query 'RouteTable.RouteTableId' --output text)
aws ec2 create-route --route-table-id $PRIVATE_RT_ID --destination-cidr-block 0.0.0.0/0 --nat-gateway-id $NAT_GW_ID
aws ec2 associate-route-table --route-table-id $PRIVATE_RT_ID --subnet-id $PRIVATE_SUBNET1_ID
aws ec2 associate-route-table --route-table-id $PRIVATE_RT_ID --subnet-id $PRIVATE_SUBNET2_ID

# Create and configure database subnet route table
DB_RT_ID=$(aws ec2 create-route-table --vpc-id $VPC_ID --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=flask-db-rt-1}]' --query 'RouteTable.RouteTableId' --output text)
aws ec2 associate-route-table --route-table-id $DB_RT_ID --subnet-id $DB_SUBNET1_ID
aws ec2 associate-route-table --route-table-id $DB_RT_ID --subnet-id $DB_SUBNET2_ID

# 2. Database Tier
# Create Security Group for RDS
DB_SG_ID=$(aws ec2 create-security-group --group-name flask-db-sg --description "Security group for Flask app database" --vpc-id $VPC_ID --query 'GroupId' --output text)
aws ec2 create-tags --resources $DB_SG_ID --tags Key=Name,Value=flask-db-sg

# Create DB Subnet Group
aws rds create-db-subnet-group --db-subnet-group-name flask-db-subnet-group --db-subnet-group-description "Subnet group for Flask app database" --subnet-ids $DB_SUBNET1_ID $DB_SUBNET2_ID

# Create RDS Instance with Multi-AZ
aws rds create-db-instance \
    --db-instance-identifier flask-crud-db \
    --db-name flaskcrud \
    --engine mysql \
    --engine-version 8.0.32 \
    --master-username admin \
    --master-user-password '*k62VSj4w6u1vSAxqk6h' \
    --db-instance-class db.t3.micro \
    --allocated-storage 20 \
    --storage-type gp2 \
    --storage-encrypted \
    --vpc-security-group-ids $DB_SG_ID \
    --db-subnet-group-name flask-db-subnet-group \
    --multi-az \
    --backup-retention-period 7 \
    --no-publicly-accessible

# 3. Middle Tier
# Create Security Group for ECS
ECS_SG_ID=$(aws ec2 create-security-group --group-name flask-app-sg --description "Security group for Flask app ECS tasks" --vpc-id $VPC_ID --query 'GroupId' --output text)
aws ec2 create-tags --resources $ECS_SG_ID --tags Key=Name,Value=flask-app-sg

# Create ECR Repository
aws ecr create-repository --repository-name flask-crud-app

# Authenticate to ECR
aws ecr get-login-password | docker login --username AWS --password-stdin $(aws sts get-caller-identity --query 'Account' --output text).dkr.ecr.$(aws configure get region).amazonaws.com

# Build and push Docker image
docker build -t flask-crud-app ./flask-app
docker tag flask-crud-app:latest $(aws sts get-caller-identity --query 'Account' --output text).dkr.ecr.$(aws configure get region).amazonaws.com/flask-crud-app:latest
docker push $(aws sts get-caller-identity --query 'Account' --output text).dkr.ecr.$(aws configure get region).amazonaws.com/flask-crud-app:latest

# Create ECS Cluster
aws ecs create-cluster --cluster-name flask-app-cluster

# Create CloudWatch Logs Group
aws logs create-log-group --log-group-name /ecs/flask-app

# Create Task Definition
aws ecs register-task-definition \
    --family flask-app-task \
    --network-mode awsvpc \
    --requires-compatibilities FARGATE \
    --cpu 256 \
    --memory 512 \
    --execution-role-arn arn:aws:iam::$(aws sts get-caller-identity --query 'Account' --output text):role/LabRole \
    --container-definitions "[{\"name\":\"flask-app\",\"image\":\"$(aws sts get-caller-identity --query 'Account' --output text).dkr.ecr.$(aws configure get region).amazonaws.com/flask-crud-app:latest\",\"essential\":true,\"portMappings\":[{\"containerPort\":8000,\"hostPort\":8000,\"protocol\":\"tcp\"}],\"environment\":[{\"name\":\"SECRET_KEY\",\"value\":\"$mgX!8HG98&HY#tW92qC\"},{\"name\":\"DATABASE_URL\",\"value\":\"mysql+pymysql://admin:*k62VSj4w6u1vSAxqk6h@flask-crud-db.czyocqcwwzna.us-east-1.rds.amazonaws.com:3306/flaskcrud\"}],\"logConfiguration\":{\"logDriver\":\"awslogs\",\"options\":{\"awslogs-group\":\"/ecs/flask-app\",\"awslogs-region\":\"$(aws configure get region)\",\"awslogs-stream-prefix\":\"ecs\",\"awslogs-create-group\":\"true\",\"mode\":\"non-blocking\",\"max-buffer-size\":\"25m\"}}}]"

# 4. Front-end Tier
# Create Security Group for ALB
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

# Create HTTP listener initially
HTTP_LISTENER_ARN=$(aws elbv2 create-listener \
    --load-balancer-arn $ALB_ARN \
    --protocol HTTP \
    --port 80 \
    --default-actions Type=forward,TargetGroupArn=$TG_ARN \
    --query 'Listeners[0].ListenerArn' \
    --output text)

# Create ECS service
aws ecs create-service \
    --cluster flask-app-cluster \
    --service-name flask-app-service \
    --task-definition flask-app-task:1 \
    --desired-count 2 \
    --launch-type FARGATE \
    --network-configuration "awsvpcConfiguration={subnets=[$PRIVATE_SUBNET1_ID,$PRIVATE_SUBNET2_ID],securityGroups=[$ECS_SG_ID],assignPublicIp=DISABLED}" \
    --load-balancers "targetGroupArn=$TG_ARN,containerName=flask-app,containerPort=8000" \
    --health-check-grace-period-seconds 0 \
    --deployment-configuration "deploymentCircuitBreaker={enable=true,rollback=true}" \
    --enable-execute-command

# 5. HTTPS Configuration
# Request certificate
CERT_ARN=$(aws acm request-certificate \
    --domain-name flask.quinten-de-meyer.be \
    --validation-method DNS \
    --query 'CertificateArn' \
    --output text)

# Create HTTPS listener (after certificate validation)
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

# 6. Bastion Host
# Create Security Group for Bastion
BASTION_SG_ID=$(aws ec2 create-security-group --group-name bastion-sg --description "Security group for bastion host" --vpc-id $VPC_ID --query 'GroupId' --output text)
aws ec2 create-tags --resources $BASTION_SG_ID --tags Key=Name,Value=bastion-sg
aws ec2 authorize-security-group-ingress --group-id $BASTION_SG_ID --protocol tcp --port 22 --cidr 0.0.0.0/0

# Update DB security group to allow access from bastion
aws ec2 authorize-security-group-ingress --group-id $DB_SG_ID --protocol tcp --port 3306 --source-group $BASTION_SG_ID

# Create key pair
aws ec2 create-key-pair --key-name bastion-key-new --query 'KeyMaterial' --output text > bastion-key-new.pem
chmod 400 bastion-key-new.pem

# Get latest Amazon Linux 2 AMI ID
AMI_ID=$(aws ec2 describe-images --owners amazon --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" "Name=state,Values=available" --query "sort_by(Images, &CreationDate)[-1].ImageId" --output text)

# Launch EC2 instance
INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --count 1 \
    --instance-type t2.micro \
    --key-name bastion-key-new \
    --security-group-ids $BASTION_SG_ID \
    --subnet-id $PUBLIC_SUBNET1_ID \
    --associate-public-ip-address \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=flask-bastion-host}]' \
    --query 'Instances[0].InstanceId' \
    --output text)

# Allocate and associate Elastic IP for Bastion
BASTION_EIP_ALLOC_ID=$(aws ec2 allocate-address --domain vpc --query 'AllocationId' --output text)
aws ec2 associate-address --allocation-id $BASTION_EIP_ALLOC_ID --instance-id $INSTANCE_ID
```

## Code Changes Made

### 1. Modified config.py
```python
class Config(object):
    SECRET_KEY = os.environ.get('SECRET_KEY') or 'dev-temporary-key-not-for-production'
    SQLALCHEMY_DATABASE_URI = os.environ.get('DATABASE_URL') or 'sqlite:///' + os.path.join(basedir, 'app.db')
    SQLALCHEMY_TRACK_MODIFICATIONS = False
```

### 2. Added ProxyFix in __init__.py
```python
from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
from dotenv import load_dotenv
import os
from werkzeug.middleware.proxy_fix import ProxyFix

# Load environment variables from .env file if present
load_dotenv()

app = Flask(__name__)
app.wsgi_app = ProxyFix(app.wsgi_app, x_proto=1, x_host=1)
app.config.from_object('app.config.Config')
db = SQLAlchemy(app)
migrate = Migrate(app, db)
```

### 3. Updated Dockerfile
```dockerfile
FROM python:3.9-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Install Gunicorn and python-dotenv
RUN pip install --no-cache-dir gunicorn python-dotenv

# Copy the application
COPY . .

# Make the entrypoint script executable
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV FLASK_APP=wsgi.py

# Expose port 8000
EXPOSE 8000

# Run the entrypoint script
ENTRYPOINT ["/entrypoint.sh"]
``` 