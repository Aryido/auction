variable "project_id" {
  description = "Google Cloud project ID."
  type        = string
  validation {
    condition     = var.project_id != ""
    error_message = "Error: project_id is required"
  }
}

variable "region" {
  description = "Google Cloud region where the cloud resource will be created."
  type        = string
  default     = "asia-east1"
}

variable "zone" {
  description = "Google cloud zone where the resources will be created."
  type        = string
  default     = "asia-east1-a"
}