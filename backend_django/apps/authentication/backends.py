from django.contrib.auth.backends import ModelBackend
from django.contrib.auth import get_user_model


class PhoneNumberBackend(ModelBackend):
    """Authenticate staff/admin users by phone_number + password."""

    def authenticate(self, request, username=None, password=None, **kwargs):
        phone = username or kwargs.get('phone_number')
        if not phone:
            return None
        User = get_user_model()
        candidates = User.objects.filter(phone_number=phone, is_staff=True)
        for user in candidates.order_by('-is_superuser'):
            if user.check_password(password) and self.user_can_authenticate(user):
                return user
        return None
