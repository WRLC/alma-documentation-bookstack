#!/usr/bin/env bash

# Script to sync terraform.tfvars values to GitHub repository secrets
# Install GitHub CLI: `brew install gh`
# Authenticate: `gh auth login`
# Run: `./sync-secrets.sh`

set -e

TFVARS_FILE="terraform/terraform.tfvars"
REPO_DIR="/Users/trb74/projects/alma-documentation-bookstack"

# Check if terraform.tfvars exists
if [[ ! -f "$TFVARS_FILE" ]]; then
    echo "Error: $TFVARS_FILE not found!"
    exit 1
fi

# Check if gh CLI is installed and authenticated
if ! command -v gh &> /dev/null; then
    echo "Error: GitHub CLI (gh) not found. Please install it first."
    exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
    echo "Error: Not authenticated with GitHub CLI. Run 'gh auth login' first."
    exit 1
fi

cd "$REPO_DIR"

echo "Reading terraform.tfvars and creating GitHub secrets..."

# Function to map terraform variable names to GitHub secret names
get_secret_name() {
    case "$1" in
        "azure_service_plan_name") echo "AZURE_SERVICE_PLAN_NAME" ;;
        "azure_service_plan_rg_name") echo "AZURE_SERVICE_PLAN_RG_NAME" ;;
        "azure_mysql_flexible_server_name") echo "AZURE_MYSQL_FLEXIBLE_SERVER_NAME" ;;
        "azure_mysql_flexible_server_rg_name") echo "AZURE_MYSQL_FLEXIBLE_SERVER_RG_NAME" ;;
        "azure_log_analytics_workspace_name") echo "AZURE_LOG_ANALYTICS_WORKSPACE_NAME" ;;
        "azure_log_analytics_workspace_rg_name") echo "AZURE_LOG_ANALYTICS_WORKSPACE_RG_NAME" ;;
        "mysql_admin_username") echo "MYSQL_ADMIN_USERNAME" ;;
        "mysql_admin_password") echo "MYSQL_ADMIN_PASSWORD" ;;
        "bookstack_app_key") echo "BOOKSTACK_APP_KEY" ;;
        "smtp_username") echo "SMTP_USERNAME" ;;
        "smtp_password") echo "SMTP_PASSWORD" ;;
        "mail_from") echo "MAIL_FROM" ;;
        "mail_from_name") echo "MAIL_FROM_NAME" ;;
        "allowed_iframe_source") echo "ALLOWED_IFRAME_SOURCE" ;;
        "app_url") echo "APP_URL" ;;
        "stage_app_url") echo "STAGE_APP_URL" ;;
        *) echo "" ;;
    esac
}

# Parse terraform.tfvars and create secrets
while IFS= read -r line; do
    # Skip comments and empty lines
    if [[ $line =~ ^[[:space:]]*# ]] || [[ -z "${line// }" ]]; then
        continue
    fi
    
    # Extract variable name and value
    if [[ $line =~ ^([^=]+)=(.*)$ ]]; then
        var_name="${BASH_REMATCH[1]// /}"  # Remove spaces
        var_value="${BASH_REMATCH[2]}"
        
        # Remove quotes from value
        # shellcheck disable=SC2001
        var_value=$(echo "$var_value" | sed 's/^[[:space:]]*"\(.*\)"[[:space:]]*$/\1/')
        
        # Check if this variable should be synced to GitHub
        secret_name=$(get_secret_name "$var_name")
        if [[ -n "$secret_name" ]]; then
            echo "Setting secret: $secret_name"
            echo "$var_value" | gh secret set "$secret_name"
        else
            echo "Skipping unknown variable: $var_name"
        fi
    fi
done < "$TFVARS_FILE"

echo "Done! All secrets have been synced to GitHub."
echo ""
echo "You can verify by running: gh secret list"