# SECURITY WARNING: This script contains database credentials.
# For production use, consider using environment variables or a secure vault.
# Database connection info
$BASTION_HOST="3.92.143.158"
$KEY_FILE="labsuser.pem"
$DB_HOST="flask-crud-db.czyocqcwwzna.us-east-1.rds.amazonaws.com"
$DB_USER="admin"
$DB_PASS="*k62VSj4w6u1vSAxqk6h"
$DB_NAME="flaskcrud"

Write-Host "`n===== CONNECTING TO DATABASE VIA BASTION HOST =====`n" -ForegroundColor Cyan

# Check if key file exists
if (-not (Test-Path $KEY_FILE)) {
    Write-Host "Error: Key file $KEY_FILE not found!" -ForegroundColor Red
    exit 1
}

# Create a single-line command without Windows line endings
$command = "echo '=================== DATABASES ==================='; "
$command += "mysql -h $DB_HOST -u $DB_USER -p'$DB_PASS' -e 'SHOW DATABASES;' || echo 'Error connecting to database'; "
$command += "echo '=================== TABLES IN $DB_NAME ==================='; "
$command += "mysql -h $DB_HOST -u $DB_USER -p'$DB_PASS' -e 'USE $DB_NAME; SHOW TABLES;' || echo 'Error showing tables'; "
$command += "echo '=================== TABLE STRUCTURE ==================='; "
$command += "mysql -h $DB_HOST -u $DB_USER -p'$DB_PASS' -e 'USE $DB_NAME; DESCRIBE entry;' || echo 'Error describing table structure'; "
$command += "echo '=================== TABLE DATA ==================='; "
$command += "mysql -h $DB_HOST -u $DB_USER -p'$DB_PASS' -e 'USE $DB_NAME; SELECT * FROM entry;' || echo 'Error retrieving data'"

try {
    # Execute commands on the bastion host with timeout
    $sshProcess = Start-Process -FilePath "ssh" -ArgumentList "-i $KEY_FILE -o ConnectTimeout=10 -o StrictHostKeyChecking=no ec2-user@$BASTION_HOST $command" -NoNewWindow -PassThru -Wait
    
    if ($sshProcess.ExitCode -ne 0) {
        Write-Host "SSH connection failed with exit code $($sshProcess.ExitCode)" -ForegroundColor Red
    } else {
        Write-Host "`n===== DATABASE QUERY COMPLETE =====`n" -ForegroundColor Green
    }
} catch {
    Write-Host "Error executing SSH command: $_" -ForegroundColor Red
} 