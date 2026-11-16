import "package:flutter/material.dart";
import "../../core/theme/app_colors.dart";

enum BadgeType { success, warning, error, info, neutral }

class StatusBadge extends StatelessWidget {
  final String? label;
  final String? status;
  final BadgeType type;
  final IconData? icon;

  const StatusBadge({
    super.key,
    this.label,
    this.status,
    this.type = BadgeType.neutral,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final text = status ?? label ?? "";
    var effectiveType = type;
    var displayText = text;

    if (text.toLowerCase() == "held" || text.toLowerCase() == "hold") {
      displayText = "Hold Bill";
    }

    if (effectiveType == BadgeType.neutral && text.isNotEmpty) {
      final lower = text.toLowerCase();
      if (lower == "active" || lower == "success" || lower == "completed") {
        effectiveType = BadgeType.success;
      } else if (lower == "inactive" || lower == "failed" || lower == "error" || lower == "cancelled") {
        effectiveType = BadgeType.error;
      } else if (lower == "pending" || lower == "warning" || lower == "held" || lower == "hold" || lower == "hold bill") {
        effectiveType = BadgeType.warning;
      }
    }

    Color bg;
    Color fg;

    switch (effectiveType) {
      case BadgeType.success:
        bg = AppColors.successContainer;
        fg = AppColors.success;
        break;
      case BadgeType.warning:
        bg = AppColors.secondaryContainer;
        fg = AppColors.secondary;
        break;
      case BadgeType.error:
        bg = AppColors.errorContainer;
        fg = AppColors.error;
        break;
      case BadgeType.info:
        bg = const Color(0xFFDBEAFE);
        fg = AppColors.info;
        break;
      case BadgeType.neutral:
        bg = const Color(0xFFE2E8F0);
        fg = const Color(0xFF475569);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            displayText,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

