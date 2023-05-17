# AKS CSI Driver POC

## Description
The AKS CSI Driver is a Container Storage Interface (CSI) driver that allows Kubernetes to consume Azure Key Vault secrets as volumes. This POC demonstrates how to use the AKS CSI Driver with Terraform.

## Prerequisites
- Azure Subscription
- Azure CLI

## Infrastructure

This POC will create the following infrastructure:
- Resource Group
- AKS Cluster
- Azure Key Vault
- Azure Instance Identity
- Azure Key Vault Access Policy

## Usage
To deploy the POC, follow these steps:
1. Clone the repository.
2. Run `terraform init` to initialize the Terraform modules.
3. Run `terraform apply` to create the infrastructure.
4. Once the infrastructure is created, you can interact with it by creating a Kubernetes pod that mounts a secret from the Azure Key Vault.

## Limitations
- This POC is not intended for production use.
- The AKS CSI Driver is currently in preview and subject to change.

## Contributing
Contributions are welcome! Please submit a pull request with your changes.

## License
This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.