import 'package:flutter/material.dart';
import 'package:resonance_network_wallet/v2/theme/app_colors.dart';
import 'package:resonance_network_wallet/v2/theme/app_text_styles.dart';

class SegmentedControls<T> extends StatelessWidget {
  final List<SegmentedControlItem<T>> items;
  final T selectedValue;
  final ValueChanged<T> onChanged;

  static const double _padding = 5.0;
  static const double _outerRadius = 10.5;
  static const double _pillRadius = 8.0;
  static const double _verticalPadding = 14.0;
  static const Duration _duration = Duration(milliseconds: 300);

  const SegmentedControls({super.key, required this.items, required this.selectedValue, required this.onChanged})
    : assert(items.length >= 2, 'SegmentedControls requires at least 2 items');

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final selectedIndex = items.indexWhere((item) => item.value == selectedValue);

    return Container(
      padding: const EdgeInsets.all(_padding),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(_outerRadius),
        border: Border.all(color: const Color(0xFF191919), width: 1.5),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segmentWidth = constraints.maxWidth / items.length;
          final pillLeft = selectedIndex * segmentWidth;

          return SizedBox(
            height: _verticalPadding * 2 + 22,
            child: Stack(
              children: [
                // Sliding pill
                AnimatedPositioned(
                  duration: _duration,
                  curve: Curves.easeInOut,
                  left: pillLeft,
                  top: 0,
                  bottom: 0,
                  width: segmentWidth,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1C),
                      borderRadius: BorderRadius.circular(_pillRadius),
                    ),
                  ),
                ),
                // Labels row
                Row(
                  children: items.mapIndexed((index, item) {
                    final isSelected = index == selectedIndex;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => onChanged(item.value),
                        behavior: HitTestBehavior.opaque,
                        child: SizedBox(
                          height: double.infinity,
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: _duration,
                              curve: Curves.easeInOut,
                              style: (context.themeText.smallTitle ?? const TextStyle(fontSize: 18)).copyWith(
                                color: isSelected ? colors.textPrimary : const Color(0xFF363636),
                                fontWeight: FontWeight.w400,
                              ),
                              child: Text(item.label, textAlign: TextAlign.center),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

extension _IterableIndexed<T> on Iterable<T> {
  List<R> mapIndexed<R>(R Function(int index, T item) f) {
    var index = 0;
    return map((item) => f(index++, item)).toList();
  }
}

class SegmentedControlItem<T> {
  final T value;
  final String label;

  const SegmentedControlItem({required this.value, required this.label});
}
