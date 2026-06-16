from .base import *
import environ

env = environ.Env()

DEBUG = False
ALLOWED_HOSTS = env.list('ALLOWED_HOSTS', default=[])

# Fail hard rather than boot prod with the insecure placeholder key.
SECRET_KEY = env('SECRET_KEY')

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

# Serve collected static files (admin + DRF browsable API) via WhiteNoise.
STORAGES = {
    'default': {
        'BACKEND': 'django.core.files.storage.FileSystemStorage',
    },
    'staticfiles': {
        'BACKEND': 'whitenoise.storage.CompressedManifestStaticFilesStorage',
    },
}

SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True

SECURE_SSL_REDIRECT = True
SECURE_HSTS_SECONDS = 31536000  # 1 year
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_HSTS_PRELOAD = True
SECURE_CONTENT_TYPE_NOSNIFF = True
SESSION_COOKIE_HTTPONLY = True
X_FRAME_OPTIONS = 'DENY'
