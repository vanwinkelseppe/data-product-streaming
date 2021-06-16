// This template is used to create a Cosmos Database.
targetScope = 'resourceGroup'

// Parameters
param location string
param tags object
param streamanalyticsclusterName string
param streamanalyticsName string
@minValue(36)
@maxValue(216)
param streamanalyticsclusterSkuCapacity int
@allowed([
  1
  3
  6
  12
  18
  24
  30
  36
  42
  48
])
param streamanalyticsjobSkuCapacity int
param storageAccountId string
param sqlServerId string
param eventhubNamespaceId string

// Variables
var storageAccountName = last(split(storageAccountId, '/'))
var sqlServerName = last(split(sqlServerId, '/'))
var eventhubNamespaceName = last(split(eventhubNamespaceId, '/'))
var streamanalyticsclusterManagedPrivateEndpointNameStorageAccount = '${storageAccountName}-private-endpoint'
var streamanalyticsclusterManagedPrivateEndpointNameSqlServer = '${sqlServerName}-private-endpoint'
var streamanalyticsclusterManagedPrivateEndpointNameEventhubNamespace = '${eventhubNamespaceName}-private-endpoint'
var requestMessage = 'Private Endpoint for Stream Analytics Cluster ${streamanalyticscluster.name}'

// Resources
resource streamanalyticscluster 'Microsoft.StreamAnalytics/clusters@2020-03-01-preview' = {
  name: streamanalyticsclusterName
  location: location
  tags: tags
  sku: {
    name: 'Default'
    capacity: streamanalyticsclusterSkuCapacity
  }
  properties: {}
}

resource streamanalyticsclusterManagedPrivateEndpointStorageAccount 'Microsoft.StreamAnalytics/clusters/privateEndpoints@2020-03-01-preview' = if (!empty(storageAccountId)) {
  parent: streamanalyticscluster
  name: streamanalyticsclusterManagedPrivateEndpointNameStorageAccount
  properties: {
    manualPrivateLinkServiceConnections: [
      {
        properties: {
          privateLinkServiceId: storageAccountId
          groupIds: [
            'blob'
          ]
          privateLinkServiceConnectionState: {}
          requestMessage: requestMessage
        }
      }
    ]
  }
}

resource streamanalyticsclusterManagedPrivateEndpointSqlServer 'Microsoft.StreamAnalytics/clusters/privateEndpoints@2020-03-01-preview' = if (!empty(sqlServerId)) {
  parent: streamanalyticscluster
  name: streamanalyticsclusterManagedPrivateEndpointNameSqlServer
  properties: {
    manualPrivateLinkServiceConnections: [
      {
        properties: {
          privateLinkServiceId: sqlServerId
          groupIds: [
            'sqlServer'
          ]
          privateLinkServiceConnectionState: {}
          requestMessage: requestMessage
        }
      }
    ]
  }
}

resource streamanalyticsclusterManagedPrivateEndpointEventhubNamespace 'Microsoft.StreamAnalytics/clusters/privateEndpoints@2020-03-01-preview' = if (!empty(eventhubNamespaceId)) {
  parent: streamanalyticscluster
  name: streamanalyticsclusterManagedPrivateEndpointNameEventhubNamespace
  properties: {
    manualPrivateLinkServiceConnections: [
      {
        properties: {
          privateLinkServiceId: eventhubNamespaceId
          groupIds: [
            'namespace'
          ]
          privateLinkServiceConnectionState: {}
          requestMessage: requestMessage
        }
      }
    ]
  }
}

resource streamanalyticsjob001 'Microsoft.StreamAnalytics/streamingjobs@2017-04-01-preview' = {
  name: streamanalyticsName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    cluster: {
      id: streamanalyticscluster.id
    }
    compatibilityLevel: '1.0'
    // contentStoragePolicy: 'JobStorageAccount'  // Uncomment to store all connection details in storage account
    // jobStorageAccount: {
    //   accountName: storageAccountName
    //   authenticationMode: 'Msi'
    // }
    dataLocale: 'en-US'
    eventsLateArrivalMaxDelayInSeconds: 5
    eventsOutOfOrderMaxDelayInSeconds: 0
    eventsOutOfOrderPolicy: 'Adjust'
    // externals: {  // Uncomment to point to a storage account where custom code artifacts are stored
    //   container: 'mycontainername'
    //   path: 'my/path/to/artifacts'
    //   storageAccount: storageAccountName
    // }
    functions: []
    inputs: []
    outputs: []
    jobType: 'Cloud'
    outputErrorPolicy: 'Stop'
    sku: {
      name: 'Standard'
    }
    transformation: {
      name: 'transformation'
      properties: {
        streamingUnits: streamanalyticsjobSkuCapacity
        query: 'SELECT\r\n    *\r\nINTO\r\n    [YourOutputAlias]\r\nFROM\r\n    [YourInputAlias]'
      }
    }
  }
}

// Outputs
output streamanalyticsjob001Id string = streamanalyticsjob001.id