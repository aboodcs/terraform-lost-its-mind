locals {
  is_paranoid  = var.security_level >= 80
  network_mode = local.is_paranoid ? "private" : "public"
  ## if local.is_paranoid = true then the network mode is private, otherwise it is public

  personality = (
    var.budget < 20 ? "BROKE STUDENT" :
    var.security_level >= 80 ? "PARANOID ENGINEER" :
    var.budget >= 500 ? "CLOUD BILLIONAIRE" :
    var.chaos_level >= 80 ? "CHAOTIC" :
    "NORMAL ENGINEER"
  )
  personality_messages = {
    "BROKE STUDENT"     = "We are NOT paying for that."
    "NORMAL ENGINEER"   = "Let's build something reasonable."
    "PARANOID ENGINEER" = "I don't trust the Internet."
    "CLOUD BILLIONAIRE" = "Availability first. Money later."
    "CHAOTIC"           = "I provision therefore I am."
  }

  personality_message = local.personality_messages[local.personality]

  is_billionaire = local.personality == "CLOUD BILLIONAIRE"

  max_instance_count = 3

  requested_instance_count = local.is_billionaire ? 2 : 1
  ## local.is_billionaire = true creates 2 instances, otherwise 1 instance is created
  instance_count = min(
    local.requested_instance_count,
    local.max_instance_count
  )
}
