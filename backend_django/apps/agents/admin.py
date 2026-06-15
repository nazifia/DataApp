from django.contrib import admin
from .models import Agent


@admin.register(Agent)
class AgentAdmin(admin.ModelAdmin):
    list_display = ('agent_code', 'business_name', 'status', 'commission_percent', 'created_at')
    list_filter = ('status',)
    search_fields = ('agent_code', 'business_name', 'user__phone_number')
    list_editable = ('status', 'commission_percent')
    readonly_fields = ('agent_code',)
