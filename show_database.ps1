# SECURITY WARNING: This script contains database credentials.
# For production use, consider using environment variables or a secure vault.
# Database connection info
$BASTION_HOST="54.159.110.150"
$KEY_FILE="labsuser.pem"
$DB_HOST="flask-crud-db.czyocqcwwzna.us-east-1.rds.amazonaws.com"
$DB_USER="admin"
$DB_PASS="*k62VSj4w6u1vSAxqk6h"
$DB_NAME="flaskcrud"

Write-Host "`n===== CONNECTING TO DATABASE VIA BASTION HOST =====`n" -ForegroundColor Cyan

# Create a single-line command without Windows line endings
$command = "echo '=================== DATABASES ==================='; "
$command += "mysql -h $DB_HOST -u $DB_USER -p'$DB_PASS' -e 'SHOW DATABASES;'; "
$command += "echo '=================== TABLES IN $DB_NAME ==================='; "
$command += "mysql -h $DB_HOST -u $DB_USER -p'$DB_PASS' -e 'USE $DB_NAME; SHOW TABLES;'; "
$command += "echo '=================== TABLE STRUCTURE ==================='; "
$command += "mysql -h $DB_HOST -u $DB_USER -p'$DB_PASS' -e 'USE $DB_NAME; DESCRIBE entry;'; "
$command += "echo '=================== TABLE DATA ==================='; "
$command += "mysql -h $DB_HOST -u $DB_USER -p'$DB_PASS' -e 'USE $DB_NAME; SELECT * FROM entry;'"

# Execute commands on the bastion host
ssh -i $KEY_FILE ec2-user@$BASTION_HOST $command

Write-Host "`n===== DATABASE QUERY COMPLETE =====`n" -ForegroundColor Green 