# Setting Up HTTPS for Flask Application in AWS

## Current HTTPS Status

The application has been configured to redirect HTTP traffic to HTTPS (port 443) with the following setup:

1. The Application Load Balancer (ALB) has port 80 (HTTP) configured to redirect to port 443 (HTTPS)
2. The security group for the ALB allows both HTTP (port 80) and HTTPS (port 443) traffic

## Steps to Complete HTTPS Configuration

To properly enable HTTPS for your application, you need to:

1. **Request a Valid Certificate**

   The current certificate request failed because it's using the ELB's domain name. You should request a certificate for a custom domain you own:

   ```
   aws acm request-certificate --domain-name your-domain.com --validation-method DNS
   ```

   Then follow the validation process to verify domain ownership.

2. **Create HTTPS Listener**

   After your certificate is validated, create the HTTPS listener:

   ```
   aws elbv2 create-listener \
     --load-balancer-arn arn:aws:elasticloadbalancing:us-east-1:180116291619:loadbalancer/app/flask-app-alb/327fdafad516af86 \
     --protocol HTTPS \
     --port 443 \
     --certificates CertificateArn=YOUR_CERTIFICATE_ARN \
     --default-actions Type=forward,TargetGroupArn=arn:aws:elasticloadbalancing:us-east-1:180116291619:targetgroup/flask-app-tg/8c6938b0a2a3d5a3
   ```

3. **Register Your Domain with Route 53 and Create an Alias Record**

   ```
   aws route53 create-hosted-zone --name your-domain.com --caller-reference $(date +%s)
   
   aws route53 change-resource-record-sets \
     --hosted-zone-id YOUR_HOSTED_ZONE_ID \
     --change-batch '{
       "Changes": [
         {
           "Action": "CREATE",
           "ResourceRecordSet": {
             "Name": "your-domain.com",
             "Type": "A",
             "AliasTarget": {
               "HostedZoneId": "Z35SXDOTRQ7X7K",
               "DNSName": "flask-app-alb-1035767056.us-east-1.elb.amazonaws.com",
               "EvaluateTargetHealth": true
             }
           }
         }
       ]
     }'
   ```

## Alternative: Self-Signed Certificate for Testing

If you just need HTTPS for testing and don't have a custom domain, you can create a self-signed certificate:

1. Generate a private key and self-signed certificate:
   ```
   openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout private.key -out certificate.crt
   ```

2. Import it to ACM:
   ```
   aws acm import-certificate --certificate fileb://certificate.crt --private-key fileb://private.key
   ```

3. Create the HTTPS listener with this certificate

## Current Configuration

- **Load Balancer DNS Name**: flask-app-alb-1035767056.us-east-1.elb.amazonaws.com
- **HTTP Listener**: Configured to redirect to HTTPS
- **Security Group**: sg-05cc663bffbf71966 (allows both HTTP and HTTPS)

The configuration is ready for HTTPS, it just needs a valid certificate to complete the setup. 