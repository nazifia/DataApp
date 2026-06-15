from django.contrib import admin
from .models import Notification


@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ('title', 'user', 'type', 'is_read', 'created_at')
    list_filter = ('is_read', 'type', 'created_at')
    search_fields = ('title', 'body', 'user__phone_number')
    readonly_fields = ('created_at',)
    raw_id_fields = ('user', 'tenant')
