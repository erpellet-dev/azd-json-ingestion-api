

param location string = resourceGroup().location


@description('The name of the user-assigned identity')
param managedIdentityName string = ''

@description('The name of the container registry')
param containerRegistryName string = ''

@description('Image name')
param imageName string

@description('Image tag')
param imageTag string = 'latest'


@description('Github repo containing the source code and Dockerfile')
param gitRepo string

@description('Dockerfile name - default Dockerfile')
param dockerfile string = 'Dockerfile'

@description('Dockerfile directory (will be prepended to the Dockerfile name)')
param dockerfileDirectory string = ''

@description('The docker context working directory, change this when your Dockerfile and source files are ALL located in a repo subdirectory')
param buildWorkingDirectory string = ''

module buildRunnerImage 'br/public:deployment-scripts/build-acr:2.0.2' = {
  name: 'build-${imageName}-${imageTag}'
  params: {
    location: location
    AcrName: containerRegistryName
    gitRepositoryUrl: gitRepo
    imageName: imageName
    imageTag: imageTag
    dockerfileName: dockerfile
    cleanupPreference: 'OnSuccess'
    useExistingManagedIdentity: true
    managedIdentityName: managedIdentityName
    dockerfileDirectory: dockerfileDirectory
    buildWorkingDirectory: buildWorkingDirectory
  }
}

output acrImage string = buildRunnerImage.outputs.acrImage
