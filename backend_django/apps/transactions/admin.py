from django.contrib import admin
from .models import Transaction


@admin.register(Transaction)
class TransactionAdmin(admin.ModelAdmin):
    list_display = ('reference', 'user', 'type', 'amount', 'status', 'network', 'phone_number', 'created_at')
    list_filter = ('type', 'status', 'network', 'tenant')
    search_fields = ('reference', 'user__phone_number', 'phone_number')
    ordering = ('-created_at',)
    readonly_fields = ('id', 'reference', 'created_at')
    raw_id_fields = ('user',)
