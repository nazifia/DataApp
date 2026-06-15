// Notifications Page — list, mark read, mark-all-read, swipe to delete.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/notifications_bloc.dart';
import '../event/notifications_event.dart';
import '../state/notifications_state.dart';
import '../../../core/constants/theme.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    context.read<NotificationsBloc>().add(const LoadNotificationsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          BlocBuilder<NotificationsBloc, NotificationsState>(
            builder: (context, state) {
              if (state.unreadCount == 0) return const SizedBox.shrink();
              return TextButton(
                onPressed: () => context
                    .read<NotificationsBloc>()
                    .add(const MarkAllReadEvent()),
                child: const Text('Mark all read'),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<NotificationsBloc, NotificationsState>(
        builder: (context, state) {
          if (state.loading && !state.loadedOnce) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.error != null && state.notifications.isEmpty) {
            return _errorView(state.error!);
          }
          if (state.notifications.isEmpty) return _emptyView();
          return RefreshIndicator(
            onRefresh: () async => context
                .read<NotificationsBloc>()
                .add(const LoadNotificationsEvent()),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount: state.notifications.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _notificationCard(state.notifications[i]),
            ),
          );
        },
      ),
    );
  }

  Widget _notificationCard(Map<String, dynamic> n) {
    final cs = Theme.of(context).colorScheme;
    final id = (n['id'] ?? '').toString();
    final isRead = n['is_read'] == true;
    final type = (n['type'] ?? '').toString();
    final (icon, color) = _typeStyle(type);

    return Dismissible(
      key: ValueKey(id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: AppColors.error),
      ),
      onDismissed: (_) => context
          .read<NotificationsBloc>()
          .add(DeleteNotificationEvent(id)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: isRead
            ? null
            : () => context
                .read<NotificationsBloc>()
                .add(MarkReadEvent(id)),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isRead
                ? cs.surface
                : AppColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            (n['title'] ?? '').toString(),
                            style: TextStyle(
                              fontWeight:
                                  isRead ? FontWeight.w600 : FontWeight.w800,
                              fontSize: 14.5,
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 6, top: 4),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    if ((n['body'] ?? '').toString().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        (n['body'] ?? '').toString(),
                        style: TextStyle(
                            fontSize: 13,
                            color: cs.onSurface.withValues(alpha: 0.7)),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      _formatDate(n['created_at']),
                      style: TextStyle(
                          fontSize: 11.5,
                          color: cs.onSurface.withValues(alpha: 0.5)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  (IconData, Color) _typeStyle(String type) {
    switch (type) {
      case 'wallet':
        return (Icons.account_balance_wallet_rounded, AppColors.warning);
      case 'transaction':
        return (Icons.receipt_long_rounded, AppColors.success);
      case 'dispute':
        return (Icons.support_agent_rounded, AppColors.info);
      case 'referral':
        return (Icons.card_giftcard_rounded, AppColors.success);
      default:
        return (Icons.notifications_rounded, AppColors.primary);
    }
  }

  String _formatDate(dynamic raw) {
    final parsed = DateTime.tryParse(raw?.toString() ?? '');
    if (parsed == null) return '';
    final local = parsed.toLocal();
    final diff = DateTime.now().difference(local);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('d MMM yyyy, h:mm a').format(local);
  }

  Widget _emptyView() {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_off_outlined,
                size: 56, color: cs.onSurface.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            const Text('No notifications yet',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              "We'll let you know when something happens on your account.",
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: cs.onSurface.withValues(alpha: 0.6)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorView(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context
                  .read<NotificationsBloc>()
                  .add(const LoadNotificationsEvent()),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
