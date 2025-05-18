# SECURITY WARNING: This script contains database credentials.
# For production use, consider using environment variables or a secure vault.
# Database access script using environment variables
# For security, set these environment variables before running:
# $env:BASTION_HOST, $env:KEY_FILE, $env:DB_HOST, $env:DB_USER, $env:DB_PASS, $env:DB_NAME

# Load environment variables
$BASTION_HOST = $env:BASTION_HOST
$KEY_FILE = $env:KEY_FILE
$DB_HOST = $env:DB_HOST
$DB_USER = $env:DB_USER
$DB_PASS = $env:DB_PASS
$DB_NAME = $env:DB_NAME

# Check if environment variables are set
if (-not $BASTION_HOST -or -not $KEY_FILE -or -not $DB_HOST -or -not $DB_USER -or -not $DB_PASS -or -not $DB_NAME) {
    Write-Host "Error: Required environment variables not set!" -ForegroundColor Red
    Write-Host "Please set the following environment variables:" -ForegroundColor Yellow
    Write-Host "  BASTION_HOST - The bastion host IP address"
    Write-Host "  KEY_FILE - Path to the SSH key file"
    Write-Host "  DB_HOST - Database hostname"
    Write-Host "  DB_USER - Database username"
    Write-Host "  DB_PASS - Database password"
    Write-Host "  DB_NAME - Database name"
    exit 1
}

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