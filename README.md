<!-- BEGIN_TF_DOCS -->
# GitGuardian ggscout Terraform Infrastructure

Terraform configuration that deploys GitGuardian ggscout on AWS using ECS Fargate and EventBridge for scheduled scanning.

## What is ggscout?

GitGuardian Scout (ggscout) is a command-line application that collects secrets and their metadata from your Secrets Managers and synchronizes this data with your GitGuardian platform. It creates an inventory of secrets stored in AWS Secrets Manager, hashes them locally using the HMSL algorithm (secrets never leave your infrastructure in clear text), and reconciles this inventory with secrets detected by GitGuardian.

### Key Capabilities

1. **Extend Detection Coverage**: Detect when vaulted secrets are compromised elsewhere in your perimeter
2. **Improve Incident Prioritization**: Use vault metadata (paths, lease times, environments) to prioritize remediation
3. **Bootstrap Incident Remediation**: Identify and secure unvaulted secrets by pushing them to your Secrets Manager

### AWS Secrets Manager Integration

This deployment configures ggscout to:
- Scan AWS Secrets Manager for secrets inventory
- Hash secrets locally using HMSL algorithm for secure transmission
- Collect metadata like secret names, paths, creation dates, and lease times
- Send hashed data to GitGuardian for reconciliation with detected incidents

**Note**: This deployment is configured in **read-only mode**. The capability to push unvaulted secrets back to Secrets Manager requires additional write permissions and configuration.

### NHI Governance Capabilities

ggscout supports GitGuardian's Non-Human Identity (NHI) governance by providing visibility into:

**Identity Management**
![NHI Identities](./images/nhi\_identities.png)

**Secret Inventory & Tracking**
![NHI Inventory](./images/nhi\_inventory.png)

**AWS Secrets Manager Integration**
![Integration Secrets Manager](./images/integration\_secrets\_manager.png)

**Custom Inventory Views**
![NHI Custom View](./images/nhi\_custom\_view.png)

**Policy Breach Detection**
![NHI Breached Policies](./images/nhi\_breached\_policies.png)

**Secret Hygiene Monitoring**
![NHI Secret Hygiene](./images/nhi\_secret\_hygiene.png)

## Architecture

- **ECS Fargate**: Runs the ggscout container on a scheduled basis
- **EventBridge**: Triggers ggscout execution based on configurable schedule
- **Secrets Manager**: Secure storage for GitGuardian API key and target for secret scanning
- **CloudWatch**: Logging and monitoring for task execution
- **VPC & Networking**: Isolated network environment with NAT Gateway for secure outbound access

## Prerequisites

1. **AWS CLI** configured with appropriate permissions
2. **Terraform** >= 1.0
3. **GitGuardian API Key** - Obtain from [GitGuardian Dashboard](https://dashboard.gitguardian.com/)

## Documentation

- [What is ggscout?](https://docs.gitguardian.com/ggscout-docs/what-is-ggscout)
- [AWS Secrets Manager Integration](https://docs.gitguardian.com/ggscout-docs/integrations/secret-managers/aws-secrets-manager)

## Quick Start

1. **Deploy**:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

2. **Monitor**:
   - Check CloudWatch logs for ggscout execution
   - View task status in ECS console

## Usage

### Configuration

1. **Set variables** in `terraform.tfvars`:
   ```hcl
   gitguardian_api_key = "your-gitguardian-api-key"
   owner_email        = "admin@example.com"
   aws_region          = "us-east-1"
   scan_regions       = ["us-east-1", "us-west-2", "eu-west-1"]
   schedule_expression = "rate(1 hour)"
   environment        = "production"
   ```

2. **Deploy**:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_event_rule.ggscout_schedule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.ggscout_target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_cloudwatch_log_group.ggscout](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_ecs_cluster.ggscout](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster) | resource |
| [aws_ecs_task_definition.ggscout](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_efs_file_system.ggscout_config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_file_system) | resource |
| [aws_efs_mount_target.ggscout_config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_mount_target) | resource |
| [aws_eip.nat](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_iam_role.ecs_execution_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.eventbridge_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.ggscout_task_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.ecs_execution_secrets_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.eventbridge_ecs_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.ggscout_secrets_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.ecs_execution_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_internet_gateway.ggscout](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_nat_gateway.ggscout](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway) | resource |
| [aws_route_table.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_secretsmanager_secret.gitguardian_api_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_version.gitguardian_api_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [aws_security_group.efs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.ggscout](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_subnet.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.ggscout](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
| [random_id.secret_suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region for deployment | `string` | `"us-east-1"` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment label (e.g., development, staging, production) | `string` | `"development"` | no |
| <a name="input_ggscout_image_tag"></a> [ggscout\_image\_tag](#input\_ggscout\_image\_tag) | Container image tag for ggscout | `string` | `"latest"` | no |
| <a name="input_gitguardian_api_key"></a> [gitguardian\_api\_key](#input\_gitguardian\_api\_key) | GitGuardian API key for authentication | `string` | n/a | yes |
| <a name="input_owner_email"></a> [owner\_email](#input\_owner\_email) | Owner email for ggscout configuration | `string` | n/a | yes |
| <a name="input_schedule_expression"></a> [schedule\_expression](#input\_schedule\_expression) | EventBridge schedule expression for ggscout execution | `string` | `"rate(1 hour)"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cloudwatch_log_group"></a> [cloudwatch\_log\_group](#output\_cloudwatch\_log\_group) | Name of the CloudWatch log group |
| <a name="output_ecs_cluster_arn"></a> [ecs\_cluster\_arn](#output\_ecs\_cluster\_arn) | ARN of the ECS cluster |
| <a name="output_ecs_cluster_name"></a> [ecs\_cluster\_name](#output\_ecs\_cluster\_name) | Name of the ECS cluster |
| <a name="output_efs_file_system_id"></a> [efs\_file\_system\_id](#output\_efs\_file\_system\_id) | ID of the EFS file system |
| <a name="output_eventbridge_rule_name"></a> [eventbridge\_rule\_name](#output\_eventbridge\_rule\_name) | Name of the EventBridge rule |
| <a name="output_private_subnet_ids"></a> [private\_subnet\_ids](#output\_private\_subnet\_ids) | IDs of the private subnets |
| <a name="output_public_subnet_ids"></a> [public\_subnet\_ids](#output\_public\_subnet\_ids) | IDs of the public subnets |
| <a name="output_secret_arn"></a> [secret\_arn](#output\_secret\_arn) | ARN of the GitGuardian API key secret |
| <a name="output_task_definition_arn"></a> [task\_definition\_arn](#output\_task\_definition\_arn) | ARN of the ECS task definition |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | ID of the VPC |
<!-- END_TF_DOCS -->