# Recipe 01

## Objectives
1. Create a CI/CD pipeline for a Node.js web app
2. Create a VM deployment group
3. Register a VM to a VM deployment group
4. Create a CI/CD pipeline task to deploy a Node.js web app to different VM deployment groups
5. Add a trigger to an existing CI/CD pipeline
6. Configure health checks using Azure Traffic Manager

## Setup
**Step 1.** Create a GitHub Personal Access Token (PAT) for Azure DevOps to use and save it as an environment variable. Make sure it expires soon and only has the following scopes checked: `repo`, `admin:repo_hook`, and `user`. 
```bash
export AZURE_DEVOPS_EXT_GITHUB_PAT=""
```

**Step 2.** Create an Azure DevOps PAT with the `Deployment Groups: Read & Manage` and `Release: Read` scopes checked. 
```bash
export DEPLOYMENT_GROUP_PAT="" 
```

**Step 3.** Set other variables. 
```bash
export AZURE_PIPELINE_AGENT_URL_LINUX="https://vstsagentpackage.azureedge.net/agent/3.227.2/vsts-agent-linux-x64-3.227.2.tar.gz"
export DEPLOYMENT_GROUP_PROD="Production"
export DEPLOYMENT_GROUP_QA="QA"
export DEPLOYMENT_GROUP_TAG=""
export PROJECT_ORG=""
export PROJECT_NAME=""
```

**Step 4.** Download the provided source code. If you get a "Permission denied (publickey)" error, make sure you created an SSH key pair and added the public key to your GitHub profile. If the repo doesn't include a CI/CD pipeline file, add it.
```bash
git clone git@github.com:cyberphor/somerepo.git
cd somerepo
```

**Step 5.** Verify you're using the correct Azure subscription.
```bash
az account show
```

**Step 6.** Execute the script provided. 
```bash
bash Start-DevOps.sh
```

## Run Terraform
```bash
cd terraform/
terraform init
terraform plan
terraform apply
export ANSIBLE_USER=$(terraform output admin_username | tr -d '"')
cd ..
```

## Create Your Deployment Groups
Text goes here. 

## Load Your SSH Key Into Memory
```bash
eval "$(ssh-agent -s)" # start the SSH authentication agent
ssh-add ~/.ssh/id_rsa  # add your SSH private key to the SSH authentication agent
```

## Register Virtual Machines as Deployment Group Targets
```bash
cd ansible/
ansible-playbook playbook.yaml -i inventory.yaml --ssh-common-args='-o StrictHostKeyChecking=no'
cd ..
```

## Create a Release Pipeline
Azure DevOps > Projects > (your project)
* Releases
  * Empty job
  * Pipeline name: "Server Release"
* Edit pipeline 
  * Artifacts
    * (after adding an artifact, the source alias will be listed)
      * Source Type: Build
      * Project: (your project)
      * Source (build pipeline): (name of build pipeline; i.e., value stored in `PIPELINE_NAME` environment variable and used in `Start-DevOps.sh` script)
      * Default version: "Latest"
      * Source alias: (keep the default value provided)
      * Continuous deployment trigger
      * Enabled
  * Stages
    * QA 
      * Pre-deployment conditions
        * Triggers: "After release"
      * "Deployment group job" (remove the task added by default)
        * Deployment group: "QA" (should be the same value stored in `DEPLOYMENT_GROUP_QA` environment variable)
        * Additional options:
          * Run this job: "Only when all previous jobs have succeeded"
        * Tasks
          * Bash 
            * Display name: "Bash Script"
            * Type: Inline
            * Script:
              * sudo apt-get update && sudo apt-get install unzip
          * Extract Files
            * Display name: "Extract Files"
            * Archive file patterns: `$(System.DefaultWorkingDirectory)/<artifact-alias>/drop/server.zip` 
            * Destination folder: `$(System.DefaultWorkingDirectory)/<artifact-alias>/drop/server/`
          * Node.js tool installer
            * Version Spec: "10.x"
          * Bash
            * Display name: "Bash Script"
            * Type: Inline
            * Script:
              * cd $(System.DefaultWorkingDirectory)/<artifact-alias>/drop/server/
              * if [ -f ~/pid.txt ]; then kill -9 `cat ~/pid.txt fi`
              * `nohup node app.js >> app.log 2>&1 & 
              * echo $! > ~/pid.txt
        * Variables
          * process.clean = false (By default, when a release is complete, any process or script initiated by the release pipeline is cleaned and stopped. As we are starting the node server process in this release pipeline, we would want it to continue even after the release is complete so that the web app remains running.)
    * Production (clone the "QA" stage)
      * Pre-deployment conditions
        * Triggers: "After stage"
          * Stages: "QA"
        * Pre-deployment approval
          * Approvers: (your email)
      * Deployment group: "Production" (should be the same value stored in `DEPLOYMENT_GROUP_PROD` environment variable)

### References
* [https://stackoverflow.com/questions/75081137/unable-to-create-pipeline-using-azure-devops-cli-in-azure-devops-portal-from-azu](https://stackoverflow.com/questions/75081137/unable-to-create-pipeline-using-azure-devops-cli-in-azure-devops-portal-from-azu)