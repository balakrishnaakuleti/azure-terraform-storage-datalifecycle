@description('Azure location where storage account should be created.')
param location string

@description('SKU tier of storage account.')
param skuName string = 'Standard_LRS'

@description('Kind of storage account.')
@allowed([
  'BlobStorage'
  'BlockBlobStorage'
  'FileStorage'
  'Storage'
  'StorageV2'
])
param storageAccountKind string = 'StorageV2'

@description('Access Tier of storage account.')
@allowed([
  'Cool'
  'Hot'
  'Premium'
])
param accessTier string = 'Hot'

@description('Whether to enable HierarchicalNamespace for storage account.')
param isHnsEnabled bool = true

@description('Whether to enable NFS 3.0 protocol support for storage account.')
param nfsv3Enabled bool = false

@description('Whether to enable last access time tracking on the storage account.')
param lastAccessTrackingEnabled bool = true

@description('Env that storage account is deployed in.')
param resourceEnv string = 'dev'

@description('Storage accounts to be created')
param storageAccountNames array

@description('Storage account containers to be created')
param storageAccountContainerNames object

@description('Cool Management policies to be created')
param coolManagementPolicies object

@description('Archive management policies to be created')
param archiveManagementPolicies object

@description('Delete management policies to be created')
param deleteManagementPolicies object

var fullStorageAccountNames = [for (name, idx) in storageAccountNames: {
  name: name
  fullName: '${name}${uniqueString(resourceGroup().id)}${resourceEnv}'
}]

var storageAccountIndices = [for (name, idx) in storageAccountNames: {
  name: name
  index: idx
}]

var storageAccountNameMapping = reduce(fullStorageAccountNames, {}, (prev, cur) => union(prev, { '${cur.name}': cur.fullName }))
var storageAccountIndexMapping = reduce(storageAccountIndices, {}, (prev, cur) => union(prev, { '${cur.name}': cur.index }))

var containerStorageAccounts = [for ctr in items(storageAccountContainerNames): {
  container: ctr.key
  storageAccName: storageAccountNameMapping[ctr.value]
}]

var containerStorageAccNameMapping = reduce(containerStorageAccounts, {}, (prev, cur) => union(prev, { '${cur.container}': cur.storageAccName }))

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' = [for namePair in items(storageAccountNameMapping): {
  name: namePair.value
  location: location
  sku: {
    name: skuName
  }
  kind: storageAccountKind
  properties: {
    accessTier: accessTier
    isHnsEnabled: isHnsEnabled
    isNfsV3Enabled: nfsv3Enabled
  }
}]

resource blobServices 'Microsoft.Storage/storageAccounts/blobServices@2022-05-01' = [for (name, idx) in items(storageAccountNameMapping): {
  name: 'default'
  parent: storageAccount[idx]
  properties: {
    lastAccessTimeTrackingPolicy: {
      blobType: [
        'string'
      ]
      enable: lastAccessTrackingEnabled
      name: 'AccessTimeTracking'
    }
  }
}]

resource storageAccContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-09-01' = [for sacItem in items(storageAccountContainerNames): {
  name: sacItem.key
  parent: blobServices[storageAccountIndexMapping[sacItem.value]]
}]

module coolLifecyclePolicies 'lifecycle-rule.bicep' = [for policy in items(coolManagementPolicies): {
  name: '${policy.key}-cool'
  params: {
    ruleType: 'cool'
    storageAccountName: containerStorageAccNameMapping[policy.key]
    lifecycleRuleName: policy.key
    lifecycleRuleInterval: policy.value
  }
  dependsOn: [
    storageAccContainer
  ]
}]

module archiveLifecyclePolicies 'lifecycle-rule.bicep' = [for policy in items(archiveManagementPolicies): {
  name: '${policy.key}-archive'
  params: {
    ruleType: 'archive'
    storageAccountName: containerStorageAccNameMapping[policy.key]
    lifecycleRuleName: policy.key 
    lifecycleRuleInterval: policy.value
  }
  dependsOn: [
    storageAccContainer
  ]
}]

module deleteLifecyclePolicies 'lifecycle-rule.bicep' = [for policy in items(deleteManagementPolicies): {
  name: '${policy.key}-delete'
  params: {
    ruleType: 'delete'
    storageAccountName: containerStorageAccNameMapping[policy.key]
    lifecycleRuleName: policy.key
    lifecycleRuleInterval: policy.value
  }
  dependsOn: [
    storageAccContainer
  ]
}]
