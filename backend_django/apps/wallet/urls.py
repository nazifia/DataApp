from django.urls import path
from .views import (
    WalletBalanceView, BankDetailsView, InitiatePaymentView, PaystackWebhookView,
    FundWalletView, BankListView, ResolveAccountView, WithdrawView,
    WithdrawalStatusView,
)

urlpatterns = [
    path('balance/', WalletBalanceView.as_view()),
    path('bank-details/', BankDetailsView.as_view()),
    path('initiate-payment/', InitiatePaymentView.as_view()),
    path('webhook/paystack/', PaystackWebhookView.as_view()),
    path('fund/', FundWalletView.as_view()),  # kept for dev/admin use
    path('banks/', BankListView.as_view()),
    path('resolve-account/', ResolveAccountView.as_view()),
    path('withdraw/', WithdrawView.as_view()),
    path('withdraw/<str:reference>/status/', WithdrawalStatusView.as_view()),
]
