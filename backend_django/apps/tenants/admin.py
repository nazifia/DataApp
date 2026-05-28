from django.contrib import admin
from .models import Tenant


@admin.register(Tenant)
class TenantAdmin(admin.ModelAdmin):
    list_display = ('name', 'slug', 'owner_email', 'owner_phone', 'is_active', 'created_at')
    list_filter = ('is_active',)
    search_fields = ('name', 'slug', 'owner_email', 'owner_phone')
    readonly_fields = ('id', 'created_at', 'updated_at')
    fieldsets = (
        (None, {
            'fields': ('id', 'name', 'slug', 'is_active'),
        }),
        ('Owner', {
            'fields': ('owner_email', 'owner_phone'),
        }),
        ('Branding', {
            'fields': ('logo_url', 'primary_color', 'support_email', 'support_phone'),
        }),
        ('Business Config', {
            'fields': (
                'airtime_markup_percent',
                'data_markup_percent',
                'min_wallet_fund',
                'max_daily_transaction',
            ),
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',),
        }),
    )
