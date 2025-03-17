terraform {
  backend "s3" {
    bucket         = "world-hello-bucket"
    key            = "terraform"
    region         = "eu-west-2"
    encrypt        = true
  }
}