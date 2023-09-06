param tags object
param scopeName string
@description('Type for resource tags must be applied to')
@allowed(['FunctionApp'])
param scopeType string

resource functionApp 'Microsoft.Web/sites@2022-09-01' existing = if (scopeType == 'FunctionApp') {
  name: scopeName
}

resource tagsResource 'Microsoft.Resources/tags@2022-09-01' = if (scopeType == 'FunctionApp') {
  name: 'default'
  scope: functionApp
  properties: {
    tags: tags
  }
}
