param location string = resourceGroup().location
param tags object = {}

@description('The name of the user-assigned identity')
param identityName string


// roles
// var contributorRole = {
//   name: 'Contributor'
//   // az role definition list --query "[?roleName=='Contributor'].name" -o tsv
//   roleDefinitionId: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
//   principalType: 'ServicePrincipal'
// }

// var keyVaultAdministratorRole = {
//   name: 'Contributor'
//   // az role definition list --query "[?roleName=='Contributor'].name" -o tsv
//   roleDefinitionId: '00482a5a-887f-4fb3-b363-3b7fe8e74483'
//   principalType: 'ServicePrincipal'
// }

// var acrPushRole = {
//   name: 'AcrPush'
//   // az role definition list --query "[?roleName=='Contributor'].name" -o tsv
//   roleDefinitionId: '8311e382-0749-4cb8-b61a-304f252e45ec'
//   principalType: 'ServicePrincipal'
// }


// create a user assigned managed identity with bicep public registry module
// roles will be assigned to the managed identity at resourceGroup level
module managedIdentity 'br/public:identity/user-assigned-identity:1.0.2' = {
  name: 'ua-managed-identity'
  params: {
    location: location
    name: identityName
    tags: tags
    roles: [
      // keyVaultAdministratorRole
      // acrPushRole
    ]
  }
}  

output id string = managedIdentity.outputs.id
output principalId string = managedIdentity.outputs.principalId
output name string = managedIdentity.outputs.name
output clientId string = managedIdentity.outputs.clientId

