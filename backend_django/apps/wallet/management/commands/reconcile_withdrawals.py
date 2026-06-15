"""Reconcile withdrawals stuck in `pending` against Paystack.

Webhook fallback: if a `transfer.success`/`transfer.failed`/`transfer.reversed`
event is missed, pending withdrawals would otherwise never settle. This command
queries each pending transfer's current status and settles it — crediting the
user on success or refunding the wallet on failure/reversal.

Schedule every ~10 minutes:
  * Linux cron:        */10 * * * * cd /app && python manage.py reconcile_withdrawals
  * Windows Scheduler: task running `python manage.py reconcile_withdrawals` every 10 min

Only touches withdrawals older than --min-age-seconds (default 120s) so it does
not race the synchronous response of a transfer just initiated.
"""
from datetime import timedelta

from django.core.management.base import BaseCommand
from django.utils import timezone

from apps.wallet.models import Withdrawal
from apps.wallet.views import settle_pending_withdrawal


class Command(BaseCommand):
    help = 'Settle pending withdrawals by polling Paystack transfer status.'

    def add_arguments(self, parser):
        parser.add_argument('--limit', type=int, default=200,
                            help='Max withdrawals to process in one run.')
        parser.add_argument('--min-age-seconds', type=int, default=120,
                            help='Skip withdrawals newer than this (avoid racing the API response).')

    def handle(self, *args, **options):
        cutoff = timezone.now() - timedelta(seconds=options['min_age_seconds'])
        pending = (
            Withdrawal.all_objects
            .filter(status='pending', created_at__lte=cutoff)
            .order_by('created_at')[:options['limit']]
        )
        processed = succeeded = reversed_ = still_pending = 0
        for wd in pending:
            processed += 1
            status = settle_pending_withdrawal(wd, source='reconcile')
            if status == 'success':
                succeeded += 1
            elif status in ('failed', 'reversed'):
                reversed_ += 1
            else:
                still_pending += 1

        self.stdout.write(self.style.SUCCESS(
            f'reconcile_withdrawals: processed={processed} succeeded={succeeded} '
            f'reversed={reversed_} still_pending={still_pending}'
        ))
