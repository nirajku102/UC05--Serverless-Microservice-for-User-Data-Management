# UC05--Serverless-Microservice-for-User-Data-Management

This repository contains the code and infrastructure for a serverless microservice for user data management. The microservice is built using AWS Lambda, API Gateway, DynamoDB, and Terraform for infrastructure as code.


The Project structurs is 

├── README.md
├── lambda
│   └── user_lambda
│       ├── Dockerfile
│       └── app.py
└── terraform
    ├── dev.tfvars
    ├── main.tf
    ├── modules
    │   └── vpc
    │       ├── main.tf
    │       ├── outputs.tf
    │       └── variables.tf
    ├── outputs.tf
    ├── provider.tf
    └── variables.tf



## Lambda Function

The Lambda function is implemented in [app.py](lambda/user_lambda/app.py). It handles HTTP POST and GET requests to create and retrieve user data from DynamoDB.

### Dockerfile

The [Dockerfile](lambda/user_lambda/Dockerfile) is used to build the Docker image for the Lambda function.

## Terraform

Terraform is used to provision the AWS infrastructure. The main configuration files are located in the [terraform](terraform/) directory.

### Main Terraform Files

- [main.tf](terraform/main.tf): Defines the main infrastructure resources.
- [provider.tf](terraform/provider.tf): Configures the Terraform provider.
- [variables.tf](terraform/variables.tf): Defines the input variables.
- [outputs.tf](terraform/outputs.tf): Defines the output values.

### VPC Module

The VPC module is located in the [modules/vpc](terraform/modules/vpc/) directory and contains the following files:

- [main.tf](terraform/modules/vpc/main.tf): Defines the VPC resources.
- [variables.tf](terraform/modules/vpc/variables.tf): Defines the input variables for the VPC module.
- [outputs.tf](terraform/modules/vpc/outputs.tf): Defines the output values for the VPC module.

## GitHub Actions

The deployment workflow is defined in [deploy.yaml](.github/workflows/deploy.yaml). It builds and pushes the Docker image to Amazon ECR and applies the Terraform configuration.

## Infrastructure Details

### AWS Resources

- **VPC**: A Virtual Private Cloud (VPC) is created with public and private subnets across multiple availability zones.
- **Internet Gateway**: An Internet Gateway is attached to the VPC to allow internet access.
- **NAT Gateway**: A NAT Gateway is created to allow private subnets to access the internet.
- **DynamoDB Table**: A DynamoDB table is created to store user data.
- **Lambda Function**: A Lambda function is created to handle user data management.
- **API Gateway**: An API Gateway is created to expose the Lambda function as a REST API.

### IAM Roles and Policies

- **GitHub Actions Role**: An IAM role is created to allow GitHub Actions to interact with AWS resources.
- **Lambda Execution Role**: An IAM role is created to allow the Lambda function to access DynamoDB and other AWS services.

## Getting Started

### Prerequisites

- AWS account
- Terraform installed
- Docker installed
- AWS CLI configured

### Deployment

1. Clone the repository:

    ```sh
    git clone https://github.com/yourusername/UC05--Serverless-Microservice-for-User-Data-Management.git
    cd UC05--Serverless-Microservice-for-User-Data-Management
    ```

2. Configure GitHub Secrets:

    - `AWS_ACCESS_KEY_ID`: Your AWS access key ID.
    - `AWS_SECRET_ACCESS_KEY`: Your AWS secret access key.
    - `AWS_REGION`: Your AWS region.
    - `AWS_ACCOUNT_ID`: Your AWS account ID.

3. Push changes to the `test-branch` branch to trigger the GitHub Actions workflow.

### Testing the API

Once the deployment is complete, you can test the API using the following endpoints:

- **POST /users**: Create a new user.
    ```sh
    curl -X POST https://<api-id>.execute-api.<region>.amazonaws.com/prod/users \
    -H "Content-Type: application/json" \
    -d '{"name": "John Doe", "email": "john.doe@example.com"}'
    ```

- **GET /users**: Retrieve all users.
    ```sh
    curl -X GET https://<api-id>.execute-api.<region>.amazonaws.com/prod/users
    ```

Replace `<api-id>` and `<region>` with the appropriate values from your API Gateway deployment.

## Outputs

The following outputs are defined in the Terraform configuration:

- **VPC ID**: The ID of the created VPC.
- **Public Subnets**: The IDs of the created public subnets.
- **Private Subnets**: The IDs of the created private subnets.
- **Internet Gateway ID**: The ID of the created Internet Gateway.
- **NAT Gateway ID**: The ID of the created NAT Gateway.
