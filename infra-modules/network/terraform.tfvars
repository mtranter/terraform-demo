region     = "us-east-2"
vpc_name   = "test-123"
cidr_block = "10.1.0.0/16"
subnet_definitions = {
  public = {
    new_bits  = 8
    is_public = true
  },
  private = {
    new_bits  = 8
    is_public = false
  },
  database = {
    new_bits  = 12
    is_public = false
  },
}
nacls = [{
    name = "allow-pg"
    protocol = "tcp"
    rule_number = 100
    action = "allow"
    cidr_block = "10.1.0.0/16"
}]