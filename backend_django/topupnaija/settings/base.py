from pathlib import Path
import environ

BASE_DIR = Path(__file__).resolve().parent.parent.parent

env = environ.Env()
environ.Env.read_env(BASE_DIR / '.env')

SECRET_KEY = env('SECRET_KEY', default='django-insecure-change-me-in-production')

INSTALLED_APPS = [
    # Local apps first so their management commands override django.contrib.auth's
    'apps.authentication',
    'apps.tenants',
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    # Third party
    'rest_framework',
    'rest_framework_simplejwt',
    'rest_framework_simplejwt.token_blacklist',
    'corsheaders',
    # Local
    'apps.wallet',
    'apps.airtime',
    'apps.data_plans',
    'apps.transactions',
    'apps.admin_portal',
    'apps.beneficiaries',
    'apps.disputes',
    'apps.bills',
    'apps.referrals',
    'apps.ussd',
    'apps.agents',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'corsheaders.middleware.CorsMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
    'core.middleware.TenantMiddleware',
]

ROOT_URLCONF = 'topupnaija.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [BASE_DIR / 'templates'],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'topupnaija.wsgi.application'
ASGI_APPLICATION = 'topupnaija.asgi.application'

AUTH_USER_MODEL = 'authentication.User'

AUTHENTICATION_BACKENDS = [
    'apps.authentication.backends.PhoneNumberBackend',
    'django.contrib.auth.backends.ModelBackend',
]

AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator', 'OPTIONS': {'min_length': 6}},
]

LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'Africa/Lagos'
USE_I18N = True
USE_TZ = True

STATIC_URL = '/static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'
STATICFILES_DIRS = [BASE_DIR / 'static']

MEDIA_URL = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticated',
    ],
    'DEFAULT_PAGINATION_CLASS': 'core.pagination.StandardPagination',
    'PAGE_SIZE': 20,
    'EXCEPTION_HANDLER': 'core.exceptions.custom_exception_handler',
    'DEFAULT_THROTTLE_CLASSES': [
        'rest_framework.throttling.AnonRateThrottle',
        'rest_framework.throttling.UserRateThrottle',
    ],
    'DEFAULT_THROTTLE_RATES': {
        'anon': '200/day',
        'user': '2000/day',
        'otp': '10/hour',
        'login': '20/hour',
        'purchase': '100/hour',
    },
}

from datetime import timedelta

SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(minutes=30),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=30),
    'ROTATE_REFRESH_TOKENS': True,
    'BLACKLIST_AFTER_ROTATION': True,
    'AUTH_HEADER_TYPES': ('Bearer',),
    'USER_ID_FIELD': 'id',
    'USER_ID_CLAIM': 'user_id',
}

CORS_ALLOW_ALL_ORIGINS = False
CORS_ALLOWED_ORIGINS = env.list('CORS_ALLOWED_ORIGINS', default=[])

from corsheaders.defaults import default_headers
CORS_ALLOW_HEADERS = list(default_headers) + [
    'bypass-tunnel-reminder',
    'x-tenant-slug',
]

# External services
AT_API_KEY = env('AT_API_KEY', default='')
AT_USERNAME = env('AT_USERNAME', default='sandbox')
AT_SENDER_ID = env('AT_SENDER_ID', default='TopUpNaija')
GLADTIDING_API_KEY = env('GLADTIDING_API_KEY', default='')
GLADTIDING_BASE_URL = env('GLADTIDING_BASE_URL', default='https://gladtidingsdata.com/api')
PAYSTACK_SECRET_KEY = env('PAYSTACK_SECRET_KEY', default='')
# VTpass (electricity / cable TV bills)
VTPASS_API_KEY = env('VTPASS_API_KEY', default='')
VTPASS_PUBLIC_KEY = env('VTPASS_PUBLIC_KEY', default='')
VTPASS_SECRET_KEY = env('VTPASS_SECRET_KEY', default='')
VTPASS_BASE_URL = env('VTPASS_BASE_URL', default='https://vtpass.com/api')
# Auto-retry for failed airtime/data/bill transactions
TXN_MAX_RETRIES = env.int('TXN_MAX_RETRIES', default=3)
# Shared secret a USSD gateway must send in the X-USSD-Secret header
USSD_WEBHOOK_SECRET = env('USSD_WEBHOOK_SECRET', default='')
# Path to Firebase service account JSON, or None to disable push notifications
FIREBASE_CREDENTIALS = env('FIREBASE_CREDENTIALS', default=None)
DEV_MODE = env.bool('DEV_MODE', default=True)
TEST_OTP = env('TEST_OTP', default='123456')
