from django.urls import path
from .views import DataPlansView, DataPurchaseView

urlpatterns = [
    path('plans/', DataPlansView.as_view()),
    path('purchase/', DataPurchaseView.as_view()),
]
