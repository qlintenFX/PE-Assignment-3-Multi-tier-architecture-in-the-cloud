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

5. Create and configure route tables
   
   ```bash
   # Create public route table
   aws ec2 create-route-table --vpc-id vpc-**** --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=public-rt}]'
   aws ec2 create-route --route-table-id rtb-**** --destination-cidr-block 0.0.0.0/0 --gateway-id igw-****
   
   # Associate public subnets with public route table
   aws ec2 associate-route-table --route-table-id rtb-**** --subnet-id subnet-**** # Public subnet 1
   aws ec2 associate-route-table --route-table-id rtb-**** --subnet-id subnet-**** # Public subnet 2
   
   # Create private app route table
   aws ec2 create-route-table --vpc-id vpc-**** --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=private-app-rt}]'
   aws ec2 create-route --route-table-id rtb-**** --destination-cidr-block 0.0.0.0/0 --nat-gateway-id nat-****
   
   # Associate private app subnets with private app route table
   aws ec2 associate-route-table --route-table-id rtb-**** --subnet-id subnet-**** # Private app subnet 1
   aws ec2 associate-route-table --route-table-id rtb-**** --subnet-id subnet-**** # Private app subnet 2
   
   # Create private DB route table
   aws ec2 create-route-table --vpc-id vpc-**** --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=private-db-rt}]'
   
   # Associate private DB subnets with private DB route table
   aws ec2 associate-route-table --route-table-id rtb-**** --subnet-id subnet-**** # Private DB subnet 1
   aws ec2 associate-route-table --route-table-id rtb-**** --subnet-id subnet-**** # Private DB subnet 2
   ```

6. Create security groups
   
   ```bash
   # ALB security group
   aws ec2 create-security-group --group-name alb-sg --description "Security group for ALB" --vpc-id vpc-****
   aws ec2 authorize-security-group-ingress --group-id sg-**** --protocol tcp --port 80 --cidr 0.0.0.0/0
   
   # App security group
   aws ec2 create-security-group --group-name app-sg --description "Security group for application servers" --vpc-id vpc-****
   aws ec2 authorize-security-group-ingress --group-id sg-**** --protocol tcp --port 8000 --source-group sg-**** # ALB SG
   
   # DB security group
   aws ec2 create-security-group --group-name db-sg --description "Security group for database" --vpc-id vpc-****
   aws ec2 authorize-security-group-ingress --group-id sg-**** --protocol tcp --port 3306 --source-group sg-**** # App SG
   ```

### 2. Database Tier Setup

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

1. Modify the Flask application code to connect to the RDS database

   Edit the `flask-app/app/config.py` file:
   
   ```python
   import os
   basedir = os.path.abspath(os.path.dirname(__file__))
   
   class Config(object):
       SECRET_KEY = os.environ.get('SECRET_KEY') or 'do-or-do-not-there-is-no-try'
       SQLALCHEMY_DATABASE_URI = os.environ.get('DATABASE_URL')
       SQLALCHEMY_TRACK_MODIFICATIONS = False
   ```

2. Add ProxyFix middleware for proper handling of client IPs behind ALB

   Create `flask-app/wsgi.py` file:
   
   ```python
   from app import app
   from werkzeug.middleware.proxy_fix import ProxyFix
   
   # Apply ProxyFix middleware to handle X-Forwarded-* headers from the load balancer
   app.wsgi_app = ProxyFix(
       app.wsgi_app,
       x_for=1,        # Number of proxies setting X-Forwarded-For
       x_proto=1,      # Number of proxies setting X-Forwarded-Proto
       x_host=1,       # Number of proxies setting X-Forwarded-Host
       x_port=1,       # Number of proxies setting X-Forwarded-Port
       x_prefix=0      # Number of proxies setting X-Forwarded-Prefix
   )
   
   if __name__ == "__main__":
       app.run()
   ```

3. Create a Dockerfile for the application
   
   ```Dockerfile
   FROM python:3.9-slim
   
   WORKDIR /app
   
   COPY requirements.txt .
   RUN pip install --no-cache-dir -r requirements.txt
   
   COPY . .
   
   # Create an entrypoint script
   COPY docker/entrypoint.sh /entrypoint.sh
   RUN chmod +x /entrypoint.sh
   
   EXPOSE 8000
   
   ENTRYPOINT ["/entrypoint.sh"]
   ```

4. Create an entrypoint script for the container
   
   Create `flask-app/docker/entrypoint.sh`:
   
   ```bash
   #!/bin/bash
   
   # Print environment variables for debugging (excluding secrets)
   echo "Environment variables:"
   env | grep -v SECRET_KEY | grep -v DATABASE_URL
   
   # Database connection string (without password for logging)
   DB_CONNECTION=$(echo $DATABASE_URL | sed 's/:[^:]*@/:***@/')
   echo "Database connection string: $DB_CONNECTION"
   
   # Initialize the database
   echo "Initializing database..."
   
   # Attempt multiple times to initialize the database
   max_attempts=10
   attempt_count=0
   success=false
   
   while [ $attempt_count -lt $max_attempts ] && [ "$success" = false ]; do
     attempt_count=$((attempt_count+1))
     echo "Attempt $attempt_count of $max_attempts..."
     
     # Try to initialize the database
     python << EOF
   from app import db
   from app.models import Entry
   
   try:
       # Connect to the database
       connection = db.engine.connect()
       connection.close()
       print("Database connection successful!")
       
       # Check if tables exist
       connection = db.engine.connect()
       tables = connection.execute("SHOW TABLES").fetchall()
       table_names = [table[0] for table in tables]
       print(f"Existing tables: {table_names}")
       connection.close()
       
       # Create tables if they don't exist
       print("Creating tables if needed...")
       db.create_all()
       print("Tables created successfully!")
   except Exception as e:
       import traceback
       print(f"Database initialization error: {e}")
       traceback.print_exc()
       exit(1)
   EOF
     
     if [ $? -eq 0 ]; then
       success=true
       echo "Database initialization successful!"
     else
       echo "Database initialization failed, retrying in 5 seconds..."
       sleep 5
     fi
   done
   
   if [ "$success" = false ]; then
     echo "Failed to initialize database after $max_attempts attempts. Exiting."
     exit 1
   fi
   
   # Start Gunicorn WSGI server
   echo "Starting Gunicorn WSGI server..."
   exec gunicorn --bind 0.0.0.0:8000 --workers=2 wsgi:app
   ```

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

