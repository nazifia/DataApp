from django import forms
from django.contrib import admin
from .models import Tenant
from .services import provision_tenant_owner


class TenantAdminForm(forms.ModelForm):
    owner_password = forms.CharField(
        required=False,
        widget=forms.PasswordInput(render_value=False),
        help_text="Owner login password. Leave blank to auto-generate one "
                  "(shown after save). Setting it on an existing tenant resets "
                  "the owner's password.",
    )

    class Meta:
        model = Tenant
        fields = '__all__'


@admin.register(Tenant)
class TenantAdmin(admin.ModelAdmin):
    form = TenantAdminForm

    def save_model(self, request, obj, form, change):
        super().save_model(request, obj, form, change)
        # Always ensure a login-capable owner exists. A password typed into the
        # form resets it; otherwise a new tenant gets a generated password.
        typed = form.cleaned_data.get('owner_password') or None
        user, raw_password = provision_tenant_owner(
            obj, password=typed, reset_password=bool(typed),
        )
        from django.contrib import messages
        if raw_password:
            messages.warning(
                request,
                f"Owner login ready — phone: {user.phone_number}, "
                f"password: {raw_password} (shown once, save it now).",
            )
        else:
            messages.info(
                request,
                f"Owner account already exists for {user.phone_number} "
                f"(password unchanged).",
            )
    list_display = ('name', 'slug', 'owner_email', 'owner_phone', 'is_active', 'created_at')
    list_filter = ('is_active',)
    search_fields = ('name', 'slug', 'owner_email', 'owner_phone')
    readonly_fields = ('id', 'created_at', 'updated_at')
    fieldsets = (
        (None, {
            'fields': ('id', 'name', 'slug', 'is_active'),
        }),
        ('Owner', {
            'fields': ('owner_email', 'owner_phone', 'owner_password'),
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
