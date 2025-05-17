# Script to pause AWS resources to prevent further costs
# Run this to pause all resources that might be costing money in your AWS learner lab

Write-Host "===== PAUSING AWS RESOURCES ====="

# 1. Stop ECS Tasks in the flask-app cluster
Write-Host "1. Stopping ECS Tasks..."
Write-Host "   aws ecs update-service --cluster flask-app-cluster --service flask-app-service --desired-count 0"
aws ecs update-service --cluster flask-app-cluster --service flask-app-service --desired-count 0

# 2. Stop the RDS Database instance
Write-Host "2. Stopping RDS Database..."
Write-Host "   aws rds stop-db-instance --db-instance-identifier flask-crud-db"
aws rds stop-db-instance --db-instance-identifier flask-crud-db

# 3. Stop the Bastion Host
Write-Host "3. Stopping Bastion Host..."
Write-Host "   Getting Bastion Host instance ID..."
$BASTION_ID = aws ec2 describe-instances --filters "Name=tag:Name,Values=*bastion*" --query "Reservations[0].Instances[0].InstanceId" --output text
if ($BASTION_ID -ne "None" -and $BASTION_ID -ne "") {
    Write-Host "   aws ec2 stop-instances --instance-ids $BASTION_ID"
    aws ec2 stop-instances --instance-ids $BASTION_ID
} else {
    Write-Host "   No Bastion Host found."
}

# 4. Release any Elastic IPs (optional - uncomment if needed)
# Write-Host "4. Releasing unused Elastic IPs..."
# $ELASTIC_IPS = aws ec2 describe-addresses --query "Addresses[?AssociationId==null].AllocationId" --output text
# if ($ELASTIC_IPS -ne "") {
#     foreach ($EIP in $ELASTIC_IPS.Split()) {
#         Write-Host "   aws ec2 release-address --allocation-id $EIP"
#         aws ec2 release-address --allocation-id $EIP
#     }
# } else {
#     Write-Host "   No unassociated Elastic IPs found."
# }

Write-Host "`n===== RESOURCES THAT CANNOT BE EASILY PAUSED ====="
Write-Host "The following resources will continue to incur costs until deleted:"
Write-Host "1. Application Load Balancer (ALB)"
Write-Host "2. NAT Gateway"
Write-Host "3. Database storage (even when stopped)"

Write-Host "`nTo fully stop all costs, you would need to delete these resources."
Write-Host "WARNING: Deleting these resources will require recreating them when you want to use the application again."
Write-Host "Consider creating a CloudFormation template to easily redeploy your infrastructure when needed."

Write-Host "`n===== RESOURCES PAUSED SUCCESSFULLY =====" 