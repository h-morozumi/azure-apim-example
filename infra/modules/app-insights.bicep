@description('Name of the Application Insights resource')
param name string

@description('Location for the resource')
param location string = resourceGroup().location

@description('Resource ID of the Log Analytics workspace')
param workspaceResourceId string

@description('Tags for the resource')
param tags object = {}

module appInsights 'br/public:avm/res/insights/component:0.7.1' = {
  params: {
    name: name
    location: location
    workspaceResourceId: workspaceResourceId
    tags: tags
  }
}

output name string = appInsights.outputs.name
output resourceId string = appInsights.outputs.resourceId
output instrumentationKey string = appInsights.outputs.instrumentationKey
output connectionString string = appInsights.outputs.connectionString
