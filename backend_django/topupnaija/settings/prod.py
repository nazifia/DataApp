from .base import *
import environ

env = environ.Env()

DEBUG = False
ALLOWED_HOSTS = env.list('ALLOWED_HOSTS', default=[])

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': env('PG_DB', default='topupnaija'),
        'USER': env('PG_USER', default='postgres'),
        'PASSWORD': env('PG_PASSWORD', default=''),
        'HOST': env('PG_HOST', default='localhost'),
        'PORT': env('PG_PORT', default='5432'),
        'CONN_MAX_AGE': 60,
    }
}

CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.db.DatabaseCache',
        'LOCATION': 'cache_table',
    }
}

SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
