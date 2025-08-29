# BookStack Azure Deployment with Terraform

This Terraform configuration deploys BookStack to Azure App Service with the following resources:

## Resources Created

- **Resource Group**: Container for all BookStack resources
- **MySQL Flexible Server**: Database server for BookStack data
- **MySQL Database**: BookStack database with UTF8MB4 charset
- **Storage Account**: Blob storage for file uploads and images
- **Linux Web App**: App Service running BookStack on PHP 8.2
- **Custom Domain & SSL** (optional): Managed SSL certificate if custom domain provided

## Prerequisites

1. **Azure CLI** installed and authenticated (`az login`)
2. **Terraform** installed (version 1.0+)
3. **Existing App Service Plan** and **Application Insights** workspace
4. **Laravel App Key** generated (run `php artisan key:generate --show` locally)

## Quick Start

1. **Clone and navigate to terraform directory**:
   ```bash
   cd terraform
   ```

2. **Copy and configure variables**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

3. **Initialize and deploy**:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## Configuration

### Required Variables

Edit `terraform.tfvars` with your specific values:

```hcl
# Update with your existing resources
existing_app_service_plan_name   = "your-existing-plan"
existing_app_service_plan_rg     = "your-existing-plan-rg"
existing_application_insights_name = "your-existing-insights"
existing_application_insights_rg   = "your-existing-insights-rg"

# Generate this with: php artisan key:generate --show
app_key = "base64:your-generated-key-here"

# Must be globally unique
storage_account_name = "your-unique-storage-name"
```

### Important Notes

- **Storage Account Name**: Must be 3-24 characters, lowercase letters and numbers only, globally unique
- **App Key**: Generate with Laravel's `php artisan key:generate --show` command
- **MySQL Password**: Use a strong password (letters, numbers, symbols)
- **Custom Domain**: Leave empty if not using a custom domain

## Post-Deployment Steps

After Terraform completes:

1. **Access your app** at the provided URL
2. **Set up deployment** (GitHub Actions, Azure DevOps, etc.)
3. **Create admin user**:
   ```bash
   # SSH into App Service or use Console
   php artisan bookstack:create-admin
   ```

## File Upload Configuration

The deployment uses Azure Blob Storage for file uploads with S3-compatible API:

- **Images**: Stored in blob storage with public access
- **Attachments**: Stored securely in blob storage
- **CORS**: Configured for your domain

## Database

- **MySQL 8.0** Flexible Server
- **UTF8MB4** charset for full Unicode support
- **Automated backups** (7-day retention)
- **Firewall**: Allows Azure services access

## Security Features

- **System-assigned managed identity** for the App Service
- **HTTPS only** with minimum TLS 1.2
- **Application Insights** integration
- **Firewall rules** restricting database access

## Scaling

- **App Service**: Uses your existing App Service Plan
- **MySQL**: Starts with B_Standard_B1s, can be scaled up
- **Storage**: Automatically scales as needed

## Troubleshooting

### Common Issues

1. **Storage account name conflict**: Try a different globally unique name
2. **MySQL connection issues**: Check firewall rules and credentials
3. **App Key errors**: Ensure you generated the key with Laravel

### Useful Commands

```bash
# Check deployment status
terraform show

# View sensitive outputs
terraform output -json

# Update configuration
terraform plan
terraform apply

# Destroy resources (be careful!)
terraform destroy
```

## Cost Optimization

- **MySQL**: Start with B_Standard_B1s ($12-15/month)
- **Storage**: Pay-as-you-go for actual usage
- **App Service**: Uses your existing plan (no additional cost)

## Support

For BookStack-specific issues, refer to the [BookStack documentation](https://www.bookstackapp.com/docs/).

For Azure-specific issues, check the [Azure documentation](https://docs.microsoft.com/azure/).