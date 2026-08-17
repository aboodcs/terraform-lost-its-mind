variable "user_ocid" {
  description = "OCID of the OCI user for API authentication"
  type        = string
  sensitive   = true
}

variable "tenancy_ocid" {
  description = "OCID of the OCI tenancy"
  type        = string
  sensitive   = true
}

variable "fingerprint" {
  description = "Fingerprint of the OCI API signing key"
  type        = string
  sensitive   = true
}

variable "private_key_path" {
  description = "Absolute path to the OCI API private key (.pem)"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "OCI region where resources will be created"
  type        = string
  default     = "eu-amsterdam-1"
}

variable "budget" {
  description = "Budget for the environment"
  type        = number

  validation {
    condition     = var.budget >= 0
    error_message = "Budget must be greater than or equal to 0."
  }
}

variable "security_level" {
  description = "Security level for the environment"
  type        = number

  validation {
    condition     = var.security_level >= 0 && var.security_level <= 100
    error_message = "Security level must be a number between 0 and 100."
  }
}

variable "chaos_level" {
  description = "Chaos level for the environment"
  type        = number

  validation {
    condition     = var.chaos_level >= 0 && var.chaos_level <= 100
    error_message = "Chaos level must be a number between 0 and 100."
  }
}

variable "environment" {
  description = "Name of the environment"
  type        = string

  validation {
    condition     = contains(["dev", "test", "staging"], var.environment)
    error_message = "Environment name must be one of: dev, test, staging."
  }
}

variable "compartment_id" {
  description = "OCID of the OCI compartment where resources will be created"
  type        = string
}

variable "project_name" {
  description = "Project name used in resource display names and freeform tags"
  type        = string
  default     = "terraform-lost-its-mind"
}

variable "owner" {
  description = "Owner of the infrastructure"
  type        = string
  default     = "abdulrehman-yahya"
}

variable "managed_by" {
  description = "Tool managing the infrastructure"
  type        = string
  default     = "Terraform"
}

variable "cloud_provider" {
  description = "Cloud provider used by this environment"
  type        = string
  default     = "OCI"
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed for SSH access"
  type        = string
}

variable "instance_shape" {
  description = "Shape of the OCI Compute instance"
  type        = string
  default     = "VM.Standard.E4.Flex"
}

variable "ssh_public_key" {
  description = "Public SSH key used to access the Compute instance"
  type        = string
}