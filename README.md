# Azure Infrastructure Operations Project: Deploying a scalable IaaS web server in Azure

### Introduction

For this project, you will write a Packer template and a Terraform template to deploy a customizable, scalable web server in Azure.

### Getting Started

1. Clone this repository

2. Set your Environment Variables
    AZURE_SUBSCRIPTION_ID="your Azure Subscription ID"
    AZURE_TENANT_ID="your Azure Tenant ID"
    AZURE_CLIENT_ID="your Azure Client ID"
    AZURE_CLIENT_SECRET="your Azure Client Secret"

### Dependencies

1. Create an [Azure Account](https://portal.azure.com) 
2. Install the [Azure command line interface](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
3. Install [Packer](https://www.packer.io/downloads)
4. Install [Terraform](https://www.terraform.io/downloads.html)

### Instructions

In order to deploy the project you must follow this steps:

1. Create a resource group with following structure \<PREFIX\>-rg. Example: "udacity-c01project-rg"
2. Create the image running the following packer command ```packer build -var 'prefix=<PREFIX>' server.json``` on the command line
3. Check thought the portal or with Azure CLI that image was succesfully created
4. Create terraform solution file with the following command ```terraform plan -out solution.plan  -var 'foo=<PREFIX>'```
IMPORTANT: make sure you are using same \<PREFIX\> used before. You can remove -var flag if you update prefix in the variables.tf
5. Deploy the infraestructure with the following command ```terraform apply solution.plan```

### Output

Once everything is deploy you would see all the resoruces on the created resource group and you can curl or navigate throught the browser to the public IP created and you should see nginx running.
