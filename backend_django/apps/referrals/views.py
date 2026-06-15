from decimal import Decimal
from django.db.models import Sum
from rest_framework.views import APIView
from rest_framework.response import Response
from apps.authentication.models import User
from .models import ReferralReward


class MyReferralsView(APIView):
    def get(self, request):
        user = request.user
        invited = User.objects.filter(referred_by=user).count()
        earned = (
            ReferralReward.all_objects
            .filter(referrer=user, status='paid')
            .aggregate(total=Sum('amount'))['total'] or Decimal('0')
        )
        bonus = request.tenant.referral_bonus if request.tenant else Decimal('0')
        return Response({
            'referral_code': user.referral_code,
            'invited_count': invited,
            'total_earned': float(earned),
            'bonus_per_referral': float(bonus),
        })
