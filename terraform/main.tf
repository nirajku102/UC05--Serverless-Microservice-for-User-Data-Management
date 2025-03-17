provider "aws" {
  region = "eu-west-2"
}

# OIDC Provider for GitHub
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1" # GitHub's OIDC thumbprint
  ]
}

# IAM Role for GitHub Actions
resource "aws_iam_role" "github_actions_role" {
  name = "github-actions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub" : "repo:nirajku102/UC04-Lamda-deployment:ref:refs/heads/testing-OIDC"
          }
        }
      }
    ]
  })
}



# Attach Policies to the IAM Role
resource "aws_iam_role_policy_attachment" "github_actions_ecr" {
  role       = aws_iam_role.github_actions_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

resource "aws_iam_role_policy_attachment" "github_actions_terraform" {
  role       = aws_iam_role.github_actions_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess" # Adjust this to least privilege
}

resource "aws_dynamodb_table" "ddbtable" {
  name             = "myDB"
  hash_key         = "id"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  attribute {
    name = "id"
    type = "S"
  }
}

module "vpc" {
  source = "./modules/vpc"
  vpc_cidr = var.vpc_cidr
  public_subnets_cidr = var.public_subnets_cidr
  private_subnets_cidr = var.private_subnets_cidr
  availability_zones = var.availability_zones
}

resource "aws_ecr_repository" "create_user" {
  name = "create-user-lambda"
}

resource "aws_ecr_repository" "get_user" {
  name = "get-user-lambda"
}

resource "aws_iam_role" "lambda_exec" {
  name = "hello_world_lambda_exec_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Action": "sts:AssumeRole",
    "Principal": {
      "Service": "lambda.amazonaws.com"
    },
    "Effect": "Allow",
    "Sid": ""
  }]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_vpc_access" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_lambda_function" "create_user" {
  function_name = "create_user"
  package_type  = "Image"
  image_uri     = var.image_uri
  role          = aws_iam_role.lambda_exec.arn

  environment {
    variables = {
      USERS_TABLE = aws_dynamodb_table.users.name
    }
  }
  vpc_config {
    subnet_ids         = module.vpc.private_subnets
    security_group_ids = [aws_security_group.lambda_sg.id]
  }
}

resource "aws_lambda_function" "get_user" {
  function_name = "get_user"
  package_type  = "Image"
  image_uri     = var.image_uri
  role          = aws_iam_role.lambda_exec.arn

  environment {
    variables = {
      USERS_TABLE = aws_dynamodb_table.users.name
  
    }
  }

  vpc_config {
    subnet_ids         = module.vpc.private_subnets
    security_group_ids = [aws_security_group.lambda_sg.id]
  }
}

resource "aws_security_group" "lambda_sg" {
  name        = "lambda_sg"
  description = "Security group for Lambda function"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_api_gateway_rest_api" "users_api" {
  name          = "UsersAPI"
  protocol_type = "HTTP"
  description = "User management API"
}

resource "aws_api_gateway_resource" "users" {
  rest_api_id = aws_api_gateway_rest_api.users_api.id
  parent_id   = aws_api_gateway_rest_api.users_api.id
  path_part   = "users"
}

resource "aws_api_gateway_method" "POST" {
  rest_api_id = aws_api_gateway_rest_api.users_api.id
  resource_id = aws_api_gateway_resource.users.id
  http_method = "POST
  authorization = " NONE"
}

resource "aws_api_gateway_method" "get" {
  rest_api_id = aws_api_gateway_rest_api.users_api.id
  resource_id = aws_api_gateway_resource.users.id
  http_method = "GET
  authorization = " NONE"
}

resource "aws_api_gateway_integration" "post_integration" {
  rest_api_id                   = aws_api_gateway_rest_api.users_api.id
  resource_id                   = aws_api_gateway_rest_api.users.id
  http_method                   = aws_api_gateway_method.get.http_method
  integration_http_method       = "POST"
  type                          = "AWS_PROXY
  integration_uri               = aws_lambda_function.create_user.invoke_arn
}

resource "aws_api_gateway_integration" "get_integration" {
  rest_api_id                   = aws_api_gateway_rest_api.users_api.id
  resource_id                   = aws_api_gateway_rest_api.users.id
  http_method                   = aws_api_gateway_method.get.http_method
  integration_http_method       = "POST"
  type                          = "AWS_PROXY
  integration_uri               = aws_lambda_function.get_user.invoke_arn
}


resource "aws_api_gateway_rest_api_route" "create_user_route" {
  rest_api_id    = aws_api_gateway_rest_api.users.id
  route_key = "$default"
  target    = "integrations/${aws_api_gateway_integration.post_integration.id}"
}

resource "aws_api_gateway_rest_api_route" "get_user_route" {
  rest_api_id    = aws_api_gateway_rest_api.users.id
  route_key = "$default"
  target    = "integrations/${aws_api_gateway_integration.get_integration.id}"
}

resource "aws_api_gateway_rest_api_stage" "default_stage" {
  rest_api_id      = aws_api_gateway_rest_api.http_users.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "apigw_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.create_user.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.http_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "apigww_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_user.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.http_api.execution_arn}/*/*"
}