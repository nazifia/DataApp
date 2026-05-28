from .models import AdminAuditLog


def log_action(request, action: str, target_type='', target_id='', details=''):
    ip = request.META.get('HTTP_X_FORWARDED_FOR', request.META.get('REMOTE_ADDR', ''))
    if ',' in ip:
        ip = ip.split(',')[0].strip()
    AdminAuditLog.objects.create(
        tenant=request.tenant,
        admin=request.user,
        action=action,
        target_type=target_type,
        target_id=str(target_id),
        details=details,
        ip_address=ip or None,
    )
