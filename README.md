# Infrastructure to run the json to parquet api


## how to use:

### open repo in VSCode devcontainer

### Authenticate to azure with Azure Developer CLI:

```bash
azd auth login
```

### Deploy the infra with:

```bash
azd up
```

The infrastructure will be deployed with a dev redis service in Azure Container App.

To deploy a dedicated Azure Redis Cache instance, run the following command:

The REDIS cache is defined as a service binding in the Azure Container App. Necessary environment variables are injected in the container automatically.

### Test the api
run script
```bash
./tests/set-env.sh
```
This script will create a link to the active azd ```.env``` file in the tests folder. The REST client in VSCode will use variable ```API_URL``` to connect to the api.

Tests are defined in file ```./tests/test.http```.

#### Remark
The Azure Containerapp is configured to scale down to 0 when no requests. The first request(s) will fail because the container needs to be started. Subsequent requests will be much faster.

### Cleanup
Delete resource group or remove the infra with azd:
```bash
azd down --purge
```

## Todo
- [ ] Finalize configuration to use a dedicated Azure Redis Cache instead of a development instance (not working at the moment)
- [ ] If an external Redis is used, check if the API can connect to Redis over SSL
- [ ] Check/cleanup monitoring resources deployed by the template (dashboard, appinsights, ...) 