### Bicep script

Here are the steps to run the bicep script. Prior to running the bicep script, validate the parameter values in the `bicep-params.json` as necessary.

```bash

# verify az account subscription
az account show

# run bicep script
az deployment group create --resource-group <resource-group> --template-file storage-acc.bicep --parameters bicep-params.json

```