resource "oci_core_instance" "main" {
  count = local.instance_count

  compartment_id      = var.compartment_id
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name

  shape = var.instance_shape

  shape_config {
    ocpus         = 2
    memory_in_gbs = 16
  }

  create_vnic_details {
    subnet_id = (
      local.is_paranoid
      ? oci_core_subnet.private[0].id
      : oci_core_subnet.public.id
    )

    assign_public_ip = !local.is_paranoid

    nsg_ids = (
      local.is_paranoid
      ? [oci_core_network_security_group.private_app[0].id]
      : [oci_core_network_security_group.main.id]
    )
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.oracle_linux.images[0].id
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data           = base64encode(local.bootstrap_script)
  }

  display_name = "${var.project_name}-instance-${count.index + 1}"

  freeform_tags = {
    Project       = var.project_name
    Environment   = var.environment
    Owner         = var.owner
    ManagedBy     = var.managed_by
    CloudProvider = var.cloud_provider
    AutoDestroy   = "true"
  }
}