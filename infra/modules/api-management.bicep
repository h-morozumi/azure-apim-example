@description('Name of the API Management service')
param name string

@description('Location for the resource')
param location string = resourceGroup().location

@description('Publisher email address')
param publisherEmail string

@description('Publisher name')
param publisherName string

@description('SKU of the API Management service')
@allowed([
  'BasicV2'
  'StandardV2'
  'Developer'
  'Basic'
  'Standard'
  'Premium'
  'Consumption'
])
param sku string

@description('SKU capacity (required for non-V2 and non-Consumption SKUs)')
param skuCapacity int?

@description('Enable the Developer Portal')
param enableDeveloperPortal bool = false

@description('Diagnostic settings for the resource')
param diagnosticSettings array?

@description('APIs to create in the APIM instance')
param apis array?

@description('Loggers to configure in the APIM instance')
param loggers array?

@description('Tags for the resource')
param tags object = {}

module apim 'br/public:avm/res/api-management/service:0.14.1' = {
  params: {
    name: name
    location: location
    publisherEmail: publisherEmail
    publisherName: publisherName
    sku: sku
    skuCapacity: skuCapacity ?? (sku == 'Consumption' ? 0 : 1)
    enableDeveloperPortal: enableDeveloperPortal
    diagnosticSettings: diagnosticSettings
    apis: apis
    loggers: loggers
    tags: tags
  }
}

output name string = apim.outputs.name
output resourceId string = apim.outputs.resourceId
output gatewayUrl string = 'https://${apim.outputs.name}.azure-api.net'
