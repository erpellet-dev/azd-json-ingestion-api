targetScope = 'subscription'

// The main bicep module to provision Azure resources.
// For a more complete walkthrough to understand how this file works with azd,
// see https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/make-azd-compatible?pivots=azd-create

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

// Optional parameters to override the default azd resource naming conventions.
// Add the following to main.parameters.json to provide values:
// "resourceGroupName": {
//      "value": "myGroupName"
// }
param resourceGroupName string = ''

/////////////////////////////////////////////////////////////////////////////////
//
// START - parameters added to the azd-starter-bicep project

param containerAppsEnvironmentName string = ''
param containerRegistryName string = ''
param logAnalyticsName string = ''
param applicationInsightsDashboardName string = ''
param applicationInsightsName string = ''
param apiContainerAppName string = ''
param apiAppExists bool = false
param keyVaultName string = ''
param imageName string
param apiGitRepoUrl string
param storageAccountName string = ''
param storageContainerName string
param enableRedisDevService bool 
param redisProdEnableNonSslPort bool
param redisProdName string = ''

@description('If githuRunnerImage is not empty the acr build task will be skipped')
param dockerImage string = ''

@description('Force docker image rebuild')
param forceDockerImageBuild bool = false

@description('Id of the user or app to assign application roles')
param principalId string = ''

@secure()
@description('Secret value to store in keyVault')
param secretValue string = ''

var kvSecretName = ''

// END - parameters added to the azd-starter-bicep project
//
/////////////////////////////////////////////////////////////////////////////////

var abbrs = loadJsonContent('./abbreviations.json')

// tags that should be applied to all resources.
var tags = {
  // Tag all resources with the environment name.
  'azd-env-name': environmentName
}

// Generate a unique token to be used in naming resources.
// Remove linter suppression after using.
#disable-next-line no-unused-vars
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))

// Name of the service defined in azure.yaml
// A tag named azd-service-name with this value should be applied to the service host resource, such as:
//   Microsoft.Web/sites for appservice, function
// Example usage:
//   tags: union(tags, { 'azd-service-name': apiServiceName })
#disable-next-line no-unused-vars
var apiServiceName = 'python-api'

// Organize resources in a resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}'
  location: location
  tags: tags
}

// Add resources to be provisioned below.
// A full example that leverages azd bicep modules can be seen in the todo-python-mongo template:
// https://github.com/Azure-Samples/todo-python-mongo/tree/main/infra

/////////////////////////////////////////////////////////////////////////////////
//
// START - resources added to the azd-starter-bicep project


module containerApps './custom/host/container-apps.bicep' = {
  name: 'container-apps'
  scope: rg
  params: {
    name: 'app'
    location: location
    tags: tags
    containerAppsEnvironmentName: !empty(containerAppsEnvironmentName) ? containerAppsEnvironmentName : '${abbrs.appManagedEnvironments}${resourceToken}'
    containerRegistryName: !empty(containerRegistryName) ? containerRegistryName : '${abbrs.containerRegistryRegistries}${resourceToken}'
    logAnalyticsWorkspaceName: monitoring.outputs.logAnalyticsWorkspaceName
    applicationInsightsName: monitoring.outputs.applicationInsightsName
  }
}

module uami 'custom/identity/managed-identity.bicep' = {
  scope: rg
  name: 'user-assigned-managed-identity'
  params: {
    location: location
    tags: tags
    identityName: '${abbrs.managedIdentityUserAssignedIdentities}api-${resourceToken}'
  }
}

// storage account to store data
module dataStorage './custom/storage/storage-account.bicep' = {
  scope: rg
  name: 'data-storage-account'
  params: {
    location: location
    name: !empty(storageAccountName) ? storageAccountName : '${abbrs.storageStorageAccounts}data${resourceToken}'
    containers: [
      {
        name: storageContainerName
      }
    ]
  }
}

// redis cache
module redisProd './custom/storage/redis.bicep' = if (!enableRedisDevService) {
  name: 'redis-prod'
  scope: rg
  params: {
    name: !empty(redisProdName) ? redisProdName : '${abbrs.cacheRedis}${resourceToken}'
    location: location
    enableNonSslPort: redisProdEnableNonSslPort
  }
}

module redisProdProperties 'custom/storage/redis-output.bicep' = if (!enableRedisDevService) {
  scope: rg
  name: 'redis-properties'
  params: {
    name:  !enableRedisDevService ? redisProd.outputs.name : ''
  }
}

