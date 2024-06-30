#!/bin/bash

set -e 

directories=(
    "IaC/infrastructure-live/ecs"
    "IaC/infrastructure-live/ecr/testing"
    "IaC/infrastructure-live/ecr/develop"
    "IaC/infrastructure-live/alb"
    "IaC/infrastructure-live/vpc"
)

for dir in "${directories[@]}"; do
    echo "Destroying Terragrunt configuration in $dir"
    cd "$dir"
    terragrunt init --terragrunt-non-interactive
    terragrunt destroy --terragrunt-non-interactive --auto-approve
    cd - 
done

cd "IaC/infrastructure-live/github-oidc-provider"
echo "Destroying CloudFormation stack GithubActionsOIDC"
aws cloudformation delete-stack --stack-name GithubActionsOIDC --region us-east-2

echo "Destruction completed successfully."
