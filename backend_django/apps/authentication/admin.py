from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from .models import User, OTPRecord
from .forms import AdminUserCreationForm


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    add_form = AdminUserCreationForm
    list_display = ('phone_number', 'full_name', 'email', 'tenant', 'role', 'is_active', 'is_staff', 'created_at')
    list_filter = ('role', 'is_active', 'is_staff', 'tenant')
    search_fields = ('phone_number', 'full_name', 'email')
    ordering = ('-created_at',)
    readonly_fields = ('id', 'created_at', 'updated_at')

    fieldsets = (
        (None, {
            'fields': ('id', 'phone_number', 'password'),
        }),
        ('Personal Info', {
            'fields': ('full_name', 'email', 'profile_picture_url', 'device_id'),
        }),
        ('Tenant & Role', {
            'fields': ('tenant', 'role'),
        }),
        ('Permissions', {
            'fields': ('is_active', 'is_staff', 'is_superuser', 'groups', 'user_permissions'),
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',),
        }),
    )

    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('phone_number', 'tenant', 'role', 'password1', 'password2'),
        }),
    )


@admin.register(OTPRecord)
class OTPRecordAdmin(admin.ModelAdmin):
    list_display = ('phone_number', 'tenant', 'otp', 'expires_at', 'used', 'created_at')
    list_filter = ('used', 'tenant')
    search_fields = ('phone_number',)
    readonly_fields = ('created_at',)
