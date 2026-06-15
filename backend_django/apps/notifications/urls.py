from django.urls import path
from .views import (
    NotificationListView, UnreadCountView,
    MarkAllReadView, NotificationDetailView,
)

urlpatterns = [
    path('', NotificationListView.as_view()),
    path('unread-count/', UnreadCountView.as_view()),
    path('mark-all-read/', MarkAllReadView.as_view()),
    path('<uuid:pk>/', NotificationDetailView.as_view()),
]
