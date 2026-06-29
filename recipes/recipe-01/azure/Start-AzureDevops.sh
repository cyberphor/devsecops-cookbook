# GitHub variables.
export REPO_ORG=""           # ex: cyberphor
export REPO_NAME=""          # ex: devops-bootstraps
export REPO_BRANCH=""        # ex: main

# Azure DevOps project variables.
export PROJECT_ORG=""        # ex: ai2c
export PROJECT_NAME=""       # ex: skynet
export PROJECT_VISIBILITY="" # ex: Private

# Azure DevOps build pipeline variables.
export PIPELINE_NAME="Build and Release"
export PIPELINE_DESCRIPTION="Build and release pipeline"
export PIPELINE_FILE_PATH="azure-pipelines.yml"

# Create an Azure DevOps project. If prompted, enter "Y" to install the "azure-devops" extension. 
function Create-AzureDevOpsProject {
    az devops project create \
        --org "https://dev.azure.com/${PROJECT_ORG}" \
        --name "${PROJECT_NAME}" \
        --visibility "${PROJECT_VISIBILITY}"
}

# Create an Azure DevOps service endpoint connection to GitHub and save the ID to a variable.
function Create-AzureDevOpsServiceEndpointGitHub {
    az devops service-endpoint github create \
        --github-url "https://github.com" \
        --name "GitHub" \
        --org "https://dev.azure.com/${PROJECT_ORG}" \
        --project "${PROJECT_NAME}" \
        --query "id" \
        --output "tsv"
}

# Create a CI/CD pipeline using Azure DevOps a specified configuration file.
function Create-AzureDevOpsPipeline {
    az pipelines create \
        --org "https://dev.azure.com/${PROJECT_ORG}" \
        --project "${PROJECT_NAME}" \
        --repository "${REPO_ORG}/${REPO_NAME}" \
        --repository-type "github" \
        --service-connection $1 \
        --name $2 \
        --yml-path $3 \
        --skip-run
}

# Start the script.
if [ -n "$AZURE_DEVOPS_EXT_GITHUB_PAT" ]; then
    Create-AzureDevOpsProject
    export SERVICE_ENDPOINT_ID=$(Create-AzureDevOpsServiceEndpointGitHub)
    Create-AzureDevOpsPipeline "${SERVICE_ENDPOINT_ID}" "${PIPELINE_NAME}" "${PIPELINE_FILE_PATH}"
else 
    echo "[x] Error: 'AZURE_DEVOPS_EXT_GITHUB_PAT' is not defined."
    echo " 1. Create a GitHub Personal Access Token (PAT) for Azure DevOps to use."
    echo " 2. Save it to an environment variable called 'AZURE_DEVOPS_EXT_GITHUB_PAT'."
fi