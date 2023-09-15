## This project provides a solution following enterprise best practices to automate the deployment of an Nginx web server in Azure. 

Terraform is used to deploy the infrastructure to provision the Nginx web server. Azure DevOps is used to create the CI/CD pipeline. The pipeline performs pre commit tests using TFLint, Chekov and Terraform validate to ensure the code is acceptable for production. Once the infrastructure has been created through the pipeline, a bash script is executed on the Virtual Machine to install Nginx and update the desired configuration. Web server file (HTML, CSS, JavaScript,) are pulled on the virtual machine and the web server becomes accessible through the internet.


The following tools are utilized in this project, each with a distinct use case:

|  Tool Name   |  Description  |
| -----------  | ---------------------------------------------  | 
| Azure        | Used to provision Nginx web server |
| Terraform    | Used to automate the deployment of infrastructure (IAC) to Azure |
| Azure DevOps | Used to create CI/CD pipeline to continually build, test and deploy code to production |
| Chekov       | Used to perform static code analysis tool for scanning misconfigurations that may lead to security or compliance problems |
| TFLint       | Used to perform linting that checks possible errors like invalid instance types and syntax |
| Bash Script  | Used to install and add desired configuration to Nginx |


## Azure DevOps:

ADO is used to configure the CI/CD pipeline, host the source code, perform pre commit checks and configure the branch policies to build a seamless workflow from development to production.

Branch policies: 

Only authorized and approved commits should be permitted to be merged to the repository. Tools such as Chekov, TFlint, Terraform Validate and Terraform Plan are used to perform pre-commit checks. These checks will be triggered once a pull request is created. After validating the results of the pre-commit checks, the PR can be approved by authorized users. 

To configure branch policies: Repos > Branches > Branch policies

1) Enable and set minimum number of reviewers as desired
2) Enable Build Validation

![ADO branch policy](https://imgur.com/a/vxrP9WA)

Buid and release pipelines: 

Below 3 pipelines are used in the workflow: 

| YAML file | Description |
| ----------| ---------- |
| WebAppStatusCheck.yml| Pre-commit checks |
| apply.yml | Apply approved terraform plan file |
| destroy.yml | Destroy resources |

## Azure: 

The terraform state file will be stored in a secured blob container. Blob container will be authorized using Service connection and access will be granted to the pipeline using Azure Key Vault. Azure Key Vault will be used to store the secrets which can be passed as variable input during execution of the pipeline.

## TFLint:

TFLint is used to check possible errors with the given providers and identify syntacx error that Terraform Validate may not catch. 

*.tflint.hcl* file is added to the root directory to configure providers and additional inputs. 

```
plugin "azurerm" {
    enabled = true
    version = "0.24.0"
    source  = "github.com/terraform-linters/tflint-ruleset-azurerm"
}
plugin "terraform" {
    enabled = true
    version = "0.2.2"
    preset  = "recommended"
    source  = "github.com/terraform-linters/tflint-ruleset-terraform"
}
```
The following task is used to install, run and save the result of tflint to tflintoutput.txt file: 

```
  - stage: TFLint
    jobs:
      - job: TFLint
        steps:
          - task: CmdLine@2
            inputs:
              script: |
                curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
                tflint --init
                tflint > tflintoutput.txt
```

## Chekov:

Chekov is used to perform static code analysis tool scanning misconfigurations that may lead to security or compliance problems. It can scan .tf files and save the output in a junitxml format to display the result in Test Plans > Runs 

```
  - stage: SecurityCheck
    jobs:
    - job: SecurityCheck
      displayName: Install Checkov
      steps: 
      - script : |
          pip install -U checkov
        displayName: Install Checkov
      - script : |
          checkov \
            --directory . \
            --output junitxml \
            --skip-download \
            --compact \
            --output-file-path $(Agent.TempDirectory) \
            --soft-fail
        displayName: Run Checkov
        workingDirectory: $(System.DefaultWorkingDirectory)
      - task: PublishTestResults@2
        inputs:
          testResultsFormat: 'JUnit'
          testResultsFiles: '**/*results_junitxml.xml'
          searchFolder: $(Agent.TempDirectory)
          testRunTitle: 'Publish Checkov report'
          publishRunAttachments: true 
          failTaskOnFailedTests: false
```



## Terraform:

After initializing the local git repository and writing terraform configuration to provision the required resources, the local configuration files can be merged to a remote repository such as GitHub or Azure Repos. 

The following task initializes, validates and plans the terraform configuration:

```
stages:
  - stage: tfvalidate
    jobs:
      - job: validate
        continueOnError: false 
        steps:
          - task: TerraformInstaller@0
            inputs:
              terraformVersion: '1.5.3'
          - task: TerraformTaskV3@3
            displayName: init
            inputs:
                provider: 'azurerm'
                command: 'init'
                backendServiceArm: 'TFAzureSC'
                backendAzureRmResourceGroupName: 'tfstate'
                backendAzureRmStorageAccountName: 'tfstatestrg0'
                backendAzureRmContainerName: 'tfstatecontainer'
                backendAzureRmKey: 'terraform.tfstate'
          - task: TerraformTaskV3@3
            displayName: validate
            inputs:
                provider: 'azurerm'
                command: 'validate'
          - task: TerraformTaskV3@3
            displayName: plan
            inputs:
                provider: 'azurerm'
                command: 'custom'
                customCommand: 'plan'
                commandOptions: '-out $(Pipeline.Workspace)/tfplan'
                environmentServiceNameAzureRM: 'TFAzureSC'
```
## Bash:

Bash script is used to install and configure the required binaries on the virtual machine. Nginx is configured to use the example.com and index.html files which are pulled from a GitHub repository. 

```
#! /bin/bash
sudo apt install nginx -y
sudo unlink /etc/nginx/sites-enabled/default
# add nginx configuration text file here (done)
cd /etc/nginx/sites-available/
sudo git init
sudo git remote add origin https://github.com/potdartapan/webserver
sudo git fetch origin
sudo git checkout origin/main -- example.com
sudo ln -s /etc/nginx/sites-available/example.com /etc/nginx/sites-enabled/ #link new configuration file
sudo systemctl restart nginx
sudo mkdir /var/www/example.com
#pull index.html and rest of the website files to /var/www/example.com
cd /var/www/example.com
sudo git init
sudo git remote add origin http://github.com/potdartapan/webserver
sudo git fetch origin
sudo git checkout origin/main -- index.html
```

We can execute apply.yml pipeline to provision the resources and deploy Nginx Web Server. Copy and paste the public ip address of the virtual machine into the browser to visit the web server. 

## Conclusion

The above solution successfully automates the provisioning and configuration of Nginx web server on Azure. Terraform is used to provision the infrastructure to cloud. Azure Devops is used to perform pre-commit checks using TFlint and Chekov and to execute the deployment. The web server can be accessed by visiting the public ip address of the virtual machine. Infrastructure can be destroyed using the destroy.yml pipeline to ensure unwanted charges are not accrued.    
