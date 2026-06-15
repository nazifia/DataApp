// Disputes Page — list own disputes & raise a new one.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/disputes_bloc.dart';
import '../event/disputes_event.dart';
import '../state/disputes_state.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/constants/theme.dart';

class DisputesPage extends StatefulWidget {
  const DisputesPage({super.key});

  @override
  State<DisputesPage> createState() => _DisputesPageState();
}

class _DisputesPageState extends State<DisputesPage> {
  List<Map<String, dynamic>> _disputes = [];
  bool _loadedOnce = false;

  @override
  void initState() {
    super.initState();
    context.read<DisputesBloc>().add(const LoadDisputesEvent());
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.error : null,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support & Disputes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateSheet,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Raise a Dispute'),
      ),
      body: BlocConsumer<DisputesBloc, DisputesState>(
        listener: (context, state) {
          if (state is DisputesLoaded) {
            setState(() {
              _disputes = state.disputes;
              _loadedOnce = true;
            });
          } else if (state is DisputeCreated) {
            _snack('Dispute submitted. Our team will review it.');
          } else if (state is DisputeCreateFailed) {
            _snack(state.message, error: true);
          } else if (state is DisputesError) {
            setState(() => _loadedOnce = true);
          }
        },
        builder: (context, state) {
          if (state is DisputesLoading && !_loadedOnce) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is DisputesError && _disputes.isEmpty) {
            return _errorView(state.message);
          }
          if (_disputes.isEmpty) return _emptyView();
          return RefreshIndicator(
            onRefresh: () async =>
                context.read<DisputesBloc>().add(const LoadDisputesEvent()),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: _disputes.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _disputeCard(_disputes[i]),
            ),
          );
        },
      ),
    );
  }

  Widget _disputeCard(Map<String, dynamic> d) {
    final cs = Theme.of(context).colorScheme;
    final status = (d['status'] ?? 'open').toString();
    final ref = (d['transaction_reference'] ?? '').toString();
    final notes = (d['admin_notes'] ?? '').toString();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  (d['subject'] ?? '').toString(),
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
              _statusChip(status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            (d['message'] ?? '').toString(),
            style: TextStyle(
                fontSize: 13, color: cs.onSurface.withValues(alpha: 0.7)),
          ),
          if (ref.isNotEmpty) ...[
            const SizedBox(height: 10),
            _metaRow(Icons.receipt_long_rounded, 'Ref: $ref'),
          ],
          const SizedBox(height: 6),
          _metaRow(Icons.schedule_rounded, _formatDate(d['created_at'])),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Support response',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.info)),
                  const SizedBox(height: 4),
                  Text(notes, style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _metaRow(IconData icon, String text) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 14, color: cs.onSurface.withValues(alpha: 0.5)),
        const SizedBox(width: 6),
        Text(text,
            style: TextStyle(
                fontSize: 12, color: cs.onSurface.withValues(alpha: 0.6))),
      ],
    );
  }

  Widget _statusChip(String status) {
    final map = {
      'open': (AppColors.warning, 'Open'),
      'in_review': (AppColors.info, 'In Review'),
      'resolved': (AppColors.success, 'Resolved'),
      'closed': (AppColors.textSecondary, 'Closed'),
    };
    final entry = map[status] ?? (AppColors.textSecondary, status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: entry.$1.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(entry.$2,
          style: TextStyle(
              color: entry.$1, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }

  String _formatDate(dynamic raw) {
    final parsed = DateTime.tryParse(raw?.toString() ?? '');
    if (parsed == null) return '';
    return DateFormat('d MMM yyyy, h:mm a').format(parsed.toLocal());
  }

  Widget _emptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.support_agent_rounded,
                size: 56,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            const Text('No disputes yet',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              'Got an issue with a transaction? Raise a dispute and our team will help.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6)),
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
                  .read<DisputesBloc>()
                  .add(const LoadDisputesEvent()),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _openCreateSheet() {
    final formKey = GlobalKey<FormState>();
    final refController = TextEditingController();
    final subjectController = TextEditingController();
    final messageController = TextEditingController();
    final bloc = context.read<DisputesBloc>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: BlocConsumer<DisputesBloc, DisputesState>(
            bloc: bloc,
            listener: (context, state) {
              if (state is DisputeCreated) Navigator.of(sheetContext).pop();
            },
            builder: (context, state) {
              final submitting = state is DisputeCreating;
              return Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Raise a Dispute',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: refController,
                      decoration: const InputDecoration(
                        labelText: 'Transaction reference (optional)',
                        prefixIcon: Icon(Icons.receipt_long_rounded),
                        hintText: 'e.g. TUN-...',
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: subjectController,
                      decoration: const InputDecoration(
                        labelText: 'Subject',
                        prefixIcon: Icon(Icons.title_rounded),
                      ),
                      validator: (v) => (v == null || v.trim().length < 5)
                          ? 'Subject must be at least 5 characters'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: messageController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Describe the issue',
                        alignLabelWithHint: true,
                      ),
                      validator: (v) => (v == null || v.trim().length < 10)
                          ? 'Please add at least 10 characters'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    CustomButton(
                      text: submitting ? 'Submitting...' : 'Submit Dispute',
                      isLoading: submitting,
                      onPressed: submitting
                          ? null
                          : () {
                              if (!(formKey.currentState?.validate() ??
                                  false)) {
                                return;
                              }
                              bloc.add(CreateDisputeEvent(
                                subject: subjectController.text.trim(),
                                message: messageController.text.trim(),
                                transactionReference:
                                    refController.text.trim(),
                              ));
                            },
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
