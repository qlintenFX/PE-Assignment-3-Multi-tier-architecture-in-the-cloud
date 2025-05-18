# Script to sanitize architecture files by replacing 
# sensitive information with placeholders

$directoryPath = "architecture"
$outputPath = "sanitized_architecture"

# Create output directory if it doesn't exist
if (-not (Test-Path -Path $outputPath)) {
    New-Item -ItemType Directory -Path $outputPath
}

Write-Host "Sanitizing architecture files..." -ForegroundColor Cyan

# Get all JSON files in the architecture directory
$files = Get-ChildItem -Path $directoryPath -Filter "*.json"

foreach ($file in $files) {
    Write-Host "Sanitizing $($file.Name)..."
    
    # Read the JSON content
    $content = Get-Content -Path $file.FullName -Raw
    
    # Replace AWS Account ID
    $content = $content -replace "180116291619", "ACCOUNT_ID"
    
    # Replace domain name
    $content = $content -replace "flask\.quinten-de-meyer\.be", "example.domain.com"
    
    # Replace email addresses
    $content = $content -replace "r0984340@student\.thomasmore\.be", "user-email@example.com"
    
    # Replace RDS endpoint
    $content = $content -replace "flask-crud-db\.czyocqcwwzna\.us-east-1\.rds\.amazonaws\.com", "database-host.region.rds.amazonaws.com"
    
    # Replace load balancer DNS
    $content = $content -replace "flask-app-alb-[0-9]+\.us-east-1\.elb\.amazonaws\.com", "load-balancer.region.elb.amazonaws.com"
    
    # Replace bastion host IP
    $content = $content -replace "3\.92\.143\.158", "XX.XX.XX.XX"
    $content = $content -replace "98\.83\.119\.96", "XX.XX.XX.XX"
    
    # Replace NAT Gateway IP
    $content = $content -replace "52\.7\.199\.129", "XX.XX.XX.XX"
    
    # Replace resource IDs with placeholders
    $content = $content -replace "subnet-[0-9a-f]+", "subnet-EXAMPLE"
    $content = $content -replace "vpc-[0-9a-f]+", "vpc-EXAMPLE"
    $content = $content -replace "sg-[0-9a-f]+", "sg-EXAMPLE"
    $content = $content -replace "rtb-[0-9a-f]+", "rtb-EXAMPLE"
    $content = $content -replace "igw-[0-9a-f]+", "igw-EXAMPLE"
    $content = $content -replace "nat-[0-9a-f]+", "nat-EXAMPLE"
    $content = $content -replace "eni-[0-9a-f]+", "eni-EXAMPLE"
    $content = $content -replace "i-[0-9a-f]+", "i-EXAMPLE"
    $content = $content -replace "ami-[0-9a-f]+", "ami-EXAMPLE"
    $content = $content -replace "eipalloc-[0-9a-f]+", "eipalloc-EXAMPLE"
    
    # Replace certificate IDs
    $content = $content -replace "001a1aec-a85f-4302-9e37-241f648f57d8", "CERTIFICATE_ID"
    
    # Replace key IDs
    $content = $content -replace "760da15f-6165-41d8-8ad5-6bd300f0edf3", "KEY_ID"

    # Replace validation records
    $content = $content -replace "_3ad15fd5bb8c5315a325db6ee520558b", "_VALIDATION_ID"
    $content = $content -replace "_6540e96a83ba0ffc6e4b22b8551b4f42\.xlfgrmvvlj", "_VALIDATION_VALUE"
    
    # Replace load balancer IDs
    $content = $content -replace "327fdafad516af86", "LOAD_BALANCER_ID"
    
    # Write the sanitized content to the output directory
    $content | Out-File -FilePath "$outputPath\$($file.Name)" -Encoding utf8
}

Write-Host "Architecture files have been sanitized and saved to $outputPath" -ForegroundColor Green 