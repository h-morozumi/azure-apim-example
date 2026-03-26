@description('Name of the environment (used for resource naming)')
param environmentName string

@description('Publisher email address for APIM')
param publisherEmail string

@description('Publisher name for APIM')
param publisherName string

@description('Tags for all resources')
param tags object = {}

var abbrs = loadJsonContent('./abbreviations.json')
var location = resourceGroup().location
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))

module apimBasicV2 './modules/api-management.bicep' = {
  params: {
    name: '${abbrs.apiManagementService}basicv2-${resourceToken}'
    location: location
    publisherEmail: publisherEmail
    publisherName: publisherName
    sku: 'BasicV2'
    enableDeveloperPortal: true
    tags: tags
  }
}

module apimDeveloper './modules/api-management.bicep' = {
  params: {
    name: '${abbrs.apiManagementService}dev-${resourceToken}'
    location: location
    publisherEmail: publisherEmail
    publisherName: publisherName
    sku: 'Developer'
    skuCapacity: 1
    enableDeveloperPortal: true
    tags: tags
  }
}

output APIM_BASICV2_NAME string = apimBasicV2.outputs.name
output APIM_BASICV2_GATEWAY_URL string = apimBasicV2.outputs.gatewayUrl
output APIM_DEVELOPER_NAME string = apimDeveloper.outputs.name
output APIM_DEVELOPER_GATEWAY_URL string = apimDeveloper.outputs.gatewayUrl
