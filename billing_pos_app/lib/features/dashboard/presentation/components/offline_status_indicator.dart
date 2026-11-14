import "package:flutter/material.dart";
import "package:billing_pos_app/core/theme/app_colors.dart";

class OfflineStatusIndicator extends StatelessWidget {
  final bool isOnline;
  final int pendingSyncCount;
  final VoidCallback? onSyncTap;

  const OfflineStatusIndicator({
    super.key,
    this.isOnline = true,
    this.pendingSyncCount = 0,
    this.onSyncTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onSyncTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isOnline
              ? Colors.green.withValues(alpha: 0.12)
              : Colors.orange.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isOnline ? Colors.green.shade400 : Colors.orange.shade400,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isOnline ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              isOnline ? "ONLINE" : "OFFLINE (SQLite)",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isOnline ? Colors.green.shade800 : Colors.orange.shade900,
              ),
            ),
            if (pendingSyncCount > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "$pendingSyncCount",
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
