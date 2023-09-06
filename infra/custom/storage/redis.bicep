param name string
param location string = resourceGroup().location
param tags object = {}
param enableNonSslPort bool


module redis 'br/public:storage/redis-cache:2.0.1' = {
  name: '${uniqueString(deployment().name, location)}-redis-cache'
  params: {
    location: location
    name: name
    tags: tags
    skuName: 'Basic'
    capacity: 1
    enableNonSslPort: enableNonSslPort
  }
}


output hostName string = redis.outputs.hostName
output sslPort string = string(redis.outputs.sslPort)
output name string = redis.outputs.name
