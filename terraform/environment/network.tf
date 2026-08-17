resource "oci_core_vcn" "main" {
  compartment_id = var.compartment_id

  cidr_blocks  = ["10.0.0.0/16"]
  display_name = "main_vcn"
  dns_label    = "mainvcn"

  freeform_tags = {
    Project       = var.project_name
    Environment   = var.environment
    Owner         = var.owner
    ManagedBy     = var.managed_by
    CloudProvider = var.cloud_provider
    AutoDestroy   = "true"
  }
}

resource "oci_core_internet_gateway" "main" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.main.id

  display_name = "${var.project_name}-internet-gateway"
  enabled      = true

  freeform_tags = {
    Project       = var.project_name
    Environment   = var.environment
    Owner         = var.owner
    ManagedBy     = var.managed_by
    CloudProvider = var.cloud_provider
    AutoDestroy   = "true"
  }
}

// Subnets require a security list. Keep this list intentionally empty so that
// the NSGs defined in security.tf are the only source of VNIC traffic rules.
resource "oci_core_security_list" "nsg_only" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.main.id

  display_name = "${var.project_name}-nsg-only-security-list"

  freeform_tags = {
    Project       = var.project_name
    Environment   = var.environment
    Owner         = var.owner
    ManagedBy     = var.managed_by
    CloudProvider = var.cloud_provider
    AutoDestroy   = "true"
  }
}

resource "oci_core_route_table" "public" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.main.id

  display_name = "${var.project_name}-public-route-table"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.main.id

    description = "Route internet traffic through the Internet Gateway"
  }

  freeform_tags = {
    Project       = var.project_name
    Environment   = var.environment
    Owner         = var.owner
    ManagedBy     = var.managed_by
    CloudProvider = var.cloud_provider
    AutoDestroy   = "true"
  }
}


resource "oci_core_subnet" "public" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.main.id

  cidr_block   = "10.0.1.0/24"
  display_name = "${var.project_name}-public-subnet"

  route_table_id = oci_core_route_table.public.id

  security_list_ids = [oci_core_security_list.nsg_only.id]

  prohibit_public_ip_on_vnic = false

  freeform_tags = {
    Project       = var.project_name
    Environment   = var.environment
    Owner         = var.owner
    ManagedBy     = var.managed_by
    CloudProvider = var.cloud_provider
    AutoDestroy   = "true"
  }
}

resource "oci_core_nat_gateway" "paranoid" {
  count = local.is_paranoid ? 1 : 0

  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.main.id

  display_name = "${var.project_name}-nat-gateway"

  freeform_tags = {
    Project       = var.project_name
    Environment   = var.environment
    Owner         = var.owner
    ManagedBy     = var.managed_by
    CloudProvider = var.cloud_provider
    AutoDestroy   = "true"
  }
}


resource "oci_core_route_table" "private" {
  count = local.is_paranoid ? 1 : 0

  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.main.id

  display_name = "${var.project_name}-private-route-table"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.paranoid[0].id

    description = "Route private subnet traffic through NAT Gateway"
  }

  freeform_tags = {
    Project       = var.project_name
    Environment   = var.environment
    Owner         = var.owner
    ManagedBy     = var.managed_by
    CloudProvider = var.cloud_provider
    AutoDestroy   = "true"
  }
}


resource "oci_core_subnet" "private" {
  count = local.is_paranoid ? 1 : 0

  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.main.id

  cidr_block   = "10.0.2.0/24"
  display_name = "${var.project_name}-private-subnet"

  route_table_id = oci_core_route_table.private[0].id

  security_list_ids = [oci_core_security_list.nsg_only.id]

  prohibit_public_ip_on_vnic = true

  freeform_tags = {
    Project       = var.project_name
    Environment   = var.environment
    Owner         = var.owner
    ManagedBy     = var.managed_by
    CloudProvider = var.cloud_provider
    AutoDestroy   = "true"
  }
}
