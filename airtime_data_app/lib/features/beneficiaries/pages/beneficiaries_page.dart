import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/beneficiary_bloc.dart';
import '../event/beneficiary_event.dart';
import '../state/beneficiary_state.dart';
import '../models/beneficiary.dart';
import '../../../core/constants/theme.dart';

class BeneficiariesPage extends StatefulWidget {
  final String? filterType;
  final bool selectMode;

  const BeneficiariesPage({super.key, this.filterType, this.selectMode = false});

  @override
  State<BeneficiariesPage> createState() => _BeneficiariesPageState();
}

class _BeneficiariesPageState extends State<BeneficiariesPage> {
  @override
  void initState() {
    super.initState();
    context.read<BeneficiaryBloc>().add(LoadBeneficiariesEvent(type: widget.filterType));
  }

  Color _networkColor(String network) {
    switch (network.toLowerCase()) {
      case 'mtn': return AppColors.mtn;
      case 'airtel': return AppColors.airtel;
      case 'glo': return AppColors.glo;
      case 'etisalat': return AppColors.nineMobile;
      default: return AppColors.primary;
    }
  }

  void _confirmDelete(BuildContext context, Beneficiary b) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Beneficiary'),
        content: Text('Remove ${b.displayName} from your beneficiaries?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<BeneficiaryBloc>().add(DeleteBeneficiaryEvent(b.id));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _editNickname(BuildContext context, Beneficiary b) {
    final ctrl = TextEditingController(text: b.nickname);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Nickname'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Nickname (optional)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<BeneficiaryBloc>().add(
                UpdateBeneficiaryNicknameEvent(id: b.id, nickname: ctrl.text.trim()),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.selectMode ? 'Select Beneficiary' : 'Saved Beneficiaries'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocConsumer<BeneficiaryBloc, BeneficiaryState>(
        listener: (context, state) {
          if (state is BeneficiaryFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
            );
          }
        },
        builder: (context, state) {
          if (state is BeneficiaryLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is BeneficiaryLoaded) {
            if (state.beneficiaries.isEmpty) {
              return _buildEmpty();
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.beneficiaries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) => _buildItem(ctx, state.beneficiaries[i]),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_alt_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No saved beneficiaries yet',
            style: TextStyle(fontSize: 16, color: Colors.grey[500], fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'They appear here after you purchase airtime or data',
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, Beneficiary b) {
    final color = _networkColor(b.network);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        onTap: widget.selectMode ? () => Navigator.pop(context, b) : null,
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Text(
            b.displayName.isNotEmpty ? b.displayName[0].toUpperCase() : '?',
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ),
        title: Text(b.displayName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(
          '${b.phoneNumber} · ${b.network.toUpperCase()}',
          style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
        ),
        trailing: widget.selectMode
            ? Icon(Icons.chevron_right_rounded, color: Theme.of(context).colorScheme.outlineVariant)
            : PopupMenuButton<String>(
                onSelected: (action) {
                  if (action == 'edit') _editNickname(context, b);
                  if (action == 'delete') _confirmDelete(context, b);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit nickname')),
                  PopupMenuItem(value: 'delete', child: Text('Remove')),
                ],
              ),
      ),
    );
  }
}
