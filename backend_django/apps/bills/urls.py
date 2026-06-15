from django.urls import path
from .views import ProvidersView, VariationsView, VerifyCustomerView, BillPaymentView

urlpatterns = [
    path('providers/', ProvidersView.as_view()),
    path('variations/', VariationsView.as_view()),
    path('verify/', VerifyCustomerView.as_view()),
    path('pay/', BillPaymentView.as_view()),
]
