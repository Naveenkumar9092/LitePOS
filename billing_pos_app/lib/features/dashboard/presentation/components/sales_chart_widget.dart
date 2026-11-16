import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";
import "package:billing_pos_app/core/theme/app_colors.dart";
import "package:billing_pos_app/core/utilities/currency_formatter.dart";
import "package:billing_pos_app/features/dashboard/models/dashboard_models.dart";
import "package:billing_pos_app/shared/widgets/glass_card.dart";

class SalesChartWidget extends StatefulWidget {
  final List<SalesGraphPointModel> dailyPoints;
  final List<SalesGraphPointModel> monthlyPoints;

  const SalesChartWidget({
    super.key,
    required this.dailyPoints,
    required this.monthlyPoints,
  });

  @override
  State<SalesChartWidget> createState() => _SalesChartWidgetState();
}

class _SalesChartWidgetState extends State<SalesChartWidget> {
  bool _showDaily = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final points = _showDaily ? widget.dailyPoints : widget.monthlyPoints;
    final maxAmount = points.fold<double>(
      0.0,
      (max, p) => p.amount > max ? p.amount : max,
    );

    final activeNeonColor = _showDaily ? AppColors.neonCyan : AppColors.neonViolet;

    return GlassCard(
      borderRadius: 18,
      glowColor: activeNeonColor,
      glowOpacity: isDark ? 0.12 : 0.06,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                      color: activeNeonColor,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: activeNeonColor.withValues(alpha: 0.6),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _showDaily ? "Hourly Sales Velocity" : "7-Day Revenue Trend",
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              // Modern glassy segmented control
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.07) : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.06),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildToggleItem("Today", _showDaily, () {
                      setState(() => _showDaily = true);
                    }, AppColors.neonCyan),
                    const SizedBox(width: 4),
                    _buildToggleItem("7 Days", !_showDaily, () {
                      setState(() => _showDaily = false);
                    }, AppColors.neonViolet),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (points.isEmpty)
            SizedBox(
              height: 200,
              child: Center(
                child: Text(
                  "No transaction data recorded for this view",
                  style: GoogleFonts.dmSans(
                    color: isDark ? Colors.white54 : AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 210,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: points.map((p) {
                  final ratio = maxAmount > 0 ? (p.amount / maxAmount).clamp(0.06, 1.0) : 0.06;
                  final isPeak = p.amount == maxAmount && maxAmount > 0;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            CurrencyFormatter.format(p.amount),
                            style: GoogleFonts.dmSans(
                              fontSize: 9,
                              fontWeight: isPeak ? FontWeight.w800 : FontWeight.w600,
                              color: isPeak ? activeNeonColor : (isDark ? Colors.white70 : AppColors.textSecondary),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: FractionallySizedBox(
                                heightFactor: ratio,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: _showDaily
                                          ? [
                                              AppColors.neonCyan,
                                              AppColors.neonBlue.withValues(alpha: isDark ? 0.4 : 0.7),
                                            ]
                                          : [
                                              AppColors.neonViolet,
                                              AppColors.neonPurple.withValues(alpha: isDark ? 0.4 : 0.7),
                                            ],
                                    ),
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(6),
                                    ),
                                    boxShadow: isPeak
                                        ? [
                                            BoxShadow(
                                              color: activeNeonColor.withValues(alpha: 0.45),
                                              blurRadius: 10,
                                              spreadRadius: 1,
                                            ),
                                          ]
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            p.label,
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              fontWeight: isPeak ? FontWeight.bold : FontWeight.w500,
                              color: isPeak
                                  ? (isDark ? Colors.white : AppColors.textPrimary)
                                  : (isDark ? Colors.white54 : AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildToggleItem(String label, bool isSelected, VoidCallback onTap, Color neonColor) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? neonColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: neonColor.withValues(alpha: 0.35),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
