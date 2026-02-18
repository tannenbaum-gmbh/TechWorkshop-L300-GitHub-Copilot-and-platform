# Azure OIDC Authentication Setup for GitHub Actions

This guide explains how to configure OpenID Connect (OIDC) authentication between GitHub Actions and Azure, using a Managed Identity or App Registration with federated credentials. This is required for the **azd-provision** and **azd-down** workflows in this repository.

## Overview

The workflows in `.github/workflows/azd-provision.yml` and `.github/workflows/azd-down.yml` authenticate to Azure using OIDC (federated credentials). This approach is more secure than storing long-lived secrets because no passwords or client secrets are stored in GitHub — instead, GitHub Actions requests a short-lived token from Azure AD at runtime.

## Prerequisites

- An Azure subscription with permissions to create App Registrations or Managed Identities.
- Owner or User Access Administrator role on the target subscription (to assign RBAC roles).
- Admin access to the GitHub repository (to configure variables and environments).

## Step 1: Create an App Registration (Service Principal) in Azure

1. Open the [Azure Portal](https://portal.azure.com/) and navigate to **Microsoft Entra ID** > **App registrations**.
2. Click **New registration**.
3. Enter a name (e.g., `github-actions-azd`) and leave the default settings.
4. Click **Register** and note the following values from the **Overview** page:
   - **Application (client) ID** — this is your `AZURE_CLIENT_ID`
   - **Directory (tenant) ID** — this is your `AZURE_TENANT_ID`

## Step 2: Add a Federated Credential for GitHub Actions

1. In the App Registration, navigate to **Certificates & secrets** > **Federated credentials**.
2. Click **Add credential**.
3. Select **GitHub Actions deploying Azure resources** as the scenario.
4. Fill in the details:
   - **Organization**: Your GitHub organization or username (e.g., `tannenbaum-gmbh`)
   - **Repository**: Your repository name (e.g., `TechWorkshop-L300-GitHub-Copilot-and-platform`)
   - **Entity type**: Select **Environment**
   - **GitHub environment name**: `production`
   - **Name**: A descriptive name (e.g., `github-actions-production`)
5. Click **Add**.

> **Note**: The workflows use the `production` GitHub environment. If you use a different environment name, update both the federated credential entity and the `environment:` field in the workflow YAML files.

## Step 3: Assign Azure RBAC Roles to the Service Principal

The service principal needs permissions to create and delete resources in your Azure subscription.

1. Navigate to your **Azure Subscription** in the Azure Portal.
2. Go to **Access control (IAM)** > **Add role assignment**.
3. Assign the **Contributor** role to the App Registration (search by the application name you created in Step 1).
4. Click **Review + assign**.

> **Tip**: For least-privilege access, you can scope the role assignment to a specific resource group instead of the entire subscription. However, since `azd provision` creates the resource group, subscription-level Contributor access is recommended.

## Step 4: Find Your Azure Subscription ID

1. In the Azure Portal, navigate to **Subscriptions**.
2. Copy the **Subscription ID** for the subscription where resources will be deployed.

## Step 5: Configure GitHub Repository Variables

1. Go to your GitHub repository on GitHub.com.
2. Navigate to **Settings** > **Environments**.
3. Create an environment named `production` (if it doesn't already exist).
4. Under the `production` environment, add the following **environment variables** (not secrets):

   | Variable Name            | Value                              |
   |--------------------------|------------------------------------|
   | `AZURE_CLIENT_ID`        | Application (client) ID from Step 1 |
   | `AZURE_TENANT_ID`        | Directory (tenant) ID from Step 1   |
   | `AZURE_SUBSCRIPTION_ID`  | Subscription ID from Step 4         |

> **Important**: These values are stored as GitHub **variables** (not secrets) because they are non-sensitive identifiers. The actual authentication uses OIDC federated tokens — no client secret is needed.

Alternatively, you can set these as **repository-level variables** under **Settings** > **Secrets and variables** > **Actions** > **Variables** tab, instead of environment-level. Both approaches work with the workflows.

## Step 6: Run the Workflows

### Provision Infrastructure

1. Go to the **Actions** tab in your repository.
2. Select the **Provision Azure Infrastructure (azd)** workflow.
3. Click **Run workflow**.
4. Enter the **environment name** (used by `azd` to name resources, e.g., `dev` or `staging`).
5. Enter the **Azure region** (e.g., `westus3`).
6. Click **Run workflow** to start provisioning.

### Teardown Infrastructure

1. Go to the **Actions** tab in your repository.
2. Select the **Teardown Azure Infrastructure (azd)** workflow.
3. Click **Run workflow**.
4. Enter the **same environment name** used during provisioning.
5. Enter the **same Azure region** used during provisioning.
6. Click **Run workflow** to delete all resources.

> **Warning**: The teardown workflow runs `azd down --purge --force`, which permanently deletes all resources and the resource group. This action is irreversible.

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| `AADSTS70021: No matching federated identity record found` | Verify that the federated credential entity type, organization, repository, and environment name match exactly. |
| `AuthorizationFailed` during provisioning | Ensure the service principal has **Contributor** role on the target subscription. |
| `azd` cannot find environment | Ensure the `AZURE_ENV_NAME` input matches the environment used during provisioning. |
| Workflow does not appear in Actions tab | Ensure the workflow YAML file is on the repository's default branch. |

### Verifying Configuration

You can verify your setup locally by running:

```bash
# Log in with the same service principal
az login --service-principal \
  --username <AZURE_CLIENT_ID> \
  --tenant <AZURE_TENANT_ID> \
  --federated-token <token>

# Check subscription access
az account show
az group list --output table
```
