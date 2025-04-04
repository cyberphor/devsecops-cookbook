locals {
    resources = {
        acr       = lower("${var.csp}${var.app}${var.env}acr")
        aks       = upper("${var.csp}-${var.app}-${var.env}-aks")
        aks_nodes = upper("${var.csp}-${var.app}-${var.env}-aks-nodes")
        amg       = upper("${var.csp}-${var.app}-${var.env}-amg")
        amw       = upper("${var.csp}-${var.app}-${var.env}-amw")
        law       = upper("${var.csp}-${var.app}-${var.env}-law")
    }
}