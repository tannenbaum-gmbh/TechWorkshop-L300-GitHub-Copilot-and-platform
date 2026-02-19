@description('Name of the App Service')
param name string

@description('Location for the App Service resources')
param location string

@description('Tags to apply to the App Service resources')
param tags object = {}

@description('Container Registry login server URL')
param containerRegistryLoginServer string

@description('Container Registry resource ID for RBAC assignment')
param containerRegistryId string

@description('Application Insights connection string')
param appInsightsConnectionString string

@description('Docker image name including tag')
param imageName string = 'zava-storefront:latest'

@description('Azure AI Foundry endpoint URL')
param aiFoundryEndpoint string = ''

@description('Azure AI Services resource ID for Cognitive Services User role assignment')
param aiServicesId string = ''

@description('Azure AI Content Safety endpoint URL (standard Cognitive Services endpoint)')
param contentSafetyEndpoint string = ''

// App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: 'plan-${name}'
  location: location
  tags: tags
  kind: 'linux'
  sku: {
    name: 'B1'
    tier: 'Basic'
  }
  properties: {
    reserved: true
  }
}

// Web App
resource webApp 'Microsoft.Web/sites@2022-09-01' = {
  name: name
  location: location
  tags: tags
  kind: 'app,linux,container'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'DOCKER|${containerRegistryLoginServer}/${imageName}'
      acrUseManagedIdentityCreds: true
      appSettings: [
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://${containerRegistryLoginServer}'
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'WEBSITES_PORT'
          value: '80'
        }
        {
          name: 'AzureAIFoundry__Endpoint'
          value: aiFoundryEndpoint
        }
        {
          name: 'AzureAIFoundry__ModelName'
          value: 'Phi-4-mini-instruct'
        }
        {
          name: 'AzureContentSafety__Endpoint'
          value: contentSafetyEndpoint
        }
      ]
      alwaysOn: true
    }
    httpsOnly: true
  }
}

// Reference the existing ACR for role assignment
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' existing = {
  name: last(split(containerRegistryId, '/'))
}

// Role assignment: Grant "Cognitive Services User" to the Web App managed identity
// This allows the app to make inference calls against Azure AI Services.
resource aiServicesResource 'Microsoft.CognitiveServices/accounts@2023-05-01' existing = if (!empty(aiServicesId)) {
  name: last(split(aiServicesId, '/'))
}

resource cognitiveServicesUserRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(aiServicesId)) {
  name: guid(aiServicesId, webApp.id, 'CognitiveServicesUser')
  scope: aiServicesResource
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'a97b65f3-24c7-4388-baec-2e87135dc908')
    principalId: webApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// Role assignment: Grant AcrPull to Web App's managed identity
resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(containerRegistryId, webApp.id, 'AcrPull')
  scope: containerRegistry
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
    principalId: webApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

@description('Default hostname of the web app')
output defaultHostname string = webApp.properties.defaultHostName

@description('Principal ID of the web app managed identity')
output identityPrincipalId string = webApp.identity.principalId

@description('Name of the web app')
output name string = webApp.name
