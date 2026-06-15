from django.contrib import admin
from .models import Wallet, Withdrawal


@admin.register(Wallet)
class WalletAdmin(admin.ModelAdmin):
    list_display = ('user', 'balance', 'tenant', 'created_at', 'updated_at')
    list_filter = ('tenant',)
    search_fields = ('user__phone_number', 'user__full_name')
    readonly_fields = ('id', 'created_at', 'updated_at')
    raw_id_fields = ('user',)

    def tenant(self, obj):
        return obj.user.tenant
    tenant.short_description = 'Tenant'
    tenant.admin_order_field = 'user__tenant'


@admin.register(Withdrawal)
class WithdrawalAdmin(admin.ModelAdmin):
    list_display = ('reference', 'user', 'amount', 'fee', 'bank_name',
                    'account_number', 'status', 'created_at')
    list_filter = ('status', 'tenant', 'bank_name')
    search_fields = ('reference', 'user__phone_number', 'account_number',
                     'account_name')
    readonly_fields = ('id', 'created_at', 'updated_at', 'recipient_code',
                       'transfer_code')
    raw_id_fields = ('user',)
