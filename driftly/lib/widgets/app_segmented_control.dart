import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SegmentItem<T> {
  final T value;
  final String label;
  final String? emoji;

  const SegmentItem({required this.value, required this.label, this.emoji});
}

/// Full-width two-or-more-way segmented control — active segment is a solid
/// teal pill with black text, inactive segments are transparent with grey
/// text. Used for the Hangouts / Hot Zones switch.
class AppSegmentedControl<T> extends StatelessWidget {
  final List<SegmentItem<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  const AppSegmentedControl({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceSolid,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: segments.map((segment) {
          final isSelected = segment.value == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(segment.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.teal : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (segment.emoji != null) ...[
                      Text(segment.emoji!, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      segment.label,
                      style: TextStyle(
                        color: isSelected ? Colors.black : Colors.grey[400],
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
