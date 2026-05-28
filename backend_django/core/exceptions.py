from rest_framework.views import exception_handler
from rest_framework.response import Response
from django.conf import settings
import traceback


def custom_exception_handler(exc, context):
    response = exception_handler(exc, context)
    if response is not None:
        return response

    if settings.DEBUG:
        return Response(
            {'detail': str(exc), 'traceback': traceback.format_exc()},
            status=500,
        )
    return Response({'detail': 'An unexpected error occurred.'}, status=500)
