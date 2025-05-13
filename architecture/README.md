# Flask CRUD App Architecture Documentation

This directory contains JSON files that document the AWS architecture of the Flask CRUD application. These files are automatically generated using the `generate_architecture_files.bat` script at the root of the project.

## Architecture Overview

The application follows a multi-tier architecture with the following components:

- **Frontend**: Load balancer handling HTTP and HTTPS traffic
- **Middle Tier**: ECS Fargate cluster running Flask application
- **Backend**: RDS MySQL database

Additionally, the application is secured with SSL certificates and proper DNS configuration.

## JSON Files

### 1. Summary (`summary.json`)
Contains a high-level overview of the architecture and lists all components.

### 2. ECS Resources
- **ECS Cluster** (`ecs_cluster.json`): Details of the Fargate cluster
- **ECS Service** (`ecs_service.json`): Service configuration, deployment settings, and task counts
- **Task Definition** (`task_definition.json`): Container definitions, resource requirements, and configurations

### 3. Load Balancer Resources
- **Load Balancer** (`load_balancer.json`): ALB configuration, DNS name, and availability zones
- **Target Groups** (`target_groups.json`): Target group configurations
- **Target Health** (`target_health.json`): Health status of targets in the target group
- **Listeners** (`listeners.json`): Listener configurations, including HTTP to HTTPS redirection

### 4. Database Resources
- **RDS Instance** (`rds_instance.json`): Database instance configuration, endpoint, and status

### 5. Security Resources
- **Security Groups** (`security_groups.json`): Security group configurations, ingress and egress rules
- **SSL Certificate** (`ssl_certificate.json`): SSL certificate details, validation status, and domain name

## Keeping Documentation Updated

These files should be regenerated whenever changes are made to the infrastructure. To update the documentation, run:

```
.\generate_architecture_files.bat
```

## Accessing the Application

The application is accessible at: https://flask.quinten-de-meyer.be 