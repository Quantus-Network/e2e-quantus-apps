import 'package:flutter/material.dart';
import 'package:resonance_network_wallet/features/components/select_action_sheet.dart';
import 'package:resonance_network_wallet/features/styles/app_colors_theme.dart';
import 'package:resonance_network_wallet/features/styles/app_text_theme.dart';

class Item<T> {
  final T value;
  final String label;

  Item({required this.value, required this.label});

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Item && runtimeType == other.runtimeType && value == other.value;

  @override
  int get hashCode => value.hashCode;
}

class Select<T> extends StatefulWidget {
  final List<Item<T>> items;
  final T? initialValue;
  final Function(Item<T>) onSelect;
  final double width;
  final bool disabled;

  const Select({
    super.key,
    required this.items,
    required this.onSelect,
    this.initialValue,
    this.width = 200,
    this.disabled = false,
  });

  @override
  State<Select<T>> createState() => _SelectState<T>();
}

class _SelectState<T> extends State<Select<T>> {
  Item<T>? selectedValue;

  @override
  void initState() {
    super.initState();

    if (widget.initialValue != null) {
      selectedValue = widget.items.firstWhere(
        (item) => item.value == widget.initialValue,
        orElse: () => widget.items.first,
      );
    } else if (widget.items.isNotEmpty) {
      selectedValue = widget.items.first;
    }
  }

  void _onSelect(Item<T> item) {
    setState(() {
      selectedValue = item;
    });

    widget.onSelect(item);
  }

  void _openSelectActionSheet(BuildContext context) {
    showSelectActionSheet<T>(context, widget.items, _onSelect);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.disabled
          ? null
          : () {
              _openSelectActionSheet(context);
            },
      child: Container(
        width: widget.width,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: ShapeDecoration(
          color: widget.disabled ? Colors.grey.withValues(alpha: 0.50) : Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: Text(selectedValue?.label ?? 'Select...', style: context.themeText.smallParagraph)),
            const SizedBox(width: 12),
            Icon(Icons.keyboard_arrow_down, color: context.themeColors.textPrimary, size: 16),
          ],
        ),
      ),
    );
  }
}
