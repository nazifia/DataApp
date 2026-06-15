from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import serializers
from core.validators import NigerianPhoneField, NetworkChoiceField
from .models import Beneficiary

VALID_NETWORKS = ('mtn', 'airtel', 'glo', 'etisalat')
VALID_TYPES = ('airtime', 'data')


class BeneficiarySerializer(serializers.ModelSerializer):
    class Meta:
        model = Beneficiary
        fields = ['id', 'nickname', 'phone_number', 'network', 'type', 'created_at']


class BeneficiaryCreateSerializer(serializers.Serializer):
    nickname = serializers.CharField(max_length=100, allow_blank=True, default='')
    phone_number = NigerianPhoneField()
    network = NetworkChoiceField()
    type = serializers.ChoiceField(choices=VALID_TYPES, default='airtime')


class BeneficiaryListCreateView(APIView):
    def get(self, request):
        qs = Beneficiary.objects.filter(user=request.user)
        type_filter = request.query_params.get('type')
        if type_filter in VALID_TYPES:
            qs = qs.filter(type=type_filter)
        return Response(BeneficiarySerializer(qs, many=True).data)

    def post(self, request):
        ser = BeneficiaryCreateSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        d = ser.validated_data

        obj, created = Beneficiary.objects.get_or_create(
            tenant=request.tenant,
            user=request.user,
            phone_number=d['phone_number'],
            network=d['network'],
            type=d['type'],
            defaults={'nickname': d.get('nickname', '')},
        )
        if not created and d.get('nickname'):
            obj.nickname = d['nickname']
            obj.save(update_fields=['nickname'])

        return Response(BeneficiarySerializer(obj).data, status=201 if created else 200)


class BeneficiaryDetailView(APIView):
    def delete(self, request, pk):
        try:
            obj = Beneficiary.objects.get(user=request.user, pk=pk)
        except Beneficiary.DoesNotExist:
            return Response({'detail': 'Not found.'}, status=404)
        obj.delete()
        return Response(status=204)

    def patch(self, request, pk):
        try:
            obj = Beneficiary.objects.get(user=request.user, pk=pk)
        except Beneficiary.DoesNotExist:
            return Response({'detail': 'Not found.'}, status=404)
        nickname = request.data.get('nickname', '').strip()
        obj.nickname = nickname
        obj.save(update_fields=['nickname'])
        return Response(BeneficiarySerializer(obj).data)
