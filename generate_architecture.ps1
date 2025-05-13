# Generate architecture files script

Write-Host "Generating architecture files..."

# Create directory if it doesn't exist
if (-not (Test-Path -Path "architecture")) {
    New-Item -Path "architecture" -ItemType Directory | Out-Null
}

# Export VPC and networking resources
Write-Host "Exporting VPC and networking resources..."
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=*flask*" | Out-File -FilePath "architecture/vpc.json"

# Get VPC ID
$VPC_ID = (aws ec2 describe-vpcs --filters "Name=tag:Name,Values=*flask*" --query "Vpcs[0].VpcId" --output text)
Write-Host "VPC ID: $VPC_ID"

# Export subnet, route table, and gateway information
aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" | Out-File -FilePath "architecture/subnets.json"
aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID" | Out-File -FilePath "architecture/route_tables.json"
aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID" | Out-File -FilePath "architecture/internet_gateway.json"
aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=$VPC_ID" | Out-File -FilePath "architecture/nat_gateway.json"

# Export security groups
Write-Host "Exporting security groups..."
aws ec2 describe-security-groups --query "SecurityGroups[?contains(GroupName, 'flask') || contains(GroupName, 'bastion')]" | Out-File -FilePath "architecture/security_groups.json"

# Export EC2 instances
Write-Host "Exporting EC2 instances..."
aws ec2 describe-instances --filters "Name=tag:Name,Values=*bastion*" | Out-File -FilePath "architecture/bastion_instance.json"
aws ec2 describe-key-pairs --key-names bastion-key | Out-File -FilePath "architecture/key_pairs.json"

# Export ECS resources
Write-Host "Exporting ECS resources..."
aws ecs describe-clusters --cluster flask-app-cluster | Out-File -FilePath "architecture/ecs_cluster.json"
aws ecs describe-services --cluster flask-app-cluster --services flask-app-service | Out-File -FilePath "architecture/ecs_service.json"
aws ecs describe-task-definition --task-definition flask-app-task | Out-File -FilePath "architecture/task_definition.json"

# Export load balancer resources
Write-Host "Exporting load balancer resources..."
aws elbv2 describe-load-balancers --names flask-app-alb | Out-File -FilePath "architecture/load_balancer.json"
aws elbv2 describe-target-groups --names flask-app-tg | Out-File -FilePath "architecture/target_groups.json"
aws elbv2 describe-target-health --target-group-arn arn:aws:elasticloadbalancing:us-east-1:180116291619:targetgroup/flask-app-tg/8c6938b0a2a3d5a3 | Out-File -FilePath "architecture/target_health.json"
aws elbv2 describe-listeners --load-balancer-arn arn:aws:elasticloadbalancing:us-east-1:180116291619:loadbalancer/app/flask-app-alb/327fdafad516af86 | Out-File -FilePath "architecture/listeners.json"

# Export RDS resources
Write-Host "Exporting RDS resources..."
aws rds describe-db-instances --db-instance-identifier flask-crud-db | Out-File -FilePath "architecture/rds_instance.json"

# Export certificate
Write-Host "Exporting SSL certificate..."
aws acm describe-certificate --certificate-arn arn:aws:acm:us-east-1:180116291619:certificate/001a1aec-a85f-4302-9e37-241f648f57d8 | Out-File -FilePath "architecture/ssl_certificate.json"

# Export CloudWatch logs
Write-Host "Exporting CloudWatch logs..."
aws logs describe-log-groups --log-group-name-prefix /ecs/flask-app | Out-File -FilePath "architecture/cloudwatch_logs.json"

# Generate summary file
Write-Host "Generating architecture summary..."
"===== ARCHITECTURE SUMMARY =====" | Out-File -FilePath "architecture/summary.txt"
"VPC ID:" | Out-File -FilePath "architecture/summary.txt" -Append
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=*flask*" --query "Vpcs[0].VpcId" --output text | Out-File -FilePath "architecture/summary.txt" -Append
"" | Out-File -FilePath "architecture/summary.txt" -Append

"Subnets:" | Out-File -FilePath "architecture/summary.txt" -Append
aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query "Subnets[*].[SubnetId,CidrBlock]" --output table | Out-File -FilePath "architecture/summary.txt" -Append
"" | Out-File -FilePath "architecture/summary.txt" -Append

"Load Balancer DNS:" | Out-File -FilePath "architecture/summary.txt" -Append
aws elbv2 describe-load-balancers --names flask-app-alb --query "LoadBalancers[0].DNSName" --output text | Out-File -FilePath "architecture/summary.txt" -Append
"" | Out-File -FilePath "architecture/summary.txt" -Append

"RDS Endpoint:" | Out-File -FilePath "architecture/summary.txt" -Append
aws rds describe-db-instances --db-instance-identifier flask-crud-db --query "DBInstances[0].Endpoint.Address" --output text | Out-File -FilePath "architecture/summary.txt" -Append

Write-Host "Architecture files generated successfully in the 'architecture' directory." 