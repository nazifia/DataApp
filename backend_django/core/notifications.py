import logging
from django.conf import settings

logger = logging.getLogger(__name__)


def send_push_notification(user, title: str, body: str, data: dict | None = None) -> bool:
    """Send an FCM push notification to a single user. Silently no-ops if FCM is unconfigured."""
    token = getattr(user, 'fcm_token', None)
    if not token:
        return False
    if not getattr(settings, 'FIREBASE_CREDENTIALS', None):
        return False

    try:
        import firebase_admin
        from firebase_admin import credentials, messaging

        if not firebase_admin._apps:
            cred = credentials.Certificate(settings.FIREBASE_CREDENTIALS)
            firebase_admin.initialize_app(cred)

        message = messaging.Message(
            notification=messaging.Notification(title=title, body=body),
            data={str(k): str(v) for k, v in (data or {}).items()},
            token=token,
            android=messaging.AndroidConfig(priority='high'),
            apns=messaging.APNSConfig(
                payload=messaging.APNSPayload(
                    aps=messaging.Aps(sound='default', badge=1)
                )
            ),
        )
        messaging.send(message)
        return True
    except Exception as exc:
        logger.warning('FCM send failed for user %s: %s', getattr(user, 'id', '?'), exc)
        return False
