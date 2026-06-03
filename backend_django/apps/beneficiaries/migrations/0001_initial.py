import django.db.models.deletion
import django.utils.timezone
import uuid
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    initial = True

    dependencies = [
        ('tenants', '0001_initial'),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name='Beneficiary',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('nickname', models.CharField(blank=True, max_length=100)),
                ('phone_number', models.CharField(max_length=20)),
                ('network', models.CharField(choices=[('mtn', 'MTN'), ('airtel', 'Airtel'), ('glo', 'Glo'), ('etisalat', '9mobile')], max_length=20)),
                ('type', models.CharField(choices=[('airtime', 'Airtime'), ('data', 'Data')], default='airtime', max_length=10)),
                ('created_at', models.DateTimeField(default=django.utils.timezone.now)),
                ('tenant', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='+', to='tenants.tenant')),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='beneficiaries', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'db_table': 'beneficiaries',
                'ordering': ['nickname', 'phone_number'],
                'unique_together': {('user', 'phone_number', 'network', 'type')},
            },
        ),
    ]
