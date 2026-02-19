@description('Name of the Azure AI Services resource')
param name string

@description('Location for the Azure AI Services resource')
param location string

@description('Tags to apply to the Azure AI Services resource')
param tags object = {}

@description('Resource ID of the Log Analytics workspace for diagnostic settings')
param logAnalyticsWorkspaceId string

// Azure AI Services (AI Foundry)
resource aiServices 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: name
  location: location
  tags: tags
  kind: 'AIServices'
  sku: {
    name: 'S0'
  }
  properties: {
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: false
    customSubDomainName: name
  }
}

// GPT-4.1 Model Deployment
resource gpt41Deployment 'Microsoft.CognitiveServices/accounts/deployments@2024-04-01-preview' = {
  parent: aiServices
  name: 'gpt-4-1'
  sku: {
    name: 'GlobalStandard'
    capacity: 10
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-4.1'
      version: '2025-04-14'
    }
  }
}

// Phi-4 Model Deployment
resource phi4Deployment 'Microsoft.CognitiveServices/accounts/deployments@2024-04-01-preview' = {
  parent: aiServices
  name: 'Phi-4-mini-instruct'
  sku: {
    name: 'GlobalStandard'
    capacity: 1
  }
  properties: {
    model: {
      format: 'Microsoft'
      name: 'Phi-4-mini-instruct'
      version: '1'
    }
  }
  dependsOn: [
    gpt41Deployment
  ]
}

// Diagnostic Settings – send all log and metric categories to Log Analytics
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${aiServices.name}-diagnostics'
  scope: aiServices
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
      {
        categoryGroup: 'audit'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

@description('Endpoint URL for the Azure AI Services resource (standard Cognitive Services)')
output endpoint string = aiServices.properties.endpoint

@description('Model inference endpoint for Azure AI Inference SDK (services.ai.azure.com format)')
output inferenceEndpoint string = 'https://${name}.services.ai.azure.com/models'

@description('Resource ID of the Azure AI Services resource')
output id string = aiServices.id

@description('Name of the Azure AI Services resource')
output name string = aiServices.name
