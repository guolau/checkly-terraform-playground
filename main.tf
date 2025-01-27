terraform {
  required_providers {
    checkly = {
      source = "checkly/checkly"
      version = "~> 1.0"
    }
  }
}

variable "checkly_api_key" {}
variable "checkly_account_id" {}
variable "email_address" {}
variable "phone_number" {}

provider "checkly" {
  api_key = var.checkly_api_key
  account_id = var.checkly_account_id
}

resource "checkly_alert_channel" "tf_email" {
  email {
    address = var.email_address
  }
  send_failure = true
  send_recovery = true
  send_degraded = false
}

resource "checkly_alert_channel" "tf_sms" {
  sms {
    name = "terraform laura"
    number = var.phone_number
  }
  send_failure = true
  send_recovery = true
  send_degraded = false
}

resource "checkly_check" "tf-dog-api-list" {
  name = "Dog.ceo List Breeds"
  type = "API"
  activated = true
  frequency = 720
  tags = ["terraform", "dog"]
  locations = ["us-east-1", "eu-west-1"]

  alert_channel_subscription {
    channel_id = checkly_alert_channel.tf_email.id
    activated = true
  }
  
  request {
    url = "https://dog.ceo/api/breeds/list/all"
    
    assertion {
      source = "STATUS_CODE"
      comparison = "EQUALS"
      target = "200"
    }

    assertion {
      source = "JSON_BODY"
      property = "$.message"
      comparison = "NOT_EMPTY"
    }
  }
}