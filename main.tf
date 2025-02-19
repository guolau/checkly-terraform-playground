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

# resource "checkly_check_group" "terraform-group" {
#   name = "Terraform Group"
#   activated = true
#   muted = false
#   concurrency = 10
#   run_parallel = true
#   locations = ["us-east-1", "eu-west-1"]
# }

resource "checkly_check" "tf-dog-api-list" {
  name = "Dog.ceo List Breeds"
  type = "API"
  activated = true
  frequency = 720
  tags = ["terraform", "dog"]
  locations = ["us-east-1", "eu-west-1"]

  # group_id = checkly_check_group.terraform-group.id

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

resource "checkly_check" "tf-checklyhq" {
  name = "checklyhq.spec.ts"
  type = "BROWSER"
  activated = true
  frequency = 1440
  locations = ["us-east-1", "eu-west-1"]
  tags = ["terraform"]


  script = <<EOT
    import { test, expect } from '@playwright/test';

    test('navigate to docs and search for traces', async ({ page }) => {
      await page.goto('https://www.checklyhq.com/');
      await page.getByRole('button', { name: 'Developers' }).first().click();
      await page.getByRole('link', { name: 'Documentation Technical docs' }).click();
      await expect(page.getByRole('heading', { name: 'Getting started with Checkly' })).toBeVisible();
      await page.locator('button.DocSearch').click();
      await expect(page.getByPlaceholder('Search docs')).toBeEmpty();
      await page.getByPlaceholder('Search docs').click();
      await page.getByPlaceholder('Search docs').fill('traces');
      await page.getByRole('link', { name: 'Importing your traces to' }).click();
      await expect(page.getByRole('heading', { name: 'Importing your traces to' })).toBeVisible();
    });

    test('navigate to main blog and it loads correctly', async ({ page }) => {
      await page.goto('https://www.checklyhq.com');
      await page.getByRole('link', { name: 'Blog' }).first().click();
      await expect(page.getByRole('heading', { name: 'The Checkly Blog' })).toBeVisible();

      const post = page.locator('.section-blog').first();
      const postName = await post.locator('h2').textContent();
      await post.click();
      
      if(postName) {
        await expect(page.locator('h1')).toContainText(postName);
      } else {
        test.fail();
      }
    });
  EOT

  alert_channel_subscription {
    channel_id = checkly_alert_channel.tf_email.id
    activated = true
  }

  alert_channel_subscription {
    channel_id = checkly_alert_channel.tf_sms.id
    activated = true
  }
}

resource "checkly_check" "tf-maintainence-window-api" {
  name = "maintainence-window-api.spec.ts"
  type = "MULTI_STEP"
  activated = true
  frequency = 1440
  locations = ["us-east-1", "eu-west-1"]
  tags = ["terraform"]

  script = <<EOT
    import { test, expect } from '@playwright/test'

    const baseUrl = 'https://api.checklyhq.com/v1/maintenance-windows'
    const headers = {
      'X-Checkly-Account': process.env.CHECKLY_ACCOUNT_ID,
      Authorization: `Bearer $${process.env.CHECKLY_API_KEY}`,
    }

    test('create, retrieve, and delete a maintainence window', async ({ request }) => {
      const maintWindow = await test.step('create', async () => {
        const response  = await request.post(`$${baseUrl}`, {
          data: {
            name: 'My Test Maintainence Window',
            startsAt: '2030-12-01',
            endsAt: '2030-12-02',
            repeatUnit: 'MONTH',
          },
          headers
        })

        expect(response).toBeOK()

        return response.json()
      })

      await test.step('retrieve', async () => {
        const response = await request.get(`$${baseUrl}/$${maintWindow.id}`, {
          headers
        })
      
        expect(response).toBeOK()

        const retrievedMaintWindow = await response.json()
        expect(retrievedMaintWindow.id).toEqual(maintWindow.id)
      })

      await test.step('delete', async () => {
        const response = await request.delete(`$${baseUrl}/$${maintWindow.id}`, {
          headers
        })

        expect(response).toBeOK()
      })

      await test.step('check if deleted', async () => {
        const response = await request.get(`$${baseUrl}/$${maintWindow.id}`, {
          headers
        })
      
        expect(response.status()).toBe(404)
      })
    })
  EOT

  alert_channel_subscription {
    channel_id = checkly_alert_channel.tf_email.id
    activated = true
  }

  alert_channel_subscription {
    channel_id = checkly_alert_channel.tf_sms.id
    activated = true
  }
}
