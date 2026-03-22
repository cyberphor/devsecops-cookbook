output "endpoint" {
    value = module.AzureOpenAI.endpoint
}

output "primary_access_key" {
    value = module.AzureOpenAI.primary_access_key
    sensitive = true
}
