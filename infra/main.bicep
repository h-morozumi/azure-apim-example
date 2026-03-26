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

module logAnalytics './modules/log-analytics.bicep' = {
  params: {
    name: '${abbrs.operationalInsightsWorkspaces}${resourceToken}'
    location: location
    tags: tags
  }
}

module appInsights './modules/app-insights.bicep' = {
  params: {
    name: '${abbrs.insightsComponents}${resourceToken}'
    location: location
    workspaceResourceId: logAnalytics.outputs.resourceId
    tags: tags
  }
}

var diagnosticSettings = [
  {
    workspaceResourceId: logAnalytics.outputs.resourceId
    logCategoriesAndGroups: [
      { categoryGroup: 'allLogs' }
    ]
    metricCategories: [
      { category: 'AllMetrics' }
    ]
  }
]

var loggerName = 'appinsights-logger'

var loggers = [
  {
    name: loggerName
    type: 'applicationInsights'
    targetResourceId: appInsights.outputs.resourceId
    credentials: {
      instrumentationKey: appInsights.outputs.instrumentationKey
    }
  }
]

var apis = [
  {
    name: 'custom-echo-api'
    displayName: 'Custom Echo API'
    path: 'custom-echo'
    serviceUrl: 'https://echoapi.cloudapp.net/api'
    protocols: [
      'https'
    ]
    subscriptionRequired: true
    operations: [
      {
        name: 'retrieve-resource'
        displayName: 'Retrieve resource'
        method: 'GET'
        urlTemplate: '/resource'
      }
      {
        name: 'retrieve-resource-cached'
        displayName: 'Retrieve resource (cached)'
        method: 'GET'
        urlTemplate: '/resource-cached'
      }
      {
        name: 'create-resource'
        displayName: 'Create resource'
        method: 'POST'
        urlTemplate: '/resource'
      }
      {
        name: 'modify-resource'
        displayName: 'Modify resource'
        method: 'PUT'
        urlTemplate: '/resource'
      }
      {
        name: 'remove-resource'
        displayName: 'Remove resource'
        method: 'DELETE'
        urlTemplate: '/resource'
      }
      {
        name: 'retrieve-header-only'
        displayName: 'Retrieve header only'
        method: 'HEAD'
        urlTemplate: '/resource'
      }
    ]
  }
  {
    name: 'jsonplaceholder'
    displayName: 'JSONPlaceholder'
    path: 'jsonplaceholder'
    serviceUrl: 'https://jsonplaceholder.typicode.com'
    protocols: [
      'https'
    ]
    subscriptionRequired: true
    operations: [
      {
        name: 'get-posts'
        displayName: 'Get Posts'
        method: 'GET'
        urlTemplate: '/posts'
      }
      {
        name: 'get-post-by-id'
        displayName: 'Get Post by ID'
        method: 'GET'
        urlTemplate: '/posts/{id}'
        templateParameters: [
          {
            name: 'id'
            type: 'integer'
            required: true
          }
        ]
      }
      {
        name: 'create-post'
        displayName: 'Create Post'
        method: 'POST'
        urlTemplate: '/posts'
      }
      {
        name: 'get-users'
        displayName: 'Get Users'
        method: 'GET'
        urlTemplate: '/users'
      }
      {
        name: 'get-comments'
        displayName: 'Get Comments'
        method: 'GET'
        urlTemplate: '/comments'
      }
    ]
  }
]

module apimBasicV2 './modules/api-management.bicep' = {
  params: {
    name: '${abbrs.apiManagementService}basicv2-${resourceToken}'
    location: location
    publisherEmail: publisherEmail
    publisherName: publisherName
    sku: 'BasicV2'
    enableDeveloperPortal: true
    diagnosticSettings: diagnosticSettings
    apis: apis
    loggers: loggers
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
    diagnosticSettings: diagnosticSettings
    apis: apis
    loggers: loggers
    tags: tags
  }
}

output APIM_BASICV2_NAME string = apimBasicV2.outputs.name
output APIM_BASICV2_GATEWAY_URL string = apimBasicV2.outputs.gatewayUrl
output APIM_DEVELOPER_NAME string = apimDeveloper.outputs.name
output APIM_DEVELOPER_GATEWAY_URL string = apimDeveloper.outputs.gatewayUrl
output LOG_ANALYTICS_NAME string = logAnalytics.outputs.name
output APP_INSIGHTS_NAME string = appInsights.outputs.name
