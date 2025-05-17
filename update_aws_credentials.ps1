	# Update your AWS credentials with the values from AWS Learner Lab
# Replace the placeholders with your actual credentials from the lab interface

Write-Host "===== UPDATING AWS CREDENTIALS ====="
Write-Host "Run this script after pasting your AWS credentials from the Learner Lab"

# Set AWS credentials
$env:AWS_ACCESS_KEY_ID = "ASIAST36EQARQORI56ZU"
$env:AWS_SECRET_ACCESS_KEY = "vQ9L1B0SyIkBmm7wuxHJVoLumZSYawCb8EEodKAy"
$env:AWS_SESSION_TOKEN = "IQoJb3JpZ2luX2VjEI7//////////wEaCXVzLXdlc3QtMiJHMEUCIQDvafOcABF7e5wio5hklGwxTN5M9SrNt1wf39Yg3P38/AIgDkB4J1Th1VGuSTPIzH9EWGdFyH9y0HRV26hw9/6K2EcquAIIRxAAGgwxODAxMTYyOTE2MTkiDCazqaAhp/SoWL49SiqVAsjEyfhvLQ5tbJXBQ1Kgk5vR8byhlcZ2Yc8Qq0/fudnj5nGUx4kFB8MjqQDLlv8CiBLKKL4tKH0X5ed+yIJ8QzuadcGsUChSX27pipbQPoGalM3NLA7rNLTwqu/iPspwtxhLICFJ9Mxi9+lxVfPDL/JsahQMw1i3VZsza1ZFah6Uu7frm0fuqpGPIj4d7U15iaxJlNWCcmNQ1X27TEbHbVEPdlhOmNTzujh3uGstld3zLxJ7j5FS7bE+Y51OcdqXt6ZAhQCMEVyzcMXjOT1WEQ8GX9y5pJX5hD4CX6+BCAMSecDEGb7i93RnEp1lfKlIC39ZKSiciqm0/VNDnjoZ73OraOeBINFciXDPxm7YblfczeoNN0owjIedwQY6nQEQK9UWeeKog2PfRF/F1Uquy5jEgug74UEX+JDnJOsSGeEd20OTfM59AOYGaAqHpI9BOKTY5hYakMAinBCWzrLlkSwHgr1D5ujyZU0u6n3VtpfHDYW0f+kNryDfYlNEwcLBTj3ZPPbe3Dp9L8UnrdrWvMi7C9Zb98Xvi9TkMd09WXqxRZvU7pUzZ3yD0k3fkDZkjZdUfsn2wjUQC7Le"
$env:AWS_DEFAULT_REGION = "us-east-1"

# Verify credentials are set
Write-Host "`nCredentials updated! Testing connection..."
aws sts get-caller-identity

Write-Host "`nNow run the pause_aws_resources.ps1 script to stop your AWS resources." 