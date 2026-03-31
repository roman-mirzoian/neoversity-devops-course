from django.urls import path, include

urlpatterns = [
    # Prometheus metrics endpoint — scraped by kube-prometheus-stack
    path("metrics/", include("django_prometheus.urls")),
    # Health check — used by K8s liveness/readiness probes
    path("health/", include("health.urls")),
]
