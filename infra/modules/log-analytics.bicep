@description('Name of the Log Analytics workspace')
param name string

@description('Location for the resource')
param location string = resourceGroup().location

@description('SKU of the Log Analytics workspace')
@allowed([
  'Free'
  'PerGB2018'
  'PerNode'
  'Premium'
  'Standalone'
  'Standard'
])
param skuName string = 'PerGB2018'

@description('Data retention in days')
param dataRetention int = 30

@description('Tags for the resource')
param tags object = {}

module logAnalytics 'br/public:avm/res/operational-insights/workspace:0.15.0' = {
  params: {
    name: name
    location: location
    skuName: skuName
    dataRetention: dataRetention
    tags: tags
  }
}

output name string = logAnalytics.outputs.name
output resourceId string = logAnalytics.outputs.resourceId
