// Transaction PIN Input Dialog
import 'package:flutter/material.dart';
import '../constants/theme.dart';

class PinInputDialog {
  /// Shows the PIN entry bottom sheet and returns the entered PIN string,
  /// or null if dismissed. Use for both setting and verifying PIN.
  static Future<String?> show(
    BuildContext context, {
    String title = 'Enter Transaction PIN',
    String? subtitle,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _PinInputSheet(title: title, subtitle: subtitle),
    );
  }
}

class _PinInputSheet extends StatefulWidget {
  final String title;
  final String? subtitle;

  const _PinInputSheet({required this.title, this.subtitle});

  @override
  State<_PinInputSheet> createState() => _PinInputSheetState();
}

class _PinInputSheetState extends State<_PinInputSheet> {
  String _pin = '';

  void _onKey(String value) {
    if (_pin.length < 4) {
      setState(() => _pin += value);
      if (_pin.length == 4) {
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) Navigator.of(context).pop(_pin);
        });
      }
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty) {
      setState(() => _pin = _pin.substring(0, _pin.length - 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Icon(Icons.lock_rounded, size: 36, color: AppColors.primary),
            const SizedBox(height: 12),
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            if (widget.subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                widget.subtitle!,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 28),
            // PIN dot indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                final filled = i < _pin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled ? AppColors.primary : Colors.transparent,
                    border: Border.all(
                      color: filled ? AppColors.primary : AppColors.textHint,
                      width: 2,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),
            // Numeric keypad rows
            ...[
              ['1', '2', '3'],
              ['4', '5', '6'],
              ['7', '8', '9'],
              ['', '0', '⌫'],
            ].map((row) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: row.map((k) {
                    if (k.isEmpty) return const SizedBox(width: 100);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: GestureDetector(
                        onTap: k == '⌫' ? _onBackspace : () => _onKey(k),
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: k == '⌫'
                                ? Colors.transparent
                                : AppColors.background,
                            border: k == '⌫'
                                ? null
                                : Border.all(color: AppColors.divider),
                          ),
                          child: Center(
                            child: k == '⌫'
                                ? const Icon(
                                    Icons.backspace_outlined,
                                    color: AppColors.textSecondary,
                                    size: 22,
                                  )
                                : Text(
                                    k,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
