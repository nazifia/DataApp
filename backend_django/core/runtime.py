"""Runtime dev/prod switch, toggleable from the Django admin.

A single ``RuntimeConfig`` row (apps.admin_portal) overrides the DEV_MODE env
default. The value is cached; ``RuntimeConfig.save()`` busts the cache so an
admin toggle applies on the next request. With no row present (fresh DB, tests)
the env-based ``settings.DEV_MODE`` is used as the default.

Use ``is_dev_mode()`` in sync code and ``await ais_dev_mode()`` in async code
(httpx provider calls) — never read ``settings.DEV_MODE`` directly.
"""
from asgiref.sync import sync_to_async
from django.conf import settings
from django.core.cache import cache

_CACHE_KEY = 'runtime:dev_mode'
_CACHE_TTL = 300  # seconds


def _read() -> bool:
    cached = cache.get(_CACHE_KEY)
    if cached is not None:
        return cached
    try:
        from apps.admin_portal.models import RuntimeConfig
        val = (
            RuntimeConfig.objects.filter(pk=RuntimeConfig.SINGLETON_PK)
            .values_list('dev_mode', flat=True)
            .first()
        )
    except Exception:
        # Table missing (pre-migrate) or DB error — fall back to env default.
        val = None
    if val is None:
        # No admin override yet: follow the deploy-time env flag. Not cached so
        # the first admin save takes effect immediately.
        return settings.DEV_MODE
    cache.set(_CACHE_KEY, val, _CACHE_TTL)
    return val


def is_dev_mode() -> bool:
    """True when the app should mock providers and accept the test OTP."""
    return _read()


async def ais_dev_mode() -> bool:
    """Async variant for use inside ``async def`` provider calls."""
    return await sync_to_async(_read, thread_sensitive=True)()
