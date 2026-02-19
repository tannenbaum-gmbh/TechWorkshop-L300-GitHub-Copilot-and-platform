@description('Name of the Azure Workbook resource')
param name string

@description('Location for the Workbook resource')
param location string

@description('Tags to apply to the Workbook resource')
param tags object = {}

@description('Resource ID of the Log Analytics workspace used as the data source')
param logAnalyticsWorkspaceId string

// Load the workbook definition from the companion JSON file
var workbookContent = loadTextContent('workbook.json')

// Replace the placeholder token with the actual Log Analytics workspace resource ID
var serializedContent = replace(workbookContent, '__LOG_ANALYTICS_WORKSPACE_ID__', logAnalyticsWorkspaceId)

resource workbook 'Microsoft.Insights/workbooks@2023-06-01' = {
  name: guid(resourceGroup().id, name)
  location: location
  tags: tags
  kind: 'shared'
  properties: {
    displayName: 'AI Services Observability'
    category: 'workbook'
    sourceId: logAnalyticsWorkspaceId
    serializedData: serializedContent
  }
}

@description('Resource ID of the deployed Workbook')
output id string = workbook.id

@description('Display name of the deployed Workbook')
output displayName string = workbook.properties.displayName
