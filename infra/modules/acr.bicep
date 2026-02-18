@description('Name of the Azure Container Registry')
param name string

@description('Location for the Azure Container Registry')
param location string

@description('Tags to apply to the Azure Container Registry')
param tags object = {}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: false
    publicNetworkAccess: 'Enabled'
  }
}

@description('Login server for the Azure Container Registry')
output loginServer string = containerRegistry.properties.loginServer

@description('Resource ID of the Azure Container Registry')
output id string = containerRegistry.id

@description('Name of the Azure Container Registry')
output name string = containerRegistry.name
