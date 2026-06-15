"""Sweep transactions stuck in `retrying` and re-attempt provider fulfilment.

Schedule every ~5 minutes:
  * Linux cron:        */5 * * * * cd /app && python manage.py retry_transactions
  * Windows Scheduler: task running `python manage.py retry_transactions` every 5 min

Each due transaction is passed back through apps.transactions.fulfillment.fulfill,
which resolves it to `success`, reschedules another `retrying` attempt, or — once
retries are exhausted — refunds the wallet and marks it `failed`.
"""
from django.core.management.base import BaseCommand
from django.utils import timezone

from apps.transactions.models import Transaction
from apps.transactions.fulfillment import fulfill


class Command(BaseCommand):
    help = 'Retry transactions in the "retrying" state whose next_retry_at is due.'

    def add_arguments(self, parser):
        parser.add_argument('--limit', type=int, default=200,
                             help='Max transactions to process in one run.')

    def handle(self, *args, **options):
        now = timezone.now()
        due = (
            Transaction.all_objects
            .filter(status='retrying', next_retry_at__lte=now)
            .order_by('next_retry_at')[:options['limit']]
        )
        processed = succeeded = failed = rescheduled = 0
        for txn in due:
            processed += 1
            fulfill(txn)
            if txn.status == 'success':
                succeeded += 1
            elif txn.status == 'failed':
                failed += 1
            else:
                rescheduled += 1

        self.stdout.write(self.style.SUCCESS(
            f'retry_transactions: processed={processed} succeeded={succeeded} '
            f'failed={failed} rescheduled={rescheduled}'
        ))
