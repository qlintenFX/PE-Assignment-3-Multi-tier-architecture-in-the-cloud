# Multi-tier Architecture in the Cloud: Flask CRUD Application

## Introduction

This project implements a multi-tier architecture in AWS for a Flask CRUD application. The architecture follows best practices for production deployment, ensuring high availability, security, and scalability. The solution uses AWS managed services where appropriate, with careful consideration of network security and resource isolation.

The deployed application allows users to create, read, update, and delete simple text entries through a web interface. Instead of using Flask's development server, the application is deployed using a production-ready WSGI server (Gunicorn) as required for production environments.

## Architecture Design

### Architecture Diagram

![Multi-tier Architecture Diagram](https://i.imgur.com/IqXTlgH.png)

*Note: The above diagram is a representation of the architecture. Replace this with your actual architecture diagram.*

### Components Overview

The architecture consists of three primary tiers:

1. **Front-end Tier** (Public Subnet)
   - Application Load Balancer (ALB)
   - Provides HTTP access on port 80 to users
   - Handles TLS termination and routes traffic to application servers
   - Located in public subnets across multiple availability zones

2. **Middle Tier** (Private Subnet)
   - ECS Fargate Cluster running containerized Flask application
   - Gunicorn WSGI server processes requests
   - Auto-scaling capabilities based on demand
   - Located in private subnets with no direct internet access
   - Internet access for updates via NAT Gateway

3. **Back-end Tier** (Private Subnet)
   - Amazon RDS MySQL database instance
   - Stores application data persistently
   - Located in private subnets with restricted access
   - Only accessible from the application tier

### Security Groups Configuration

| Security Group | Purpose | Inbound Rules | Outbound Rules |
|----------------|---------|---------------|----------------|
| alb-sg | Controls access to the ALB | HTTP (80) from 0.0.0.0/0 | All traffic to app-sg |
| app-sg | Controls access to the ECS tasks | HTTP (8000) from alb-sg | MySQL (3306) to db-sg, HTTPS (443) to 0.0.0.0/0 |
| db-sg | Controls access to the RDS instance | MySQL (3306) from app-sg | No outbound traffic |

### Route Tables Configuration

| Route Table | Associated Subnets | Routes |
|-------------|-------------------|--------|
| Public Route Table | Public Subnets (us-east-1a, us-east-1b) | Local VPC CIDR, 0.0.0.0/0 → Internet Gateway |
| Private App Route Table | Private App Subnets (us-east-1a, us-east-1b) | Local VPC CIDR, 0.0.0.0/0 → NAT Gateway |
| Private DB Route Table | Private DB Subnets (us-east-1a, us-east-1b) | Local VPC CIDR only (no internet access) |

### IP Addressing

| Component | Subnet Type | CIDR Block |
|-----------|-------------|------------|
| Public Subnet 1 | Public | 10.0.1.0/24 |
| Public Subnet 2 | Public | 10.0.2.0/24 |
| Private App Subnet 1 | Private | 10.0.3.0/24 |
| Private App Subnet 2 | Private | 10.0.4.0/24 |
| Private DB Subnet 1 | Private | 10.0.5.0/24 |
| Private DB Subnet 2 | Private | 10.0.6.0/24 |
| VPC | - | 10.0.0.0/16 |

## Implementation Guide

### 1. VPC and Network Setup

#### Using AWS Management Console

**1. Create a VPC**

1. Navigate to the VPC service in the AWS Management Console
2. Click "Create VPC"
3. Select "VPC and more" to create a VPC with subnets, route tables, and other components
4. Configure the following settings:
   - Name tag: `flask-app-vpc`
   - IPv4 CIDR block: `10.0.0.0/16`
   - Number of Availability Zones: `2` (select us-east-1a and us-east-1b)
   - Number of public subnets: `2`
   - Number of private subnets: `4` (2 for application tier, 2 for database tier)
   - NAT gateways: `1 per AZ` for outbound internet access from private subnets
   - VPC endpoints: None (for this basic setup)
5. Review your configuration and click "Create VPC"

**2. Rename Subnets for Better Organization**

1. After VPC creation, go to the "Subnets" section
2. For each subnet, select it and click "Actions" → "Edit subnet settings"
3. Update names according to their purpose:
   - Public subnets: `public-subnet-1a`, `public-subnet-1b`
   - Private app subnets: `private-app-subnet-1a`, `private-app-subnet-1b`
   - Private DB subnets: `private-db-subnet-1a`, `private-db-subnet-1b`

**3. Configure Route Tables**

1. Go to "Route Tables" section
2. Identify the route tables created with your VPC
3. For each route table, select it and click "Actions" → "Edit route table settings"
4. Rename them according to their purpose:
   - Public route table: `public-rt`
   - Private app route table: `private-app-rt`
   - Private DB route table: `private-db-rt`
5. Verify routes are correctly configured:
   - Public RT should have a route to the Internet Gateway for 0.0.0.0/0
   - Private App RT should have a route to the NAT Gateway for 0.0.0.0/0
   - Private DB RT should only have local routes within the VPC

**4. Create Security Groups**

1. Go to "Security Groups" section
2. Click "Create security group"
3. Create the ALB security group:
   - Name: `alb-sg`
   - Description: "Security group for ALB"
   - VPC: Select your `flask-app-vpc`
   - Inbound rules: Add rule for HTTP (80) from Anywhere (0.0.0.0/0)
   - Outbound rules: Leave as default (All traffic)
4. Click "Create security group"
5. Repeat to create the App security group:
   - Name: `app-sg`
   - Description: "Security group for application servers"
   - VPC: Select your `flask-app-vpc`
   - Inbound rules: Add rule for TCP (8000) from the ALB security group
   - Outbound rules: Leave as default (All traffic)
6. Repeat to create the DB security group:
   - Name: `db-sg`
   - Description: "Security group for database"
   - VPC: Select your `flask-app-vpc`
   - Inbound rules: Add rule for MySQL (3306) from the App security group
   - Outbound rules: Remove all rules for maximum security

#### Using AWS CLI

1. Create a new VPC with CIDR block 10.0.0.0/16
   
   ```bash
   aws ec2 create-vpc --cidr-block 10.0.0.0/16 --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=flask-app-vpc}]'
   ```

2. Create subnets as defined in the IP addressing table
   
   ```bash
   # Create public subnets
   aws ec2 create-subnet --vpc-id vpc-**** --cidr-block 10.0.1.0/24 --availability-zone us-east-1a --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=public-subnet-1a}]'
   aws ec2 create-subnet --vpc-id vpc-**** --cidr-block 10.0.2.0/24 --availability-zone us-east-1b --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=public-subnet-1b}]'
   
   # Create private app subnets
   aws ec2 create-subnet --vpc-id vpc-**** --cidr-block 10.0.3.0/24 --availability-zone us-east-1a --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=private-app-subnet-1a}]'
   aws ec2 create-subnet --vpc-id vpc-**** --cidr-block 10.0.4.0/24 --availability-zone us-east-1b --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=private-app-subnet-1b}]'
   
   # Create private DB subnets
   aws ec2 create-subnet --vpc-id vpc-**** --cidr-block 10.0.5.0/24 --availability-zone us-east-1a --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=private-db-subnet-1a}]'
   aws ec2 create-subnet --vpc-id vpc-**** --cidr-block 10.0.6.0/24 --availability-zone us-east-1b --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=private-db-subnet-1b}]'
   ```

3. Create an Internet Gateway and attach it to the VPC
   
   ```bash
   aws ec2 create-internet-gateway --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=flask-app-igw}]'
   aws ec2 attach-internet-gateway --internet-gateway-id igw-**** --vpc-id vpc-****
   ```

4. Create a NAT Gateway in a public subnet
   
   ```bash
   aws ec2 allocate-address --domain vpc
   aws ec2 create-nat-gateway --subnet-id subnet-**** --allocation-id eipalloc-**** --tag-specifications 'ResourceType=natgateway,Tags=[{Key=Name,Value=flask-app-natgw}]'
   ```

5. Create and configure route tables (as shown in original CLI commands)

6. Create security groups (as shown in original CLI commands)

### 2. Database Tier Setup

#### Using AWS Management Console

**1. Create DB Subnet Group**

1. Navigate to the Amazon RDS service in the AWS Management Console
2. In the left navigation pane, click "Subnet groups"
3. Click "Create DB subnet group"
4. Configure the following settings:
   - Name: `flask-db-subnet-group`
   - Description: "Subnet group for Flask app database"
   - VPC: Select your `flask-app-vpc`
   - Availability zones: Select both AZs (us-east-1a and us-east-1b)
   - Subnets: Select your private DB subnets
5. Click "Create"

**2. Create RDS MySQL Instance**

1. In the RDS dashboard, click "Create database"
2. Choose "Standard create" and select MySQL as the database engine
3. Configure basic settings:
   - Engine Version: MySQL 8.0.32 (or latest available)
   - Templates: Production
   - DB instance identifier: `flask-crud-db`
   - Master username: `admin`
   - Master password: Create a secure password
4. Configure instance specifications:
   - DB instance class: Burstable classes (t3.micro)
   - Storage: 20 GB (General Purpose SSD)
   - Enable storage autoscaling
5. Configure connectivity:
   - VPC: Select your `flask-app-vpc`
   - Subnet group: Select `flask-db-subnet-group`
   - Public access: No
   - VPC security group: Select the `db-sg` security group
   - Availability Zone: No preference
6. Additional configuration:
   - Initial database name: `flaskcrud`
   - Backup: Enable automatic backups with 7-day retention
   - Monitoring: Enable Enhanced monitoring (optional)
   - Maintenance: Enable auto minor version upgrade
7. Click "Create database"

#### Using AWS CLI

1. Create a DB subnet group for RDS
   
   ```bash
   aws rds create-db-subnet-group \
     --db-subnet-group-name flask-db-subnet-group \
     --db-subnet-group-description "Subnet group for Flask app database" \
     --subnet-ids subnet-**** subnet-**** # Private DB subnet IDs
   ```

2. Create an RDS MySQL instance
   
   ```bash
   aws rds create-db-instance \
     --db-instance-identifier flask-crud-db \
     --db-instance-class db.t3.micro \
     --engine mysql \
     --master-username admin \
     --master-user-password <secure-password> \
     --allocated-storage 20 \
     --db-subnet-group-name flask-db-subnet-group \
     --vpc-security-group-ids sg-**** \
     --db-name flaskcrud \
     --backup-retention-period 7 \
     --no-publicly-accessible \
     --storage-encrypted
   ```

3. Wait for the database to be available
   
   ```bash
   aws rds wait db-instance-available --db-instance-identifier flask-crud-db
   ```

### 3. Application Tier Setup

#### Using AWS Management Console

**1. Modify Flask Application Code**

1. As shown in the CLI section, update the `config.py` file
2. Create the `wsgi.py` file for ProxyFix middleware
3. Create the Dockerfile and entrypoint.sh script

**2. Build and Push Docker Image**

1. Build the Docker image locally as shown in the CLI section
2. Navigate to the Amazon ECR service in the AWS Management Console
3. Click "Create repository"
4. Enter repository name: `flask-crud-app`
5. Keep other settings as default and click "Create repository"
6. Click on your newly created repository
7. Click "View push commands"
8. Follow the displayed commands to authenticate Docker, tag, and push your image

#### Using AWS CLI

1. Modify the Flask application code to connect to the RDS database (as shown in original CLI commands)

2. Add ProxyFix middleware (as shown in original CLI commands)

3. Create a Dockerfile for the application (as shown in original CLI commands)

4. Create an entrypoint script for the container (as shown in original CLI commands)

5. Build and tag the Docker image
   
   ```bash
   cd flask-app
   docker build -t flask-crud-app:latest .
   ```

6. Create an ECR repository and push the Docker image
   
   ```bash
   # Create ECR repository
   aws ecr create-repository --repository-name flask-crud-app
   
   # Authenticate Docker to the ECR registry
   aws ecr get-login-password | docker login --username AWS --password-stdin $(aws sts get-caller-identity --query Account --output text).dkr.ecr.us-east-1.amazonaws.com
   
   # Tag the image for ECR
   docker tag flask-crud-app:latest $(aws sts get-caller-identity --query Account --output text).dkr.ecr.us-east-1.amazonaws.com/flask-crud-app:latest
   
   # Push the image to ECR
   docker push $(aws sts get-caller-identity --query Account --output text).dkr.ecr.us-east-1.amazonaws.com/flask-crud-app:latest
   ```

### 4. ECS Fargate Setup

#### Using AWS Management Console

**1. Create ECS Cluster**

1. Navigate to the Amazon ECS service in the AWS Management Console
2. Click "Clusters" in the left navigation pane
3. Click "Create Cluster"
4. Select "Networking only" as the cluster template (for Fargate)
5. Configure basic settings:
   - Cluster name: `flask-app-cluster`
   - Tags: Add Name tag if desired
6. Click "Create"

**2. Create Task Definition**

1. In the ECS dashboard, click "Task Definitions" in the left navigation pane
2. Click "Create new Task Definition"
3. Select "Fargate" as the launch type and click "Next step"
4. Configure basic settings:
   - Task Definition Name: `flask-app-task`
   - Task Role: `ecsTaskExecutionRole`
   - Task execution role: `ecsTaskExecutionRole`
   - Task memory: 0.5GB (512MB)
   - Task CPU: 0.25 vCPU (256)
5. Add a container:
   - Container name: `flask-app`
   - Image: Enter your ECR image URI
   - Memory Limits: Soft limit of 512MB
   - Port mappings: Add 8000 for container port
   - Environment variables: Add DATABASE_URL and SECRET_KEY
   - Configure CloudWatch Logs:
     - Log configuration: awslogs
     - Log group: `/ecs/flask-app`
     - Region: us-east-1
     - Auto-create: Yes
     - Stream prefix: ecs
6. Click "Add" to add the container, then "Create" to create the task definition

**3. Create Application Load Balancer**

1. Navigate to the EC2 service
2. Click "Load Balancers" in the left navigation pane
3. Click "Create Load Balancer"
4. Select "Application Load Balancer"
5. Configure basic settings:
   - Name: `flask-app-alb`
   - Scheme: internet-facing
   - IP address type: ipv4
   - Listeners: HTTP on port 80
   - Availability Zones: Select your VPC and check both public subnets
6. Configure Security Settings (skip for HTTP only)
7. Configure Security Groups:
   - Select the `alb-sg` security group you created earlier
8. Configure Routing:
   - Target group: New target group
   - Name: `flask-app-tg`
   - Target type: IP
   - Protocol: HTTP
   - Port: 8000
   - Health checks: 
     - Path: `/`
     - Advanced settings: customize if needed
9. Skip target registration (ECS will register targets)
10. Review and create the load balancer

**4. Create ECS Service**

1. Go back to the ECS service
2. Select your `flask-app-cluster`
3. Click the "Services" tab, then "Create"
4. Configure basic service settings:
   - Launch type: FARGATE
   - Task Definition: Select your `flask-app-task`
   - Service name: `flask-app-service`
   - Number of tasks: 2
   - Deployment type: Rolling update
   - Enable deployment circuit breaker with rollback
5. Configure networking:
   - VPC: Select your `flask-app-vpc`
   - Subnets: Select your private app subnets
   - Security groups: Select the `app-sg` security group
   - Auto-assign public IP: DISABLED
6. Configure load balancing:
   - Load balancer type: Application Load Balancer
   - Load balancer: Select your `flask-app-alb`
   - Target group: Select your `flask-app-tg`
   - Container port: 8000
7. Skip Auto Scaling for now (we'll add it later)
8. Review and create the service

#### Using AWS CLI

1. Create an ECS cluster
   
   ```bash
   aws ecs create-cluster --cluster-name flask-app-cluster
   ```

2. Create a task definition for the Flask application (as shown in original CLI commands)

3. Create a load balancer (as shown in original CLI commands)

4. Create an ECS service (as shown in original CLI commands)

### 5. Monitoring and Logging

#### Using AWS Management Console

**1. View CloudWatch Logs**

1. Navigate to the CloudWatch service in the AWS Management Console
2. Click "Log groups" in the left navigation pane
3. Find and select the `/ecs/flask-app` log group
4. Browse through log streams to view application logs
5. Select a specific log stream to see detailed logs

**2. Monitor ECS Service Health**

1. Navigate to the ECS service
2. Select your `flask-app-cluster`
3. Click the "Services" tab
4. Select your `flask-app-service`
5. Review the "Health and metrics" tab to see service status
6. Check the "Events" tab for deployment events and issues
7. Check the "Tasks" tab to see running tasks and their status

#### Using AWS CLI

1. View application logs in CloudWatch (as shown in original CLI commands)

2. Monitor the service health (as shown in original CLI commands)

## Application Access

You can access the Flask CRUD application via the ALB DNS name:

```
http://<alb-dns-name>
```

To find your ALB DNS name:

1. **AWS Management Console**: Navigate to EC2 → Load Balancers → Select your ALB → Copy the DNS name
2. **AWS CLI**: Use the command below

```bash
aws elbv2 describe-load-balancers --names flask-app-alb --query 'LoadBalancers[0].DNSName' --output text
```

## Technical Choices and Reasoning

1. **Amazon ECS with Fargate**:
   - Serverless container management eliminates the need to provision and manage servers
   - Automatic scaling capabilities
   - Integration with CloudWatch for logging and monitoring
   - Pay-per-use pricing model

2. **Gunicorn WSGI Server**:
   - Production-ready WSGI HTTP Server for Unix
   - Pre-fork worker model provides good performance and reliability
   - Easy to configure and deploy
   - Well-documented and widely used in production Flask deployments

3. **Amazon RDS for MySQL**:
   - Managed database service with automatic backups and patching
   - High availability with multi-AZ deployment option
   - Performance insights and monitoring capabilities
   - Data is persisted independently of application containers

4. **Application Load Balancer**:
   - Content-based routing capabilities
   - Support for HTTP/HTTPS protocols
   - Health checking capabilities
   - Support for WebSockets and HTTP/2
   - Integration with Amazon ECS for dynamic port mapping

5. **VPC with Public and Private Subnets**:
   - Isolates resources for enhanced security
   - Public subnets for internet-facing components (ALB)
   - Private subnets for application and database tiers
   - NAT Gateway provides outbound internet access for application tier while maintaining security

## Extra Implementations

### 1. HTTPS Support with Certificate Manager

#### Using AWS Management Console

1. Navigate to AWS Certificate Manager
2. Click "Request a certificate"
3. Select "Request a public certificate" and click "Next"
4. Enter your domain name(s) and click "Next"
5. Choose DNS validation or email validation
6. Add tags if desired and click "Request"
7. Complete validation process
8. Once validated, go to EC2 → Load Balancers → Select your ALB
9. Add a listener on port 443 with HTTPS protocol
10. Select your certificate
11. Configure the default action to forward to your target group
12. Save the new listener
13. Edit the HTTP (port 80) listener to redirect to HTTPS

#### Using AWS CLI

1. Create a certificate in AWS Certificate Manager
   
   ```bash
   aws acm request-certificate --domain-name example.com --validation-method DNS
   ```

2. Add an HTTPS listener to the ALB
   
   ```bash
   aws elbv2 create-listener \
     --load-balancer-arn arn:aws:elasticloadbalancing:us-east-1:$(aws sts get-caller-identity --query Account --output text):loadbalancer/app/flask-app-alb/**** \
     --protocol HTTPS \
     --port 443 \
     --certificates CertificateArn=arn:aws:acm:us-east-1:$(aws sts get-caller-identity --query Account --output text):certificate/**** \
     --default-actions Type=forward,TargetGroupArn=arn:aws:elasticloadbalancing:us-east-1:$(aws sts get-caller-identity --query Account --output text):targetgroup/flask-app-tg/****
   ```

3. Add a redirect from HTTP to HTTPS
   
   ```bash
   aws elbv2 modify-listener \
     --listener-arn arn:aws:elasticloadbalancing:us-east-1:$(aws sts get-caller-identity --query Account --output text):listener/app/flask-app-alb/****/****  \
     --default-actions 'Type=redirect,RedirectConfig={Protocol=HTTPS,Port=443,StatusCode=HTTP_301}'
   ```

### 2. Auto Scaling for Application Tier

#### Using AWS Management Console

1. Navigate to ECS → Clusters → Select your cluster
2. Select your service and click "Update"
3. In the "Service Auto Scaling" section, click "Configure Service Auto Scaling"
4. Set the minimum, desired, and maximum number of tasks
5. Configure scaling policies:
   - Add a policy for CPU utilization
   - Target value: 70%
   - Scale-out cooldown: 60 seconds
   - Scale-in cooldown: 60 seconds
6. Save the auto scaling configuration

#### Using AWS CLI

1. Create an auto scaling target
   
   ```bash
   aws application-autoscaling register-scalable-target \
     --service-namespace ecs \
     --scalable-dimension ecs:service:DesiredCount \
     --resource-id service/flask-app-cluster/flask-app-service \
     --min-capacity 2 \
     --max-capacity 6
   ```

2. Create scaling policies based on CPU utilization
   
   ```bash
   aws application-autoscaling put-scaling-policy \
     --service-namespace ecs \
     --scalable-dimension ecs:service:DesiredCount \
     --resource-id service/flask-app-cluster/flask-app-service \
     --policy-name cpu-tracking-scaling-policy \
     --policy-type TargetTrackingScaling \
     --target-tracking-scaling-policy-configuration '{"TargetValue": 70.0, "PredefinedMetricSpecification": {"PredefinedMetricType": "ECSServiceAverageCPUUtilization"}}'
   ```

### 3. Database Backup and Recovery

#### Using AWS Management Console

1. Navigate to RDS → Databases → Select your database
2. Click "Modify"
3. Under "Backup", set the backup retention period to 7 days
4. Select "Apply immediately" for the modifications
5. Click "Modify DB Instance"
6. To create a read replica:
   - Select your database instance
   - Click "Actions" → "Create read replica"
   - Configure instance specifications (t3.micro)
   - Configure other settings as needed
   - Click "Create read replica"

#### Using AWS CLI

1. Enable automated backups with a 7-day retention period
   
   ```bash
   aws rds modify-db-instance \
     --db-instance-identifier flask-crud-db \
     --backup-retention-period 7 \
     --apply-immediately
   ```

2. Create a read replica for improved read performance
   
   ```bash
   aws rds create-db-instance-read-replica \
     --db-instance-identifier flask-crud-db-replica \
     --source-db-instance-identifier flask-crud-db \
     --db-instance-class db.t3.micro
   ```

## Further Improvements

For even better security and reliability, consider implementing:

1. **Web Application Firewall (WAF)** for protection against common web exploits
2. **AWS Shield** for DDoS protection
3. **Route 53** for DNS management and routing policies
4. **CloudFront** for content delivery and edge caching
5. **Secrets Manager** for secure handling of database credentials
6. **AWS Systems Manager Parameter Store** for configuration management

## Troubleshooting

If you encounter issues with the deployment, check the following:

### Using AWS Management Console

1. **ECS Service Status**:
   - Navigate to ECS → Clusters → Select your cluster
   - Check the "Services" tab and verify the service is running
   - Look for any deployment failures or stopped tasks

2. **CloudWatch Logs**:
   - Navigate to CloudWatch → Log groups → /ecs/flask-app
   - Select the most recent log stream
   - Review logs for error messages

3. **Target Group Health**:
   - Navigate to EC2 → Target Groups → Select your target group
   - Check the "Targets" tab to see health status
   - Look for any unhealthy targets and investigate

4. **Database Connectivity**:
   - Navigate to RDS → Databases
   - Verify your database is in "Available" state
   - Check security group rules to ensure proper connectivity

### Using AWS CLI

1. **ECS Service Status**:
   ```bash
   aws ecs describe-services --cluster flask-app-cluster --services flask-app-service
   ```

2. **CloudWatch Logs**:
   ```bash
   aws logs get-log-events --log-group-name /ecs/flask-app --log-stream-name <log-stream-name> --limit 50
   ```

3. **Target Group Health**:
   ```bash
   aws elbv2 describe-target-health --target-group-arn arn:aws:elasticloadbalancing:us-east-1:$(aws sts get-caller-identity --query Account --output text):targetgroup/flask-app-tg/****
   ```

4. **Database Connectivity**:
   Use the bastion host to test connectivity to the RDS instance:
   ```bash
   ssh -i labsuser.pem ec2-user@<bastion-host-ip>
   mysql -h <rds-endpoint> -u admin -p
   ```

## Conclusion

This multi-tier architecture provides a secure, scalable, and reliable platform for hosting the Flask CRUD application. By following the principles of separation of concerns and defense in depth, the architecture ensures that each tier is isolated and secured appropriately. The use of managed services reduces operational overhead while maintaining high availability and performance. 