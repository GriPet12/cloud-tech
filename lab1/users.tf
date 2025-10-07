resource "azuread_user" "az104_user1" {
  user_principal_name   = "az104-user1@pgrigorcuk0gmail.onmicrosoft.com"
  display_name          = "az104-user1"
  password              = "Str0ngP@ssw0rd!"
  force_password_change = true
  account_enabled       = true

  job_title      = "IT Lab Administrator"
  department     = "IT"
  usage_location = "US"
}

resource "azuread_invitation" "guest_user" {
  user_email_address = "pgrigorcuk0@gmail.com"
  redirect_url       = "https://portal.azure.com"
}
