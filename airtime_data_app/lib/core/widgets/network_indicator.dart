// Network Status Indicator Widget
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class NetworkIndicator extends StatelessWidget {
  final bool isConnected;
  final String? message;

  const NetworkIndicator({
    super.key,
    required this.isConnected,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.defaultPadding,
        vertical: AppConstants.smallPadding,
      ),
      decoration: BoxDecoration(
        color: isConnected ? Colors.green[100] : Colors.red[100],
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        border: Border.all(
          color: isConnected ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isConnected ? Icons.wifi : Icons.wifi_off,
            color: isConnected ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            message ??
                (isConnected
                    ? 'Connected'
                    : 'No Internet Connection'),
            style: TextStyle(
              color: isConnected ? Colors.green[800] : Colors.red[800],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}