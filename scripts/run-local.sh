#!/usr/bin/env bash
# run-local.sh
# Retrieves Azure AI Foundry credentials from the deployed environment and
# starts the ZavaStorefront application locally.
#
# Prerequisites:
#   - Azure CLI (az) installed and logged in
#   - Azure Developer CLI (azd) installed with an environment configured
#   - .NET 10 SDK installed
#
# Usage:
#   bash scripts/run-local.sh [azd-env-name]
#
# The azd environment name defaults to "twl300" if not provided.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SRC_DIR="$REPO_ROOT/src"
AZD_ENV_NAME="${1:-twl300}"

echo "==> Checking Azure login..."
if ! az account show &>/dev/null; then
  echo "   Not logged in. Starting az login..."
  az login --use-device-code --tenant msft.flow-soft.com
fi

echo "==> Using azd environment: $AZD_ENV_NAME"
cd "$REPO_ROOT"

# Set the azd environment if not already set
azd env select "$AZD_ENV_NAME" 2>/dev/null || true

echo "==> Refreshing azd environment values from Azure..."
azd env refresh --no-prompt 2>/dev/null || true

# Try to read values from azd environment
AI_NAME=$(azd env get-values --output json 2>/dev/null | jq -r '.AZURE_AI_FOUNDRY_NAME // empty')
RESOURCE_GROUP=$(azd env get-values --output json 2>/dev/null | jq -r '.AZURE_RESOURCE_GROUP // empty')
AI_ENDPOINT=$(azd env get-values --output json 2>/dev/null | jq -r '.AZURE_AI_FOUNDRY_ENDPOINT // empty')

# Fall back to discovering the resource via az if azd values are missing
if [[ -z "$AI_NAME" || -z "$RESOURCE_GROUP" ]]; then
  echo "   azd values not found, discovering AI Services resource via az CLI..."
  SUBSCRIPTION=$(az account show --query id -o tsv)
  # Find any CognitiveServices account with kind=AIServices tagged for this environment
  FOUND=$(az cognitiveservices account list \
    --subscription "$SUBSCRIPTION" \
    --query "[?kind=='AIServices'] | [0].{name:name, rg:resourceGroup, endpoint:properties.endpoint}" \
    -o json 2>/dev/null || echo "[]")

  AI_NAME=$(echo "$FOUND" | jq -r '.name // empty')
  RESOURCE_GROUP=$(echo "$FOUND" | jq -r '.rg // empty')

  if [[ -z "$AI_NAME" ]]; then
    echo "ERROR: Could not find an Azure AI Services (AIServices) resource in your subscription."
    echo "Have you run 'azd provision' yet? Or specify the correct azd environment name as an argument."
    exit 1
  fi
fi

# Construct the inference endpoint if not already set
if [[ -z "$AI_ENDPOINT" ]]; then
  AI_ENDPOINT="https://${AI_NAME}.services.ai.azure.com/"
fi

echo "==> Retrieving API key for AI Services resource: $AI_NAME (rg: $RESOURCE_GROUP)"
AI_KEY=$(az cognitiveservices account keys list \
  --name "$AI_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --query "key1" -o tsv)

if [[ -z "$AI_KEY" ]]; then
  echo "ERROR: Could not retrieve the API key for $AI_NAME."
  exit 1
fi

echo ""
echo "==> Configuration retrieved:"
echo "    Endpoint  : $AI_ENDPOINT"
echo "    Model     : Phi-4-mini-instruct"
echo "    Key       : ${AI_KEY:0:8}...  (truncated)"
echo ""

echo "==> Starting ZavaStorefront on https://localhost:5001 ..."
echo "    Press Ctrl+C to stop."
echo ""

cd "$SRC_DIR"
export AzureAIFoundry__Endpoint="$AI_ENDPOINT"
export AzureAIFoundry__ApiKey="$AI_KEY"
export AzureAIFoundry__ModelName="Phi-4-mini-instruct"
export ASPNETCORE_ENVIRONMENT="Development"

dotnet run
