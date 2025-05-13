@echo off
echo Generating architecture files...

REM Create directory if it doesn't exist
mkdir -p architecture

REM Export security groups
echo Exporting security groups...
aws ec2 describe-security-groups --query "SecurityGroups[?contains(GroupName, 'flask') || contains(GroupName, 'bastion')]" > architecture/security_groups.json

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

echo Architecture files generated successfully in the 'architecture' directory. 