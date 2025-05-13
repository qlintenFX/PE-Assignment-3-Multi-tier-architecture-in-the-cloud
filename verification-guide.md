# Verification Guide: Multi-AZ Database & Bastion Host

This guide provides step-by-step instructions to verify and demonstrate the implementation of database replication (Multi-AZ) and the bastion host.

## 1. Database Replication (Multi-AZ)

### Verification via AWS Console

1. **Navigate to the RDS Dashboard**:
   - Sign in to AWS Console → Services → RDS
   - Click on "Databases" in the left navigation pane
   - Select the database instance "flask-crud-db"

2. **Verify Multi-AZ Configuration**:
   - In the "Configuration" tab, find "Multi-AZ" which should display "Yes"
   - You can show the "Availability & durability" section showing "Multi-AZ deployment: Yes"

3. **Explain the Benefits**:
   - High availability with automatic failover (typically within 60-120 seconds)
   - Database updates are synchronously replicated to standby instance
   - Backups taken from standby to reduce load on primary
   - Maintenance with minimal downtime (updates applied to standby first)

### Verification via AWS CLI

Run the following command to verify Multi-AZ is enabled:

```bash
aws rds describe-db-instances --db-instance-identifier flask-crud-db --query "DBInstances[0].MultiAZ"
```

Expected output: `true`

For more detailed information:

```bash
aws rds describe-db-instances --db-instance-identifier flask-crud-db --query "DBInstances[0].{DBIdentifier:DBInstanceIdentifier,MultiAZ:MultiAZ,Status:DBInstanceStatus,Endpoint:Endpoint.Address}"
```

Expected output:
```json
{
    "DBIdentifier": "flask-crud-db",
    "MultiAZ": true,
    "Status": "available",
    "Endpoint": "flask-crud-db.czyocqcwwzna.us-east-1.rds.amazonaws.com"
}
```

## 2. Bastion Host Implementation

### Verification via AWS Console

1. **Navigate to EC2 Dashboard**:
   - Sign in to AWS Console → Services → EC2
   - Click on "Instances" in the left navigation pane

2. **Locate the Bastion Host**:
   - Find the instance named "flask-bastion-host"
   - Show that it's running in a public subnet with a public IP address
   - Point out that this is the only way to access the database

3. **Review Security Groups**:
   - Click on the Security tab for the bastion host
   - Show that the security group allows SSH (port 22) access from your IP
   - Navigate to Security Groups and show the database security group
   - Demonstrate that the database security group only allows MySQL (port 3306) connections from the bastion host security group

### Verification via AWS CLI

Check the bastion host details:

```bash
aws ec2 describe-instances --filters "Name=tag:Name,Values=flask-bastion-host" --query "Reservations[0].Instances[0].{InstanceId:InstanceId,State:State.Name,PublicIP:PublicIpAddress,PrivateIP:PrivateIpAddress}"
```

Expected output:
```json
{
    "InstanceId": "i-0e5354f44eda077ed",
    "State": "running",
    "PublicIP": "54.161.0.240",
    "PrivateIP": "10.0.1.38"
}
```

Verify security group rules:

```bash
aws ec2 describe-security-group-rules --filters "Name=group-id,Values=sg-00e90afc8d7effe6f" --query "SecurityGroupRules[?IpProtocol=='tcp' && FromPort==3306]"
```

## 3. Live Demonstration

### Accessing the Database via Bastion Host

1. **Connect to the Bastion Host**:
   ```bash
   # Open PowerShell/Command Prompt
   # First, ensure proper permissions on the key file
   icacls bastion-key-new.pem /inheritance:r
   icacls bastion-key-new.pem /grant:r "$($env:USERNAME):(R,W)"
   
   # Connect to the bastion host
   ssh -i bastion-key-new.pem ec2-user@54.161.0.240
   ```

2. **From the Bastion Host, Connect to the Database**:
   ```bash
   # Once logged into the bastion host
   sudo yum install -y mysql
   
   # Connect to the RDS database
   mysql -h flask-crud-db.czyocqcwwzna.us-east-1.rds.amazonaws.com -u admin -p
   # Enter the database password when prompted: *k62VSj4w6u1vSAxqk6h
   ```

3. **Verify Database Contents**:
   ```sql
   -- Once logged into MySQL
   SHOW DATABASES;
   USE flaskcrud;
   SHOW TABLES;
   SELECT * FROM entry;
   ```

### Demonstrating Security

1. **Try Direct Connection**:
   Show that attempting to connect to the database directly from your local machine fails:
   ```bash
   # From your local machine
   mysql -h flask-crud-db.czyocqcwwzna.us-east-1.rds.amazonaws.com -u admin -p
   # This should fail because the database is only accessible through the bastion host
   ```

2. **Explain the Security Benefits**:
   - The database is in a private subnet, not directly accessible from the internet
   - All database access must go through the bastion host, which acts as a secure gateway
   - Only authorized users with the SSH key can access the bastion host
   - The bastion host can be used to audit and log all database access

## 4. Demonstrating Failover (Optional)

If you want to demonstrate failover (note this will cause a brief interruption):

```bash
aws rds reboot-db-instance --db-instance-identifier flask-crud-db --force-failover
```

After running this command, monitor the RDS console to see the failover process. The database will be unavailable for approximately 60-120 seconds during the failover.

---

Using this verification guide, you can confidently demonstrate both the Multi-AZ database replication and bastion host implementation to your teachers, showing that you've successfully implemented these important features for enhanced security and high availability in your cloud architecture. 