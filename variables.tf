variable "gitguardian_api_key" {
  description = "GitGuardian API key for authentication"
  type        = string
  sensitive   = true
}

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "schedule_expression" {
  description = "EventBridge schedule expression for ggscout execution"
  type        = string
  default     = "rate(1 hour)"
}

variable "scan_regions" {
  description = "List of AWS regions to scan for secrets"
  type        = list(string)
  default     = ["us-east-1", "us-west-2", "eu-west-1", "us-east-2"]
}

variable "environment" {
  description = "Environment label (e.g., development, staging, production)"
  type        = string
  default     = "production"
}

variable "owner_email" {
  description = "Owner email for ggscout configuration"
  type        = string
}

variable "ggscout_image_tag" {
  description = "Container image tag for ggscout"
  type        = string
  default     = "latest"
}
