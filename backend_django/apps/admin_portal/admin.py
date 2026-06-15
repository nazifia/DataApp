from django.contrib import admin
from .models import AdminAuditLog, RuntimeConfig


@admin.register(RuntimeConfig)
class RuntimeConfigAdmin(admin.ModelAdmin):
    list_display = ('__str__', 'dev_mode', 'updated_at')
    readonly_fields = ('updated_at',)

    def has_add_permission(self, request):
        # Singleton — only one row allowed.
        return not RuntimeConfig.objects.exists()

    def has_delete_permission(self, request, obj=None):
        return False


@admin.register(AdminAuditLog)
class AdminAuditLogAdmin(admin.ModelAdmin):
    list_display = ('action', 'admin', 'target_type', 'target_id', 'ip_address', 'tenant', 'created_at')
    list_filter = ('action', 'target_type', 'tenant')
    search_fields = ('action', 'target_type', 'target_id', 'admin__phone_number', 'details')
    readonly_fields = ('id', 'created_at', 'admin', 'action', 'target_type', 'target_id', 'details', 'ip_address', 'tenant')
    ordering = ('-created_at',)

    def has_add_permission(self, request):
        return False

    def has_change_permission(self, request, obj=None):
        return False
