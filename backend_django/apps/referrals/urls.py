from django.urls import path
from .views import MyReferralsView

urlpatterns = [
    path('', MyReferralsView.as_view()),
]
