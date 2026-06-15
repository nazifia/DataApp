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


def notify(user, title: str, body: str, type: str = '', data: dict | None = None,
           tenant=None, push: bool = True):
    """Persist an in-app Notification and (optionally) send a push.

    Returns the created Notification, or None if persistence failed.
    Tenant defaults to the user's tenant. Never raises — notifications are
    best-effort side effects and must not break the calling transaction.
    """
    notification = None
    try:
        from apps.notifications.models import Notification
        notification = Notification.all_objects.create(
            tenant=tenant or getattr(user, 'tenant', None),
            user=user,
            title=title,
            body=body,
            type=type,
            data={str(k): str(v) for k, v in (data or {}).items()},
        )
    except Exception as exc:
        logger.warning('Notification persist failed for user %s: %s', getattr(user, 'id', '?'), exc)

    if push:
        send_push_notification(user, title, body, {**(data or {}), 'type': type} if type else data)

    return notification
