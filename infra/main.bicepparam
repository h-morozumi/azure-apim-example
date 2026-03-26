using './main.bicep'

param environmentName = readEnvironmentVariable('AZURE_ENV_NAME', 'apim-example')
param publisherEmail = readEnvironmentVariable('AZURE_APIM_PUBLISHER_EMAIL', 'admin@example.com')
param publisherName = readEnvironmentVariable('AZURE_APIM_PUBLISHER_NAME', 'Contoso')
param tags = {}
