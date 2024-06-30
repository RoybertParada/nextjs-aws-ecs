include {
    path = find_in_parent_folders()
}

terraform {
    source = "git@github.com:terraform-aws-modules/terraform-aws-alb?ref=v9.9.0"
}

dependency "vpc" {
  config_path = "../vpc"
}

inputs = {
    name    = "poc-alb"
    vpc_id  = dependency.vpc.outputs.vpc_id
    # Set Subnets from VPC module
    subnets = dependency.vpc.outputs.public_subnets

    # Security Group
    security_group_ingress_rules = {
        all_http = {
            from_port   = 80
            to_port     = 80
            ip_protocol = "tcp"
            description = "HTTP web traffic"
            cidr_ipv4   = "0.0.0.0/0"
        }
        all_https = {
            from_port   = 443
            to_port     = 443
            ip_protocol = "tcp"
            description = "HTTPS web traffic"
            cidr_ipv4   = "0.0.0.0/0"
        }
        http_3000 = {
            from_port   = 3000
            to_port     = 3000
            ip_protocol = "tcp"
            description = "HTTP web traffic"
            cidr_ipv4   = "0.0.0.0/0"
        }
    }
    security_group_egress_rules = {
        all = {
            ip_protocol = "-1"
            cidr_ipv4   = "0.0.0.0/0"
        }
    }

    listeners = {
        dev-instance = {
            port     = 80
            protocol = "HTTP"
            forward = {
                target_group_key = "dev-instance"
            }
        },
        testing-instance = {
            port     = 3000
            protocol = "HTTP"
            forward = {
                target_group_key = "testing-instance"
            }
        }
    }

    target_groups = {
        dev-instance = {
            name_prefix      = "dev"
            protocol         = "HTTP"
            port             = 80
            target_type      = "ip"
            target_id        = "10.0.102.10"

            health_check = {
                enabled             = true
                interval            = 30
                path                = "/"
                port                = 3000
                healthy_threshold   = 3
                unhealthy_threshold = 3
                timeout             = 6
                protocol            = "HTTP"
                matcher             = "200-399"
            }
        },
        testing-instance = {
            name_prefix      = "test"
            protocol         = "HTTP"
            port             = 3000
            target_type      = "ip"
            target_id        = "10.0.102.20"

            health_check = {
                enabled             = true
                interval            = 30
                path                = "/"
                port                = 3000
                healthy_threshold   = 3
                unhealthy_threshold = 3
                timeout             = 6
                protocol            = "HTTP"
                matcher             = "200-399"
            }
        }
    }

    tags = {
        Environment = "NoProd"
        Project     = "PoC"
        Terraform   = "true"
    }
}