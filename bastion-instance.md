# Bastion Host Architecture

Our implementation uses a bastion host in a public subnet to securely access the private database:

```
┌─────────────────────────────────────────────────────────────────────────┐
│                             AWS Cloud (us-east-1)                        │
│                                                                          │
│  ┌──────────────────────────────┐         ┌──────────────────────────────┐
│  │      Public Subnet           │         │      Private Subnet          │
│  │      (10.0.1.0/24)           │         │      (10.0.3.0/24)           │
│  │                              │         │                              │
│  │  ┌────────────────────────┐  │         │  ┌────────────────────────┐  │
│  │  │   Bastion Host         │  │         │  │   RDS MySQL            │  │
│  │  │                        │  │         │  │                        │  │
│  │  │   IP: 54.159.110.150   │══════════>│  │   flask-crud-db         │  │
│  │  │   OS: Amazon Linux 2   │  │         │  │   Port: 3306           │  │
│  │  │   Key: labsuser.pem    │  │         │  │   Private Endpoint     │  │
│  │  └────────────────────────┘  │         │  └────────────────────────┘  │
│  │                              │         │                              │
│  └──────────────────────────────┘         └──────────────────────────────┘
│                                                                          │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

This setup allows:
1. SSH access to the bastion host from your workstation
2. The bastion host to connect to the RDS database in the private subnet
3. No direct public access to the database

The `show_database.ps1` script automates the process of connecting through the bastion host to query the database. 