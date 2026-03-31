from django.db import connection
from django.http import JsonResponse


def liveness(request):
    """K8s liveness probe — перевіряє що процес живий."""
    return JsonResponse({"status": "ok"})


def readiness(request):
    """K8s readiness probe — перевіряє підключення до БД перед прийомом трафіку."""
    try:
        connection.ensure_connection()
        db_status = "ok"
    except Exception as e:
        return JsonResponse({"status": "error", "db": str(e)}, status=503)

    return JsonResponse({"status": "ok", "db": db_status})
