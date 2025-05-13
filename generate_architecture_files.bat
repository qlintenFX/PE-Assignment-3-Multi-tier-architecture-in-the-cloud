@echo off
echo Generating architecture files...

REM Create directory if it doesn't exist
mkdir architecture 2>nul

REM Export VPC and networking resources
echo Exporting VPC and networking resources...
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=*flask*" > architecture/vpc.json
aws ec2 describe-subnets --filters "Name=vpc-id,Values=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=*flask*" --query "Vpcs[0].VpcId" --output text)" > architecture/subnets.json
aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=*flask*" --query "Vpcs[0].VpcId" --output text)" > architecture/route_tables.json
aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=*flask*" --query "Vpcs[0].VpcId" --output text)" > architecture/internet_gateway.json
aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=*flask*" --query "Vpcs[0].VpcId" --output text)" > architecture/nat_gateway.json

REM Export security groups
echo Exporting security groups...
aws ec2 describe-security-groups --query "SecurityGroups[?contains(GroupName, 'flask') || contains(GroupName, 'bastion')]" > architecture/security_groups.json

REM Export EC2 instances
echo Exporting EC2 instances...
aws ec2 describe-instances --filters "Name=tag:Name,Values=*bastion*" > architecture/bastion_instance.json
aws ec2 describe-key-pairs --key-names bastion-key > architecture/key_pairs.json

REM Export ECS resources
echo Exporting ECS resources...
aws ecs describe-clusters --cluster flask-app-cluster > architecture/ecs_cluster.json
aws ecs describe-services --cluster flask-app-cluster --services flask-app-service > architecture/ecs_service.json
aws ecs describe-task-definition --task-definition flask-app-task > architecture/task_definition.json

REM Export load balancer resources
echo Exporting load balancer resources...
aws elbv2 describe-load-balancers --names flask-app-alb > architecture/load_balancer.json
aws elbv2 describe-target-groups --names flask-app-tg > architecture/target_groups.json
aws elbv2 describe-target-health --target-group-arn arn:aws:elasticloadbalancing:us-east-1:180116291619:targetgroup/flask-app-tg/8c6938b0a2a3d5a3 > architecture/target_health.json
aws elbv2 describe-listeners --load-balancer-arn arn:aws:elasticloadbalancing:us-east-1:180116291619:loadbalancer/app/flask-app-alb/327fdafad516af86 > architecture/listeners.json

REM Export RDS resources
echo Exporting RDS resources...
aws rds describe-db-instances --db-instance-identifier flask-crud-db > architecture/rds_instance.json

REM Export certificate
echo Exporting SSL certificate...
aws acm describe-certificate --certificate-arn arn:aws:acm:us-east-1:180116291619:certificate/001a1aec-a85f-4302-9e37-241f648f57d8 > architecture/ssl_certificate.json

REM Export CloudWatch logs
echo Exporting CloudWatch logs...
aws logs describe-log-groups --log-group-name-prefix /ecs/flask-app > architecture/cloudwatch_logs.json

REM Generate summary file
echo Generating architecture summary...
echo ===== ARCHITECTURE SUMMARY ===== > architecture/summary.txt
echo VPC ID: >> architecture/summary.txt
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=*flask*" --query "Vpcs[0].VpcId" --output text >> architecture/summary.txt
echo. >> architecture/summary.txt

echo Subnets: >> architecture/summary.txt
aws ec2 describe-subnets --filters "Name=vpc-id,Values=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=*flask*" --query "Vpcs[0].VpcId" --output text)" --query "Subnets[*].[SubnetId,CidrBlock,Tags[?Key=='Name'].Value|[0]]" --output table >> architecture/summary.txt
echo. >> architecture/summary.txt

echo Load Balancer DNS: >> architecture/summary.txt
aws elbv2 describe-load-balancers --names flask-app-alb --query "LoadBalancers[0].DNSName" --output text >> architecture/summary.txt
echo. >> architecture/summary.txt

echo RDS Endpoint: >> architecture/summary.txt
aws rds describe-db-instances --db-instance-identifier flask-crud-db --query "DBInstances[0].Endpoint.Address" --output text >> architecture/summary.txt

echo Architecture files generated successfully in the 'architecture' directory. 