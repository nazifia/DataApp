from django.urls import path
from .views import WalletBalanceView, BankDetailsView, FundWalletView

urlpatterns = [
    path('balance/', WalletBalanceView.as_view()),
    path('bank-details/', BankDetailsView.as_view()),
    path('fund/', FundWalletView.as_view()),
]
