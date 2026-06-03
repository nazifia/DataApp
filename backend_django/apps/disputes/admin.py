from django.contrib import admin
from .models import Dispute


@admin.register(Dispute)
class DisputeAdmin(admin.ModelAdmin):
    list_display = ['id', 'user', 'subject', 'status', 'transaction_reference', 'created_at']
    list_filter = ['status', 'tenant']
    search_fields = ['subject', 'transaction_reference', 'user__phone_number']
    raw_id_fields = ['user']
    readonly_fields = ['created_at', 'resolved_at']
