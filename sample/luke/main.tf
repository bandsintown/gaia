terraform {
  backend "local" {
    path = ".terraform/luke.tfstate"
  }
}

variable "quote" {
  description="Star Wars quote"
}

output "quote" {
  description="Star Wars quote"
  value = "${var.quote}"
}

