from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('wallet', '0001_initial'),
    ]

    operations = [
        migrations.AddField(
            model_name='wallet',
            name='paystack_customer_code',
            field=models.CharField(blank=True, max_length=100),
        ),
        migrations.AddField(
            model_name='wallet',
            name='paystack_account_number',
            field=models.CharField(blank=True, max_length=20),
        ),
        migrations.AddField(
            model_name='wallet',
            name='paystack_bank_name',
            field=models.CharField(blank=True, max_length=100),
        ),
        migrations.AddField(
            model_name='wallet',
            name='paystack_account_name',
            field=models.CharField(blank=True, max_length=200),
        ),
    ]
