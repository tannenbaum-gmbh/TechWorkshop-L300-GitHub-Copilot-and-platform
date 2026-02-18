@description('Name of the Azure AI Services resource')
param name string

@description('Location for the Azure AI Services resource')
param location string

@description('Tags to apply to the Azure AI Services resource')
param tags object = {}

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

// GPT-4 Model Deployment
resource gpt4Deployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = {
  parent: aiServices
  name: 'gpt-4'
  sku: {
    name: 'Standard'
    capacity: 10
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-4'
      version: 'turbo-2024-04-09'
    }
  }
}

// Phi-4 Model Deployment
resource phi4Deployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = {
  parent: aiServices
  name: 'Phi-4'
  sku: {
    name: 'GlobalStandard'
    capacity: 1
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'Phi-4'
      version: '2'
    }
  }
  dependsOn: [
    gpt4Deployment
  ]
}

@description('Endpoint URL for the Azure AI Services resource')
output endpoint string = aiServices.properties.endpoint

@description('Resource ID of the Azure AI Services resource')
output id string = aiServices.id

@description('Name of the Azure AI Services resource')
output name string = aiServices.name
