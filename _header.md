# terraform-azurerm-avm-res-datafactory

This module deploys an Azure Data Factory (Version 2) resource, following the [Azure Verified Modules](https://azure.github.io/Azure-Verified-Modules/) specification for Terraform resource modules.

## Features

- Azure Data Factory factory resource with full attribute coverage
- Optional GitHub or Azure DevOps (VSTS) source control integration
- Global parameters support
- Managed Identity (System-assigned and/or User-assigned)
- Managed Virtual Network support
- Customer-Managed Key (CMK) encryption
- Microsoft Purview integration
- Self-hosted Integration Runtime (via AzAPI)
- Linked Services: Azure Blob Storage, Azure File Storage, Azure SQL Database, Azure Data Lake Storage Gen2, Azure Databricks, Azure Key Vault, CosmosDB MongoDB API
- CosmosDB MongoDB API Dataset (via AzAPI)
- Service Principal and User-Assigned Managed Identity credentials
- Private Endpoints with optional DNS zone group management
- Diagnostic Settings
- Role Assignments
- Resource Lock
