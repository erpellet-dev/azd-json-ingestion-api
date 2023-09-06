param name string
param location string = resourceGroup().location
param tags object = {}
param enableRbacAuthorization bool = true
param principalId string = ''

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    tenantId: subscription().tenantId
    sku: { family: 'A', name: 'standard' }
    accessPolicies: !enableRbacAuthorization && !empty(principalId) ? [
      {
        objectId: principalId
        permissions: { secrets: [ 'get', 'list' ] }
        tenantId: subscription().tenantId
      }
    ] : []
    enableRbacAuthorization: enableRbacAuthorization
  }
}

output endpoint string = keyVault.properties.vaultUri
output name string = keyVault.name
