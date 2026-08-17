resource "oci_load_balancer_load_balancer" "main" {
  count = local.is_billionaire ? 1 : 0
  ## if true create a load balancer, otherwise skip
  compartment_id = var.compartment_id
  display_name   = "${var.project_name}-load-balancer"
  shape          = "flexible"
  subnet_ids     = [oci_core_subnet.public.id]
  is_private     = false

  network_security_group_ids = [oci_core_network_security_group.public_entry[0].id]

  shape_details {
    minimum_bandwidth_in_mbps = 10
    maximum_bandwidth_in_mbps = 10
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

resource "oci_load_balancer_backend_set" "app" { ## backend set the group of instances that will receive traffic from the load balancer
  count = local.is_billionaire ? 1 : 0

  load_balancer_id = oci_load_balancer_load_balancer.main[0].id
  name             = "app-backend-set"
  policy           = "ROUND_ROBIN"

  health_checker {
    protocol          = "HTTP"
    port              = 80
    url_path          = "/"
    return_code       = 200
    interval_ms       = 10000
    timeout_in_millis = 3000
    retries           = 3
  }
}

## Backend Set
##   │
##   ├── Backend = VM-1
##   └── Backend = VM-2

resource "oci_load_balancer_backend" "app" { ## backend the actual vms that will receive traffic from the load balancer
  for_each = local.is_billionaire ? {
    for index, instance in oci_core_instance.main : index => instance
  } : {}

  load_balancer_id = oci_load_balancer_load_balancer.main[0].id
  backendset_name  = oci_load_balancer_backend_set.app[0].name
  ip_address       = each.value.private_ip
  port             = 80
  weight           = 1
}

resource "oci_load_balancer_listener" "http" {
  count = local.is_billionaire ? 1 : 0

  load_balancer_id         = oci_load_balancer_load_balancer.main[0].id
  name                     = "http"
  default_backend_set_name = oci_load_balancer_backend_set.app[0].name
  port                     = 80
  protocol                 = "HTTP"
}
