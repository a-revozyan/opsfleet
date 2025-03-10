resource "aws_iam_role" "this" {
  name = var.role_name

  assume_role_policy = var.custom_assume_role_policy != "" ? var.custom_assume_role_policy : jsonencode({
    Version = var.role_version
    Statement = [
      merge(
        {
          Action = var.actions
          Effect = var.effect
          Principal = {
            (var.principal_type) = var.principal_type == "Service" ? [var.service] : var.identifiers
          }
        },
        length(keys(var.condition)) > 0 ? { Condition = var.condition } : {}
      )
    ]
  })

  tags = var.tags
}
