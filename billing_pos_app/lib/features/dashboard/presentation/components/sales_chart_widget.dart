import "package:flutter/material.dart";
import "package:billing_pos_app/core/theme/app_colors.dart";
import "package:billing_pos_app/core/utilities/currency_formatter.dart";
import "package:billing_pos_app/shared/widgets/app_card.dart";
import "package:billing_pos_app/features/dashboard/models/dashboard_models.dart";

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
    final points = _showDaily ? widget.dailyPoints : widget.monthlyPoints;
    final maxAmount = points.fold<double>(
      0.0,
      (max, p) => p.amount > max ? p.amount : max,
    );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _showDaily ? "Hourly Sales (Today)" : "Last 7 Days Sales Trend",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment<bool>(
                    value: true,
                    label: Text("Today", style: TextStyle(fontSize: 12)),
                  ),
                  ButtonSegment<bool>(
                    value: false,
                    label: Text("7 Days", style: TextStyle(fontSize: 12)),
                  ),
                ],
                selected: {_showDaily},
                onSelectionChanged: (newVal) {
                  setState(() {
                    _showDaily = newVal.first;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (points.isEmpty)
            const SizedBox(
              height: 180,
              child: Center(
                child: Text("No transaction data recorded for this view"),
              ),
            )
          else
            SizedBox(
              height: 200,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: points.map((p) {
                  final ratio = maxAmount > 0 ? (p.amount / maxAmount).clamp(0.05, 1.0) : 0.05;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            CurrencyFormatter.format(p.amount),
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: FractionallySizedBox(
                                heightFactor: ratio,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _showDaily
                                        ? AppColors.primary
                                        : AppColors.secondary,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            p.label,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
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
}
