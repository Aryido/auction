module "project_services" {
  source = "terraform-google-modules/project-factory/google//modules/project_services"

  project_id = var.project_id

  activate_apis = [
    "compute.googleapis.com",
    "iam.googleapis.com",
  ]
}