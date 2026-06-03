from django.contrib import admin
from .models import Beneficiary


@admin.register(Beneficiary)
class BeneficiaryAdmin(admin.ModelAdmin):
    list_display = ['user', 'nickname', 'phone_number', 'network', 'type', 'created_at']
    list_filter = ['network', 'type', 'tenant']
    search_fields = ['phone_number', 'nickname', 'user__phone_number']
    raw_id_fields = ['user']
