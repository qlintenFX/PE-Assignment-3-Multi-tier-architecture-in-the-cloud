	# Update your AWS credentials with the values from AWS Learner Lab
# Replace the placeholders with your actual credentials from the lab interface

Write-Host "===== UPDATING AWS CREDENTIALS ====="
Write-Host "Run this script after pasting your AWS credentials from the Learner Lab"

# Set AWS credentials
$env:AWS_ACCESS_KEY_ID = "$env:AWS_ACCESS_KEY_ID"
$env:AWS_SECRET_ACCESS_KEY = "$env:AWS_SECRET_ACCESS_KEY"
$env:AWS_SESSION_TOKEN = "$env:AWS_SESSION_TOKEN"
$env:AWS_DEFAULT_REGION = "us-east-1"

# Verify credentials are set
Write-Host "`nCredentials updated! Testing connection..."
aws sts get-caller-identity

Write-Host "`nNow run the pause_aws_resources.ps1 script to stop your AWS resources." 