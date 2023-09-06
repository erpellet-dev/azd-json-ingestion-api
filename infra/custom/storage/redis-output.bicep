param name string


resource redis 'Microsoft.Cache/redis@2023-05-01-preview' existing = {
  name: name
}


output enableNonSslPort bool = redis.properties.enableNonSslPort
