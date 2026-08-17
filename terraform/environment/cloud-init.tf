locals {
  website_html = templatefile(
    "${path.module}/../../website/index.html.tpl",
    {
      infrastructure_name = var.project_name
      personality         = local.personality
      personality_message = local.personality_message
      budget              = var.budget
      security_level      = var.security_level
      chaos_level         = var.chaos_level
      environment         = var.environment
    }
  )

  bootstrap_script = templatefile(
    "${path.module}/../../scripts/bootstrap.sh",
    {
      index_html = local.website_html
    }
  )
}
