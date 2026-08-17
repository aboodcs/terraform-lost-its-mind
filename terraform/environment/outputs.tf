output "personality" {
  description = "Current Terraform personality."
  value       = local.personality
}

output "personality_message" {
  description = "Current Terraform personality message."
  value       = local.personality_message
}

output "architecture_mode" {
  description = "Current infrastructure architecture mode."
  value = (
    local.is_paranoid
    ? "PARANOID PRIVATE ARCHITECTURE"
    : "STANDARD PUBLIC ARCHITECTURE"
  )
}

output "vcn_id" {
  description = "OCID of the created VCN."
  value       = oci_core_vcn.main.id
}

output "public_subnet_id" {
  description = "OCID of the created public subnet."
  value       = oci_core_subnet.public.id
}

output "private_subnet_id" {
  description = "OCID of the private subnet when Paranoid Mode is active."
  value = (
    local.is_paranoid
    ? oci_core_subnet.private[0].id
    : null
  )
}

output "internet_gateway_id" {
  description = "OCID of the created Internet Gateway."
  value       = oci_core_internet_gateway.main.id
}

output "network_security_group_id" {
  description = "OCID of the main Network Security Group."
  value       = oci_core_network_security_group.main.id
}

output "instance_ids" {
  description = "OCIDs of all Compute instances."
  value       = oci_core_instance.main[*].id
}

output "private_ips" {
  description = "Private IP addresses of all Compute instances."
  value       = oci_core_instance.main[*].private_ip
}

output "public_ips" {
  description = "Public IP addresses when instances are publicly accessible."

  value = (
    local.is_paranoid
    ? []
    : oci_core_instance.main[*].public_ip
  )
}

output "instance_count" {
  description = "Number of Compute instances created."
  value       = local.instance_count
}

output "load_balancer_ip" {
  description = "Public IP address of the Billionaire Mode load balancer."
  value = (
    local.is_billionaire
    ? oci_load_balancer_load_balancer.main[0].ip_address_details[0].ip_address
    : null
  )
}

output "application_url" {
  description = "Primary application URL for the active architecture."
  value = (
    local.is_billionaire
    ? "http://${oci_load_balancer_load_balancer.main[0].ip_address_details[0].ip_address}"
    : local.is_paranoid
    ? null
    : "http://${oci_core_instance.main[0].public_ip}"
  )
}

output "website_url" {
  description = "Primary website URL for the active architecture."

  value = (
    local.is_billionaire
    ? "http://${oci_load_balancer_load_balancer.main[0].ip_address_details[0].ip_address}"
    : local.is_paranoid
    ? null
    : "http://${oci_core_instance.main[0].public_ip}"
  )
}

output "website_urls" {
  description = "URLs of all directly public Terraform personality websites."

  value = (
    local.is_billionaire
    ? ["http://${oci_load_balancer_load_balancer.main[0].ip_address_details[0].ip_address}"]
    : local.is_paranoid
    ? []
    : [
      for instance in oci_core_instance.main :
      "http://${instance.public_ip}"
    ]
  )
}
