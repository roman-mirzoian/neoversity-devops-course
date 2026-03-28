resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.namespace
  }
}

# Helm release для Argo CD сервера
resource "helm_release" "argocd" {
  name       = "argocd"
  namespace  = var.namespace
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.chart_version

  timeout         = 600
  cleanup_on_fail = true

  values = [
    file("${path.module}/values.yaml"),
    var.values_override,
  ]

  depends_on = [kubernetes_namespace.argocd]
}

resource "helm_release" "argocd_apps" {
  name      = "argocd-apps"
  namespace = var.namespace
  chart     = "${path.module}/charts/argocd-apps"

  set {
    name  = "repoUrl"
    value = var.git_repo_url
  }

  set {
    name  = "targetRevision"
    value = var.target_revision
  }

  set {
    name  = "djangoApp.path"
    value = var.django_app_path
  }

  set {
    name  = "djangoApp.namespace"
    value = var.django_app_namespace
  }

  depends_on = [helm_release.argocd]
}
