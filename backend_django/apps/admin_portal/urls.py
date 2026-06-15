from django.urls import path
from .views import (
    DashboardStatsView, RecentTransactionsView, RecentUsersView,
    AdminUserListView, AdminUserDetailView,
    AdminWalletListView, AdminWalletAdjustView,
    AdminTransactionListView, AdminTransactionDetailView, AdminReverseTransactionView,
    AnalyticsRevenueView, AnalyticsNetworkView, AnalyticsTopUsersView, AnalyticsTypeBreakdownView,
    AuditLogListView,
    BusinessSettingsView, BusinessEarningsView,
)
from apps.disputes.views import AdminDisputeListView, AdminDisputeDetailView

urlpatterns = [
    # Dashboard
    path('dashboard/stats/', DashboardStatsView.as_view()),
    path('dashboard/recent-transactions/', RecentTransactionsView.as_view()),
    path('dashboard/recent-users/', RecentUsersView.as_view()),
    # Users
    path('users/', AdminUserListView.as_view()),
    path('users/<uuid:pk>/', AdminUserDetailView.as_view()),
    # Wallets
    path('wallets/', AdminWalletListView.as_view()),
    path('wallets/<uuid:user_id>/credit/', AdminWalletAdjustView.as_view(), {'action': 'credit'}),
    path('wallets/<uuid:user_id>/debit/', AdminWalletAdjustView.as_view(), {'action': 'debit'}),
    # Transactions
    path('transactions/', AdminTransactionListView.as_view()),
    path('transactions/<uuid:pk>/', AdminTransactionDetailView.as_view()),
    path('transactions/<uuid:pk>/reverse/', AdminReverseTransactionView.as_view()),
    # Business owner settings
    path('settings/', BusinessSettingsView.as_view()),
    # Analytics
    path('analytics/revenue/', AnalyticsRevenueView.as_view()),
    path('analytics/earnings/', BusinessEarningsView.as_view()),
    path('analytics/network-distribution/', AnalyticsNetworkView.as_view()),
    path('analytics/top-users/', AnalyticsTopUsersView.as_view()),
    path('analytics/transaction-types/', AnalyticsTypeBreakdownView.as_view()),
    # Audit
    path('audit-logs/', AuditLogListView.as_view()),
    # Disputes
    path('disputes/', AdminDisputeListView.as_view()),
    path('disputes/<uuid:pk>/', AdminDisputeDetailView.as_view()),
]
