locals {
  # Automatically load account-level variables
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  # Automatically load environment-level variables
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  aws_account_id = local.account_vars.locals.aws_account_id
  # Extract out common variables for reuse
  aws_region = local.region_vars.locals.aws_region
}

include {
    path = find_in_parent_folders()
}

terraform {
    source = "git@github.com:terraform-aws-modules/terraform-aws-ecs?ref=v5.11.2"
}

dependency "vpc" {
  config_path = "../vpc"
}

dependency "alb" {
  config_path = "../alb"
}

dependency "ecr_dev" {
    config_path = "../ecr/develop"
}

dependency "ecr_testing" {
    config_path = "../ecr/testing"
}

inputs = {
    cluster_name = "ecs-cluster"

    cluster_configuration = {
        execute_command_configuration = {
            logging = "OVERRIDE"
            log_configuration = {
                cloud_watch_log_group_name = "/aws/ecs/aws-ec2"
            }
        }
    }

    fargate_capacity_providers = {
        FARGATE = {
            default_capacity_provider_strategy = {
                weight = 0
            }
        }
        FARGATE_SPOT = {
            default_capacity_provider_strategy = {
                weight = 100
            }
        }
    }
    create_cloudwatch_log_group = true
    services = {
        frontend-dev = {
            cpu    = 256
            memory = 512

            # Container definition(s)
            container_definitions = {
                frontend-dev = {
                    cpu       = 256
                    memory    = 512
                    essential = true
                    image     = "${dependency.ecr_dev.outputs.repository_url}:latest"
                    port_mappings = [
                        {
                            name          = "frontend-dev"
                            containerPort = 3000
                            protocol      = "tcp"
                        }
                    ]

                    environment: [
                        {
                            "name": "NEXT_PUBLIC_ENVIRONMENT_NAME",
                            "value": "Develop"
                        }
                    ]

                    readonly_root_filesystem = false

                    enable_cloudwatch_logging = true
                    log_configuration = {
                        logDriver = "awslogs"
                            options = {
                                awslogs-group         = "/ecs/frontend/dev"
                                awslogs-region        = local.aws_region
                                awslogs-stream-prefix = "ecs"
                                awslogs-create-group  = "true"
                            }
                    }
                }
            }

            load_balancer = {
                service = {
                    target_group_arn = dependency.alb.outputs.target_groups["dev-instance"].arn
                    container_name   = "frontend-dev"
                    container_port   = 3000
                }
            }

            subnet_ids = dependency.vpc.outputs.private_subnets
            security_group_rules = {
                all_http = {
                    type        = "ingress"
                    from_port   = 3000
                    to_port     = 3000
                    protocol    = "tcp"
                    description = "HTTP web traffic"
                    cidr_blocks = ["0.0.0.0/0"]
                }
                egress_all = {
                    type        = "egress"
                    from_port   = 0
                    to_port     = 0
                    protocol    = "-1"
                    cidr_blocks = ["0.0.0.0/0"]
                }
            }
            
            task_exec_iam_role_policies = {
                "AmazonCloudWatchFullAccess" = "arn:aws:iam::aws:policy/CloudWatchFullAccessV2"
            }
        },
        frontend-testing = {
            cpu    = 256
            memory = 512

            # Container definition(s)
            container_definitions = {
                frontend-testing = {
                    cpu       = 256
                    memory    = 512
                    essential = true
                    image     = "${dependency.ecr_testing.outputs.repository_url}:latest"
                    port_mappings = [
                        {
                            name          = "frontend-testing"
                            containerPort = 3000
                            protocol      = "tcp"
                        }
                    ]

                    environment: [
                        {
                            "name": "NEXT_PUBLIC_ENVIRONMENT_NAME",
                            "value": "Testing"
                        }
                    ]

                    readonly_root_filesystem = false

                    enable_cloudwatch_logging = true
                    log_configuration = {
                        logDriver = "awslogs"
                            options = {
                                awslogs-group         = "/ecs/frontend/testing"
                                awslogs-region        = local.aws_region
                                awslogs-stream-prefix = "ecs"
                                awslogs-create-group  = "true"
                            }
                    }
                }
            }

            load_balancer = {
                service = {
                    target_group_arn = dependency.alb.outputs.target_groups["testing-instance"].arn
                    container_name   = "frontend-testing"
                    container_port   = 3000
                }
            }

            subnet_ids = dependency.vpc.outputs.private_subnets
            security_group_rules = {
                all_http = {
                    type        = "ingress"
                    from_port   = 3000
                    to_port     = 3000
                    protocol    = "tcp"
                    description = "HTTP web traffic"
                    cidr_blocks = ["0.0.0.0/0"]
                }
                egress_all = {
                    type        = "egress"
                    from_port   = 0
                    to_port     = 0
                    protocol    = "-1"
                    cidr_blocks = ["0.0.0.0/0"]
                }
            }
            
            task_exec_iam_role_policies = {
                "AmazonCloudWatchFullAccess" = "arn:aws:iam::aws:policy/CloudWatchFullAccessV2"
            }
        }
    }
}