1. Create an ECS cluster
   
   ```bash
   aws ecs create-cluster --cluster-name flask-app-cluster
   ```

2. Create a task definition for the Flask application
   
   ```bash
   cat << EOF > task-definition.json
   {
     "family": "flask-app-task",
     "networkMode": "awsvpc",
     "executionRoleArn": "arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/ecsTaskExecutionRole",
     "containerDefinitions": [
       {
         "name": "flask-app",
         "image": "$(aws sts get-caller-identity --query Account --output text).dkr.ecr.us-east-1.amazonaws.com/flask-crud-app:latest",
         "essential": true,
         "environment": [
           {
             "name": "DATABASE_URL",
             "value": "mysql+pymysql://admin:<password>@<rds-endpoint>:3306/flaskcrud"
           },
           {
             "name": "SECRET_KEY",
             "value": "<random-secret-key>"
           }
         ],
         "portMappings": [
           {
             "containerPort": 8000,
             "hostPort": 8000,
             "protocol": "tcp"
           }
         ],
         "logConfiguration": {
           "logDriver": "awslogs",
           "options": {
             "awslogs-group": "/ecs/flask-app",
             "awslogs-region": "us-east-1",
             "awslogs-stream-prefix": "ecs",
             "awslogs-create-group": "true"
           }
         }
       }
     ],
     "requiresCompatibilities": ["FARGATE"],
     "cpu": "256",
     "memory": "512"
   }
   EOF
   
   # Register the task definition
   aws ecs register-task-definition --cli-input-json file://task-definition.json
   ```

3. Create a load balancer
   
   ```bash
   # Create an ALB
   aws elbv2 create-load-balancer \
     --name flask-app-alb \
     --subnets subnet-**** subnet-**** \
     --security-groups sg-**** \
     --type application
   
   # Create a target group
   aws elbv2 create-target-group \
     --name flask-app-tg \
     --protocol HTTP \
     --port 8000 \
     --vpc-id vpc-**** \
     --target-type ip \
     --health-check-path "/" \
     --health-check-interval-seconds 30 \
     --health-check-timeout-seconds 5 \
     --healthy-threshold-count 2 \
     --unhealthy-threshold-count 2
   
   # Create a listener
   aws elbv2 create-listener \
     --load-balancer-arn arn:aws:elasticloadbalancing:us-east-1:$(aws sts get-caller-identity --query Account --output text):loadbalancer/app/flask-app-alb/**** \
     --protocol HTTP \
     --port 80 \
     --default-actions Type=forward,TargetGroupArn=arn:aws:elasticloadbalancing:us-east-1:$(aws sts get-caller-identity --query Account --output text):targetgroup/flask-app-tg/****
   ```

4. Create an ECS service
   
   ```bash
   aws ecs create-service \
     --cluster flask-app-cluster \
     --service-name flask-app-service \
     --task-definition flask-app-task:1 \
     --desired-count 2 \
     --launch-type FARGATE \
     --network-configuration "awsvpcConfiguration={subnets=[subnet-****,subnet-****],securityGroups=[sg-****],assignPublicIp=DISABLED}" \
     --load-balancers "targetGroupArn=arn:aws:elasticloadbalancing:us-east-1:$(aws sts get-caller-identity --query Account --output text):targetgroup/flask-app-tg/****,containerName=flask-app,containerPort=8000" \
     --deployment-configuration "deploymentCircuitBreaker={enable=true,rollback=true}"
   ```

### 5. Monitoring and Logging

1. View application logs in CloudWatch
   
   ```bash
   aws logs describe-log-groups --log-group-name-prefix /ecs/flask-app
   
   aws logs describe-log-streams \
     --log-group-name /ecs/flask-app \
     --order-by LastEventTime \
     --descending
     
   aws logs get-log-events \
     --log-group-name /ecs/flask-app \
     --log-stream-name <log-stream-name> \
     --limit 20
   ```

2. Monitor the service health
   
   ```bash
   aws ecs describe-services --cluster flask-app-cluster --services flask-app-service
   ```

## Application Access

You can access the Flask CRUD application via the ALB DNS name:

```
http://<alb-dns-name>
```

Replace `<alb-dns-name>` with the actual DNS name of your ALB, which can be retrieved using the following command:

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

For enhanced security, HTTPS was implemented using AWS Certificate Manager:

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

To improve reliability and handle varying loads, auto scaling was configured:

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

For enhanced data protection:

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