// API
module api './app/api.bicep' = {
  name: 'api'
  scope: rg
  params: {
    name: !empty(apiContainerAppName) ? apiContainerAppName : '${abbrs.appContainerApps}api-${resourceToken}'
    location: location
    tags: tags
    identityName: uami.outputs.name
    // applicationInsightsName: monitoring.outputs.applicationInsightsName
    containerAppsEnvironmentName: containerApps.outputs.environmentName
    containerRegistryName: containerApps.outputs.registryName
    keyVaultName: kv.name
    // corsAcaUrl: corsAcaUrl
    exists: apiAppExists
    imageName: (empty(dockerImage) || forceDockerImageBuild) ? apiDockerImage.outputs.acrImage : dockerImage
    storageAccountName: dataStorage.outputs.name
    storageContainerName: storageContainerName
    enableRedisDevService: enableRedisDevService
    redisProdName: !enableRedisDevService ? redisProd.outputs.name : ''
  }
}

// Monitor application with Azure Monitor
module monitoring './core/monitor/monitoring.bicep' = {
  name: 'monitoring'
  scope: rg
  params: {
    location: location
    tags: tags
    logAnalyticsName: !empty(logAnalyticsName) ? logAnalyticsName : '${abbrs.operationalInsightsWorkspaces}${resourceToken}'
    applicationInsightsName: !empty(applicationInsightsName) ? applicationInsightsName : '${abbrs.insightsComponents}${resourceToken}'
    applicationInsightsDashboardName: !empty(applicationInsightsDashboardName) ? applicationInsightsDashboardName : '${abbrs.portalDashboards}${resourceToken}'
  }
}

// Create keyvault
module keyVault './core/security/keyvault.bicep' = {
  name: 'keyvault'
  scope: rg
  params: {
    name: !empty(keyVaultName) ? keyVaultName : '${abbrs.keyVaultVaults}${resourceToken}'
    location: location
    tags: tags
    principalId: principalId
  }
}

// Store secret in keyvault
module secret 'core/security/keyvault-secret.bicep' = if (!empty(secretValue)) {
  scope: rg
  name: '${kvSecretName}-secret'
  params: {
    keyVaultName: keyVault.outputs.name
    name: kvSecretName
    secretValue: secretValue
  }
}

#disable-next-line no-unused-existing-resources
resource kv 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  scope: rg
  name: keyVault.outputs.name
}

// build Github runner image
module apiDockerImage 'custom/host/image-build.bicep' = if (empty(dockerImage) || forceDockerImageBuild) {
  scope: rg
  name: '${imageName}-docker-build'
  params: {
    location: location
    containerRegistryName: containerApps.outputs.registryName
    managedIdentityName: uami.outputs.name
    imageName: imageName
    gitRepo: apiGitRepoUrl
    dockerfile: 'Dockerfile'
    dockerfileDirectory: ''
    buildWorkingDirectory : 'src'
  }
}

// END - resources added to the azd-starter-bicep project
//
/////////////////////////////////////////////////////////////////////////////////// Container apps host (including container registry)



// Add outputs from the deployment here, if needed.
//
// This allows the outputs to be referenced by other bicep deployments in the deployment pipeline,
// or by the local machine as a way to reference created resources in Azure for local development.
// Secrets should not be added here.
//
// Outputs are automatically saved in the local azd environment .env file.
// To see these outputs, run `azd env get-values`,  or `azd env get-values --output json` for json output.
output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId


/////////////////////////////////////////////////////////////////////////////////
//
// START - customize output

output APPLICATIONINSIGHTS_CONNECTION_STRING string = monitoring.outputs.applicationInsightsConnectionString
output APPLICATIONINSIGHTS_NAME string = monitoring.outputs.applicationInsightsName
output AZURE_CONTAINER_ENVIRONMENT_NAME string = containerApps.outputs.environmentName
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = containerApps.outputs.registryLoginServer
output AZURE_CONTAINER_REGISTRY_NAME string = containerApps.outputs.registryName
output AZURE_KEY_VAULT_ENDPOINT string = keyVault.outputs.endpoint
output AZURE_KEY_VAULT_NAME string = keyVault.outputs.name
output DOCKER_IMAGE string = apiDockerImage.outputs.acrImage
output REDIS_CACHE_PROD_ENABLE_NON_SSL bool =  !enableRedisDevService ? redisProdProperties.outputs.enableNonSslPort : false
output API_URL string = api.outputs.SERVICE_API_URI
output ENABLE_REDIS_CACHE_DEV bool = enableRedisDevService

// END - customize output
//
/////////////////////////////////////////////////////////////////////////////////

