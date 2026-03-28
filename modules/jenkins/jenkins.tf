locals {
  oidc_provider = replace(var.cluster_oidc_issuer_url, "https://", "")
}

resource "kubernetes_namespace" "jenkins" {
  metadata {
    name = var.namespace
  }
}

resource "aws_iam_role" "jenkins_irsa" {
  name = "${var.cluster_name}-jenkins-irsa"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = "arn:aws:iam::${var.aws_account_id}:oidc-provider/${local.oidc_provider}"
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc_provider}:sub" = "system:serviceaccount:${var.namespace}:jenkins"
          "${local.oidc_provider}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })

  tags = {
    Name = "${var.cluster_name}-jenkins-irsa"
  }
}

resource "aws_iam_policy" "jenkins_ecr_push" {
  name        = "${var.cluster_name}-jenkins-ecr-push"
  description = "Дозволяє Jenkins push образів до ECR"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage",
        ]
        Resource = var.ecr_repository_arn
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "jenkins_ecr" {
  role       = aws_iam_role.jenkins_irsa.name
  policy_arn = aws_iam_policy.jenkins_ecr_push.arn
}

resource "kubernetes_secret" "ecr_registry_config" {
  metadata {
    name      = "ecr-registry-config"
    namespace = var.namespace
  }

  type = "Opaque"

  data = {
    "config.json" = jsonencode({
      credHelpers = {
        "${var.aws_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com" = "ecr-login"
      }
    })
  }

  depends_on = [kubernetes_namespace.jenkins]
}

resource "helm_release" "jenkins" {
  name       = "jenkins"
  namespace  = var.namespace
  repository = "https://charts.jenkins.io"
  chart      = "jenkins"
  version    = var.chart_version

  timeout         = 600
  cleanup_on_fail = true

  values = [
    file("${path.module}/values.yaml"),
    var.values_override,
  ]

  set {
    name  = "controller.adminUser"
    value = var.admin_user
  }

  set_sensitive {
    name  = "controller.adminPassword"
    value = var.admin_password
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.jenkins_irsa.arn
  }

  set {
    name  = "serviceAccount.name"
    value = "jenkins"
  }

  depends_on = [
    kubernetes_namespace.jenkins,
    aws_iam_role_policy_attachment.jenkins_ecr,
    kubernetes_secret.ecr_registry_config,
  ]
}
