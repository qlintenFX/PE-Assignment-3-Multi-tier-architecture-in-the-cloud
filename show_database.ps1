# =====================================
# Database Access Script via Bastion Host
# =====================================
# This script connects to the RDS MySQL database via the bastion host
# It demonstrates secure access to private resources in AWS
# Author: Quinten De Meyer
# =====================================

# Database connection configuration
$BASTION_HOST="98.83.119.96"  # Public IP of bastion host
$KEY_FILE="bastion-key-new.pem"  # SSH private key for bastion host
$DB_HOST="flask-crud-db.czyocqcwwzna.us-east-1.rds.amazonaws.com"  # RDS endpoint
$DB_USER="admin"  # Database username
$DB_PASS="*k62VSj4w6u1vSAxqk6h"  # Database password
$DB_NAME="flaskcrud"  # Database name

# Function to check if a file exists and exit if not
function Test-FileExists {
    param (
        [string]$Path,
        [string]$Description
    )
    
    if (-not (Test-Path $Path)) {
        Write-Host "ERROR: $Description not found at path: $Path" -ForegroundColor Red
        Write-Host "Please ensure the file exists in the correct location" -ForegroundColor Yellow
        exit 1
    }
}

# Verify SSH key exists
Test-FileExists -Path $KEY_FILE -Description "SSH key file"

# Display connection information
Write-Host "`n===== CONNECTING TO DATABASE VIA BASTION HOST =====`n" -ForegroundColor Cyan
Write-Host "Bastion Host: $BASTION_HOST" -ForegroundColor Cyan
Write-Host "Database: $DB_HOST" -ForegroundColor Cyan
Write-Host "User: $DB_USER" -ForegroundColor Cyan
Write-Host "Database Name: $DB_NAME" -ForegroundColor Cyan

# Create a single-line command without Windows line endings
$command = "echo '=================== DATABASES ==================='; "
$command += "mysql -h $DB_HOST -u $DB_USER -p'$DB_PASS' -e 'SHOW DATABASES;' 2>/dev/null || echo 'ERROR: Could not connect to database'; "
$command += "echo '=================== TABLES IN $DB_NAME ==================='; "
$command += "mysql -h $DB_HOST -u $DB_USER -p'$DB_PASS' -e 'USE $DB_NAME; SHOW TABLES;' 2>/dev/null || echo 'ERROR: Could not query tables'; "
$command += "echo '=================== TABLE STRUCTURE ==================='; "
$command += "mysql -h $DB_HOST -u $DB_USER -p'$DB_PASS' -e 'USE $DB_NAME; DESCRIBE entry;' 2>/dev/null || echo 'ERROR: Could not describe table structure'; "
$command += "echo '=================== TABLE DATA ==================='; "
$command += "mysql -h $DB_HOST -u $DB_USER -p'$DB_PASS' -e 'USE $DB_NAME; SELECT * FROM entry;' 2>/dev/null || echo 'ERROR: Could not query table data'"

# Execute commands on the bastion host with error handling
try {
    # Make the SSH key permissions secure
    if ($PSVersionTable.Platform -ne 'Unix') {
        # Windows needs specific permissions
        icacls $KEY_FILE /inheritance:r
        icacls $KEY_FILE /grant:r "$($env:USERNAME):(R)"
    } else {
        # Linux/macOS permissions
        chmod 600 $KEY_FILE
    }
    
    # Connect via SSH to bastion host and execute command
    Write-Host "`nExecuting query through bastion host... Please wait.`n" -ForegroundColor Yellow
    $sshResult = $null
    $sshResult = ssh -i $KEY_FILE -o "StrictHostKeyChecking=no" -o "ConnectTimeout=10" ec2-user@$BASTION_HOST $command
    
    # Display results
    if ($sshResult) {
        Write-Host $sshResult
        Write-Host "`n===== DATABASE QUERY COMPLETE =====`n" -ForegroundColor Green
    } else {
        Write-Host "`nNo results returned from database query." -ForegroundColor Yellow
    }
} catch {
    Write-Host "`n===== ERROR CONNECTING TO BASTION HOST =====`n" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host "`nTroubleshooting tips:" -ForegroundColor Yellow
    Write-Host "1. Ensure the bastion host is running and the IP is correct" -ForegroundColor Yellow
    Write-Host "2. Verify the SSH key path is correct and has proper permissions" -ForegroundColor Yellow
    Write-Host "3. Check if your local network allows SSH connections (port 22)" -ForegroundColor Yellow
    Write-Host "4. Ensure the bastion host security group allows SSH from your IP" -ForegroundColor Yellow
}

# End of script 