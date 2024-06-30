#!/bin/bash

set -e  # Terminar el script si ocurre cualquier error

directories=(
  "IaC/infrastructure-live/vpc"
  "IaC/infrastructure-live/alb"
  "IaC/infrastructure-live/ecr/develop"
  "IaC/infrastructure-live/ecr/testing"
  "IaC/infrastructure-live/ecs"
)

for dir in "${directories[@]}"; do
  echo "Applying Terragrunt configuration in $dir"
  cd "$dir"
  terragrunt apply --terragrunt-non-interactive --auto-approve
  cd -  # Volver al directorio anterior
done

cd "IaC/infrastructure-live/github-oidc-provider"
aws cloudformation deploy \
  --template-file configure-aws-credentials-latest.yml \
  --stack-name GithubActionsOIDC \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides GitHubOrg=RoybertParada RepositoryName=nextjs-aws-ecs \
  --region us-east-2

echo "Deployment completed successfully."
