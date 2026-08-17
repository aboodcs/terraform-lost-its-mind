resource "oci_core_network_security_group" "main" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.main.id

  display_name = "${var.project_name}-nsg"

  freeform_tags = {
    Project       = var.project_name
    Environment   = var.environment
    ManagedBy     = var.managed_by
    CloudProvider = var.cloud_provider
    AutoDestroy   = "true"
  }
}


resource "oci_core_network_security_group_security_rule" "allow_ssh" {
  network_security_group_id = oci_core_network_security_group.main.id

  direction   = "INGRESS"
  protocol    = "6"
  source      = var.allowed_ssh_cidr
  source_type = "CIDR_BLOCK"

  description = "Allow SSH from trusted CIDR only"

  tcp_options {
    destination_port_range {
      min = 22
      max = 22
    }
  }
}

resource "oci_core_network_security_group_security_rule" "allow_http" {
  count                     = (!local.is_paranoid && !local.is_billionaire) ? 1 : 0
  network_security_group_id = oci_core_network_security_group.main.id

  direction   = "INGRESS"
  protocol    = "6"
  source      = "0.0.0.0/0"
  source_type = "CIDR_BLOCK"

  description = "Allow HTTP from the Internet"

  tcp_options {
    destination_port_range {
      min = 80
      max = 80
    }
  }
}

resource "oci_core_network_security_group_security_rule" "allow_egress" {
  network_security_group_id = oci_core_network_security_group.main.id

  direction        = "EGRESS"
  protocol         = "all"
  destination      = "0.0.0.0/0"
  destination_type = "CIDR_BLOCK"
  description      = "Allow all outbound internet traffic"
  stateless        = false
}

resource "oci_core_network_security_group" "private_app" {
  count = local.is_paranoid ? 1 : 0

  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.main.id

  display_name = "${var.project_name}-private-app-nsg"

  freeform_tags = {
    Project       = var.project_name
    Environment   = var.environment
    ManagedBy     = var.managed_by
    CloudProvider = var.cloud_provider
    AutoDestroy   = "true"
  }
}

resource "oci_core_network_security_group" "public_entry" {
  count = (local.is_paranoid || local.is_billionaire) ? 1 : 0

  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.main.id

  display_name = "${var.project_name}-public-entry-nsg"

  freeform_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = var.managed_by
  }
}

resource "oci_core_network_security_group_security_rule" "public_entry_http" {
  count = (local.is_paranoid || local.is_billionaire) ? 1 : 0

  network_security_group_id = oci_core_network_security_group.public_entry[0].id

  direction   = "INGRESS"
  protocol    = "6"
  source      = "0.0.0.0/0"
  source_type = "CIDR_BLOCK"

  tcp_options {
    destination_port_range {
      min = 80
      max = 80
    }
  }

  description = "Public HTTP entry point"
}

resource "oci_core_network_security_group_security_rule" "main_http_from_load_balancer" {
  count = local.is_billionaire ? 1 : 0

  network_security_group_id = oci_core_network_security_group.main.id

  direction   = "INGRESS"
  protocol    = "6"
  source      = oci_core_network_security_group.public_entry[0].id
  source_type = "NETWORK_SECURITY_GROUP"

  tcp_options {
    destination_port_range {
      min = 80
      max = 80
    }
  }

  description = "Allow HTTP only from the load balancer"
}

resource "oci_core_network_security_group_security_rule" "public_entry_to_app_http" {
  count = local.is_billionaire ? 1 : 0

  network_security_group_id = oci_core_network_security_group.public_entry[0].id

  direction        = "EGRESS"
  protocol         = "6"
  destination      = local.is_paranoid ? oci_core_network_security_group.private_app[0].id : oci_core_network_security_group.main.id
  destination_type = "NETWORK_SECURITY_GROUP"
  description      = "Forward HTTP traffic to application instances"

  tcp_options {
    destination_port_range {
      min = 80
      max = 80
    }
  }
}

resource "oci_core_network_security_group_security_rule" "private_http" {
  count = local.is_paranoid ? 1 : 0

  network_security_group_id = oci_core_network_security_group.private_app[0].id

  direction = "INGRESS"
  protocol  = "6"

  source      = oci_core_network_security_group.public_entry[0].id
  source_type = "NETWORK_SECURITY_GROUP"

  tcp_options {
    destination_port_range {
      min = 80
      max = 80
    }
  }

  description = "Allow HTTP only from controlled entry point"
}

resource "oci_bastion_bastion" "paranoid" {
  count = local.is_paranoid ? 1 : 0

  bastion_type   = "STANDARD"
  compartment_id = var.compartment_id

  target_subnet_id = oci_core_subnet.private[0].id

  client_cidr_block_allow_list = [
    var.allowed_ssh_cidr
  ]

  name = "${var.project_name}-bastion"

  freeform_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = var.managed_by
  }
}

resource "oci_core_network_security_group_security_rule" "private_ssh" {
  count = local.is_paranoid ? 1 : 0

  network_security_group_id = oci_core_network_security_group.private_app[0].id

  direction = "INGRESS"
  protocol  = "6"

  source = "${oci_bastion_bastion.paranoid[0].private_endpoint_ip_address}/32"

  source_type = "CIDR_BLOCK"

  tcp_options {
    destination_port_range {
      min = 22
      max = 22
    }
  }

  description = "Allow SSH only through OCI Bastion"
}

resource "oci_core_network_security_group_security_rule" "private_http_from_bastion" {
  count = local.is_paranoid ? 1 : 0

  network_security_group_id = oci_core_network_security_group.private_app[0].id

  direction   = "INGRESS"
  protocol    = "6"
  source      = "${oci_bastion_bastion.paranoid[0].private_endpoint_ip_address}/32"
  source_type = "CIDR_BLOCK"

  tcp_options {
    destination_port_range {
      min = 80
      max = 80
    }
  }

  description = "Allow HTTP through OCI Bastion"
}

resource "oci_core_network_security_group_security_rule" "private_egress" {
  count = local.is_paranoid ? 1 : 0

  network_security_group_id = oci_core_network_security_group.private_app[0].id

  direction        = "EGRESS"
  protocol         = "all"
  destination      = "0.0.0.0/0"
  destination_type = "CIDR_BLOCK"

  description = "Allow outbound traffic through NAT Gateway"
}
