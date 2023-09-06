// Note: this file is not used and not tested as bicepparam files are not supported yet
// by Azure Developer ACI

using './main-no-redis.bicep'

param environmentName = readEnvironmentVariable('AZURE_ENV_NAME')
param location = readEnvironmentVariable('AZURE_LOCATION')
param imageName = readEnvironmentVariable('IMAGE_NAME', 'ingestionapi')
param apiGitRepoUrl = readEnvironmentVariable('API_GIT_REPO_URL', 'https://github.com/abossard/api-to-parquet')
param dockerImage = readEnvironmentVariable('DOCKER_IMAGE')
param forceDockerImageBuild = bool(readEnvironmentVariable('FORCE_DOCKER_IMAGE_BUILD', 'false'))
param storageContainerName = readEnvironmentVariable('STORAGE_CONTAINER_NAME', 'data')
param redisProdEnableNonSslPort = bool(readEnvironmentVariable('REDIS_PROD_ENABLE_NON_SSL', 'false'))
param enableRedisDevService = bool(readEnvironmentVariable('ENABLE_REDIS_DEV_SERVICE'))


