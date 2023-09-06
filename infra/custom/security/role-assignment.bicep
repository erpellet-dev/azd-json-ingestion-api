param principalId string

@allowed([
  'Device'
  'ForeignGroup'
  'Group'
  'ServicePrincipal'
  'User'
])
param principalType string = 'ServicePrincipal'

@description('Type of resource the role must be assigned to')
@allowed(['StorageAccount', 'AzureContainerRegistry', 'KeyVault'])
param scopeType string

@description('Role name (as defined in file roles.json), eg: "AcrPush", "KeyVaultContributor", etc.')
param roleName string

param scopeName string

// load json file containing all built-in roles
// the file is created with the following command (run from root dir of the repo):
// az role definition list --query "[?roleType=='BuiltInRole']"  --output json | jq 'map({(.roleName | gsub(" "; "") | gsub("\\([pP]review\\)"; "_Preview")): {roleDefinitionId: .name, name: .roleName, principalType: "ServicePrincipal"}}) | add' > infra/custom/security/roles.json
var builtInRoles = loadJsonContent('roles.json')
var roleDefinitionId = builtInRoles[roleName].roleDefinitionId

// StorageAccount
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = if (scopeType == 'StorageAccount') {
  name: scopeName
}

resource storageAccountRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (scopeType == 'StorageAccount') {
  name: guid(subscription().id, resourceGroup().id, principalId, roleDefinitionId)
  scope: storageAccount
  properties: {
    principalId: principalId
    principalType: principalType
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
  }
}

// AzureContainerRegistry
resource acr 'Microsoft.ContainerRegistry/registries@2023-06-01-preview' existing = if (scopeType == 'AzureContainerRegistry') {
  name: scopeName
}

resource acrRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (scopeType == 'AzureContainerRegistry') {
  name: guid(subscription().id, resourceGroup().id, principalId, roleDefinitionId)
  scope: acr
  properties: {
    principalId: principalId
    principalType: principalType
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
  }
}

// Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' existing = if (scopeType == 'KeyVault') {
  name: scopeName
}

resource keyVaultRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (scopeType == 'KeyVault') {
  name: guid(subscription().id, resourceGroup().id, principalId, roleDefinitionId)
  scope: keyVault
  properties: {
    principalId: principalId
    principalType: principalType
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
  }
}
