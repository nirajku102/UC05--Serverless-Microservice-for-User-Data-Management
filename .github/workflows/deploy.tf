on:
  push:

    branches:
      - main

env:
  AWS_REGION: eu-west-2
  ECR_REPO_APP: ${{ secrets.AWS_ACCOUNT_ID }}.dkr.ecr.eu-west-2.amazonaws.com/lambda

permissions:
  id-token: write
  contents: read

jobs:
  terraform-apply:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: latest
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v3
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ secrets.AWS_REGION }}

      - name: Login to Amazon ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v1

      - name: Generate Unique Image Tag
        run: echo "IMAGE_TAG=$(date +%Y%m%d%H%M%S)" >> $GITHUB_ENV

      - name: Build and Push Docker Image for app
        run: |
          cd app/
          docker build -t app:$IMAGE_TAG .
          docker tag app:$IMAGE_TAG $ECR_REPO_APP:$IMAGE_TAG
          docker push $ECR_REPO_APP:$IMAGE_TAG


      - name: Run Terraform Apply with dev.tfvars and Image URIs
        run: |
          cd terraform
          terraform init
          terraform apply -auto-approve \
            -var-file=dev.tfvars \
            -var="image_uri=$ECR_REPO_APP:$IMAGE_TAG"

          # terraform destroy -auto-approve \
          #   -var-file=dev.tfvars \
          #   -var="image_uri=$ECR_REPO_APP:$IMAGE_TAG"