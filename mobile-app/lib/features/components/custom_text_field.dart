import 'package:flutter/material.dart';
import 'package:resonance_network_wallet/features/components/label.dart';
import 'package:resonance_network_wallet/features/styles/app_text_theme.dart';

class CustomTextField extends StatelessWidget {
  final String? labelText;
  final String? initialValue;
  final String? hintText;
  final Icon? icon;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;

  const CustomTextField({
    super.key,
    this.labelText,
    this.initialValue,
    this.hintText,
    this.icon,
    this.obscureText = false,
    this.onChanged,
    this.controller,
  }) : assert(
         initialValue == null || controller == null,
         'Cannot provide both an initialValue and a controller.',
       );

  @override
  Widget build(BuildContext context) {
    // The main container for the entire widget
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min, // Takes up minimum vertical space
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The label is now optional and will only be displayed if labelText is not null.
          if (labelText != null) ...[
            Label(labelText!),
            const SizedBox(height: 4),
          ],
          // The container that forms the background of the input field
          Stack(
            alignment: AlignmentGeometry.center,
            children: [
              if (icon != null) Positioned(right: 16, child: icon!),

              TextFormField(
                controller: controller,
                initialValue: initialValue,
                onChanged: onChanged,
                obscureText: obscureText,
                // Styling for the text inside the input field
                style: context.themeText.smallTitle,
                decoration: InputDecoration(
                  isDense: true, // Reduces vertical padding
                  contentPadding: EdgeInsets.only(
                    top: 10,
                    bottom: 10,
                    left: 11,
                    right: icon != null ? 40 : 11
                  ), // Removes default padding
                  hintText: hintText,
                  // Style for the hint text when the field is empty
                  hintStyle: context.themeText.smallTitle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
