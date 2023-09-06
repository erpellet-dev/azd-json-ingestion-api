param name string
param location string = resourceGroup().location
param tags object = {}

param identityName string
param containerAppsEnvironmentName string
param containerRegistryName string
param keyVaultName string
param serviceName string = 'api'
param exists bool
param imageName string
param storageAccountName string
param storageContainerName string
param enableRedisDevService bool
@description('Name of the Azure Redis instance (mandatory if enableRedisDevService is false)')
param redisProdName string = ''

resource apiIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: identityName
  location: location
}

// Give the API access to KeyVault
module apiKeyVaultAccess '../custom/security/role-assignment.bicep' = {
  name: 'api-keyvault-access'
  params: {
    principalId: apiIdentity.properties.principalId
    scopeType: 'KeyVault'
    roleName: 'KeyVaultSecretsUser'
    scopeName: keyVaultName
  }
}

module apiAcrAccess '../custom/security/role-assignment.bicep' = {
  name: 'api-acr-access'
  params: {
    principalId: apiIdentity.properties.principalId
    roleName: 'AcrPull'
    scopeType: 'AzureContainerRegistry'
    scopeName: containerRegistryName
  }
}

module apiStorageBlobDataContributorAccess '../custom/security/role-assignment.bicep' = {
  name: 'api-blobDataContributor-access'
  params: {
    principalId: apiIdentity.properties.principalId
    roleName: 'StorageBlobDataContributor'
    scopeType: 'StorageAccount'
    scopeName: storageAccountName
  }
}




module app '../custom/host/container-app-upsert.bicep' = {
  name: '${serviceName}-container-app'
  dependsOn: [ apiKeyVaultAccess, apiAcrAccess ]
  params: {
    name: name
    location: location
    tags: union(tags, { 'azd-service-name': serviceName })
    identityType: 'UserAssigned'
    identityName: apiIdentity.name
    exists: exists
    containerAppsEnvironmentName: containerAppsEnvironmentName
    containerRegistryName: containerRegistryName
    containerCpuCoreCount: '0.5'
    containerMemory: '1.0Gi'
    env: [
      {
        name: 'STORAGE_ACCOUNT_NAME'
        value: storageAccountName
      }
      {
        name: 'STORAGE_CONTAINER_NAME'
        value: storageContainerName
      }
      {
        name: 'AZURE_CLIENT_ID'
        value: apiIdentity.properties.clientId
      }

    ]
    targetPort: 8080
    imageName: imageName
    containerMinReplicas: 0
    enableRedisDevService: enableRedisDevService
    redisProdName: redisProdName
  }
}

output SERVICE_API_IDENTITY_PRINCIPAL_ID string = apiIdentity.properties.principalId
output SERVICE_API_NAME string = app.outputs.name
output SERVICE_API_URI string = app.outputs.uri
output SERVICE_API_IMAGE_NAME string = app.outputs.imageName
