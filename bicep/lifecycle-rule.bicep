
param ruleType string
param storageAccountName string
param lifecycleRuleName string
param lifecycleRuleInterval int

var BLOB_TYPE_BLOCK_BLOB = 'blockBlob'

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' existing = {
  name: storageAccountName
}

resource managementPolicy 'Microsoft.Storage/storageAccounts/managementPolicies@2021-09-01' = {
  name: 'default'
  parent: storageAccount
  properties: {
    policy: {
      rules: [
        {
          enabled: true
          name: '${lifecycleRuleName}-${ruleType}'
          type: 'Lifecycle'
          definition: {
            actions: {
              baseBlob: {
                tierToCool: ((ruleType == 'cool') ? { daysAfterModificationGreaterThan: lifecycleRuleInterval } : null )
                tierToArchive: ((ruleType == 'archive') ? { daysAfterModificationGreaterThan: lifecycleRuleInterval } : null)
                delete: ((ruleType == 'delete') ? { daysAfterModificationGreaterThan: lifecycleRuleInterval } : null)
              }
            }
            filters: {
              blobTypes: [
                BLOB_TYPE_BLOCK_BLOB
              ]
              prefixMatch: [
                lifecycleRuleName
              ]
            }
          }
        }
      ]
    }
  }
}
