from django.urls import path
from .user_views import CreateProfileView, ProfileView, ChangePasswordView, ProfilePictureView, RegisterFCMTokenView

urlpatterns = [
    path('profile/setup/', CreateProfileView.as_view()),
    path('profile/', ProfileView.as_view()),
    path('password/', ChangePasswordView.as_view()),
    path('profile/picture/', ProfilePictureView.as_view()),
    path('fcm-token/', RegisterFCMTokenView.as_view()),
]
