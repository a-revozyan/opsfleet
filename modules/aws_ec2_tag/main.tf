resource "aws_ec2_tag" "this" {
  for_each    = var.objects
  resource_id = each.key
  key         = var.tag_key
  value       = var.tag_value
}
