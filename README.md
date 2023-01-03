Terraform Script to create Storage Account , Containers and Data Lifecycle Rules at scale in Azure
With wide scale adaptation of IAC, many a times we would need to create storage accounts and corresponding entities dynamically using IAC Scripts.

Here is an article which simplifies this job for Azure Cloud.

This is a utility kind template project, which is configuration driven, flexible and extensible.

This sample project will create storage accounts along with containers and the data lifecycle rules for the data.

Here is the list of items which would be created as part of the script:

1.Storage Accounts

2.Containers

3. Data Lifecycle Rules

The script is flexible and scalable to accommodate any number of storage accounts, containers and data life cycle rules.

The script is configuration driven and based on a variable of type map(map(map))).

First level map represents storage accounts.

Second level map represents the containers inside the respective storage account.

Third level map represents the data life cycle rules under respective container.

Here is the variable format :


Configure as many storage accounts, containers and lifecycle rules as needed and run the IAC script provided in git repo .
