locals {
    panels = [
        templatefile("templates/panel-01.tmpl", {
            query = replace(
                file("queries/query.kql"), "\n", ""
            )
        }),
    ]

    dashboard = templatefile("templates/dashboard.tmpl", {
        "title" = "Security"
        "uid"   = "security-dashboard"
        "panels" = join(",", local.panels)
    })
}

output "json" {
    value = "${local.dashboard}"
}
