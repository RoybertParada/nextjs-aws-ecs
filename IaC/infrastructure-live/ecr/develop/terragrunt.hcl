include {
    path = find_in_parent_folders()
}

terraform {
    source = "git@github.com:terraform-aws-modules/terraform-aws-ecr?ref=v2.2.1"
}

inputs = {
    repository_name = "frontend-ecr-dev"
    repository_force_delete = true
    repository_lifecycle_policy = jsonencode({
        rules = [
            {
                rulePriority = 1,
                description  = "Keep last 30 images",
                selection = {
                    tagStatus     = "tagged",
                    tagPrefixList = ["v"],
                    countType     = "imageCountMoreThan",
                    countNumber   = 30
                },
                action = {
                    type = "expire"
                }
            }
        ]
    })

    tags = {
        Environment = "dev"
        Terraform   = "true"
    }
}