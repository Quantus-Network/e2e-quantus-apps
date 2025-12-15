import 'package:flutter/material.dart';
import 'package:resonance_network_wallet/features/components/select.dart';
import 'package:resonance_network_wallet/features/styles/app_colors_theme.dart';
import 'package:resonance_network_wallet/features/styles/app_text_theme.dart';

class SelectActionSheet<T> extends StatefulWidget {
  final List<Item<T>> items;
  final Function(Item<T>) onSelect;

  const SelectActionSheet({super.key, required this.items, required this.onSelect});

  @override
  State<SelectActionSheet<T>> createState() => _SelectActionSheetState<T>();
}

class _SelectActionSheetState<T> extends State<SelectActionSheet<T>> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.only(top: 10, left: 34, right: 10, bottom: 10),
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.9)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: widget.items.map((item) {
            return InkWell(
              onTap: () {
                Navigator.pop(context);
                Future.microtask(() => widget.onSelect(item));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(item.label, style: context.themeText.paragraph?.copyWith(color: context.themeColors.light)),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

void showSelectActionSheet<T>(BuildContext context, List<Item<T>> items, Function(Item<T>) onSelect) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    builder: (context) => SelectActionSheet<T>(items: items, onSelect: onSelect),
  );
}
