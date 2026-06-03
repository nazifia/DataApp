from django.urls import path
from .views import WalletBalanceView, BankDetailsView, InitiatePaymentView, PaystackWebhookView, FundWalletView

urlpatterns = [
    path('balance/', WalletBalanceView.as_view()),
    path('bank-details/', BankDetailsView.as_view()),
    path('initiate-payment/', InitiatePaymentView.as_view()),
    path('webhook/paystack/', PaystackWebhookView.as_view()),
    path('fund/', FundWalletView.as_view()),  # kept for dev/admin use
]
