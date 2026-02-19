targetScope = 'subscription'

@description('Name of the environment used to generate a short unique hash for resources')
@minLength(1)
@maxLength(64)
param environmentName string

@description('Primary location for all resources')
param location string = 'westus3'

// Generate unique resource names
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var tags = {
  'azd-env-name': environmentName
}

// Create resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-${environmentName}-${location}'
  location: location
  tags: tags
}

// Deploy Azure Container Registry
module acr 'modules/acr.bicep' = {
  name: 'acr-deployment'
  scope: rg
  params: {
    name: 'acr${resourceToken}'
    location: location
    tags: tags
  }
}

// Deploy Application Insights
module appInsights 'modules/appInsights.bicep' = {
  name: 'appinsights-deployment'
  scope: rg
  params: {
    name: 'appi-${environmentName}-${resourceToken}'
    location: location
    tags: tags
  }
}

// Deploy App Service
module appService 'modules/appService.bicep' = {
  name: 'appservice-deployment'
  scope: rg
  params: {
    name: 'app-${environmentName}-${resourceToken}'
    location: location
    tags: tags
    containerRegistryLoginServer: acr.outputs.loginServer
    containerRegistryId: acr.outputs.id
    appInsightsConnectionString: appInsights.outputs.connectionString
    imageName: 'web:latest'
    aiFoundryEndpoint: aiFoundry.outputs.inferenceEndpoint
    aiFoundryApiKey: aiFoundry.outputs.apiKey
  }
}

// Deploy Azure AI Foundry (AI Services)
module aiFoundry 'modules/aiFoundry.bicep' = {
  name: 'aifoundry-deployment'
  scope: rg
  params: {
    name: 'ai-${environmentName}-${resourceToken}'
    location: location
    tags: tags
  }
}

// Outputs required by AZD
output APPLICATIONINSIGHTS_CONNECTION_STRING string = appInsights.outputs.connectionString
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = acr.outputs.loginServer
output SERVICE_WEB_IMAGE_NAME string = appService.outputs.name
output AZURE_LOCATION string = location
output AZURE_RESOURCE_GROUP string = rg.name
output AZURE_AI_FOUNDRY_ENDPOINT string = aiFoundry.outputs.inferenceEndpoint
output AZURE_AI_FOUNDRY_NAME string = aiFoundry.outputs.name
