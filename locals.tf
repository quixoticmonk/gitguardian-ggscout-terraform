locals {
  common_tags = {
    Project     = "ggscout"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
