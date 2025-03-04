output "addresses" {
  description = "List of address values (e.g. [\"1.2.3.4\"])"
  value       = module.global_addresses.addresses
}

output "private_key_file" {
  description = "A PrivateKey file's path for ansible SSH"
  value       = "~/.ssh/${local.private_key_filename}"
}
