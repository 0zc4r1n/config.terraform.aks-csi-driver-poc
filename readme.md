# AKS CSI Driver POC

## Description
This is a POC for the AKS CSI Driver using Terraform. It is based on the [AKS CSI Driver](https://learn.microsoft.com/en-us/azure/aks/csi-secrets-store-driver).

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
