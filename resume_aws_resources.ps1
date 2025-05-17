# Script to resume AWS resources that were previously paused
# Run this after updating your AWS credentials to resume your infrastructure

Write-Host "===== RESUMING AWS RESOURCES ====="

# 1. Restart ECS Tasks in the flask-app cluster (setting desired count back to 2)
Write-Host "1. Restarting ECS Tasks..."
Write-Host "   aws ecs update-service --cluster flask-app-cluster --service flask-app-service --desired-count 2"
aws ecs update-service --cluster flask-app-cluster --service flask-app-service --desired-count 2

# 2. Start the RDS Database instance
Write-Host "2. Starting RDS Database..."
Write-Host "   aws rds start-db-instance --db-instance-identifier flask-crud-db"
aws rds start-db-instance --db-instance-identifier flask-crud-db

# 3. Start the Bastion Host
Write-Host "3. Starting Bastion Host..."
Write-Host "   Getting Bastion Host instance ID..."
$BASTION_ID = aws ec2 describe-instances --filters "Name=tag:Name,Values=*bastion*" --query "Reservations[0].Instances[0].InstanceId" --output text
if ($BASTION_ID -ne "None" -and $BASTION_ID -ne "") {
    Write-Host "   aws ec2 start-instances --instance-ids $BASTION_ID"
    aws ec2 start-instances --instance-ids $BASTION_ID
} else {
    Write-Host "   No Bastion Host found."
}

Write-Host "`n===== RESOURCES RESUMED SUCCESSFULLY =====" 