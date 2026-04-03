import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:resonance_network_wallet/v2/theme/app_colors.dart';
import 'package:resonance_network_wallet/v2/theme/app_text_styles.dart';

class _StableKeyboardPadding extends StatefulWidget {
  final Widget child;
  const _StableKeyboardPadding({required this.child});

  @override
  State<_StableKeyboardPadding> createState() => _StableKeyboardPaddingState();
}

class _StableKeyboardPaddingState extends State<_StableKeyboardPadding> {
  double _lockedHeight = 0;
  bool _isOpen = false;
  Timer? _closeTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final kb = MediaQuery.of(context).viewInsets.bottom;

    if (kb > 0) {
      _closeTimer?.cancel();
      _isOpen = true;
      if (kb > _lockedHeight) _lockedHeight = kb;
    } else if (_isOpen) {
      _closeTimer?.cancel();
      _closeTimer = Timer(const Duration(milliseconds: 200), () {
        if (mounted) setState(() { _isOpen = false; _lockedHeight = 0; });
      });
    }
  }

  @override
  void dispose() {
    _closeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: _lockedHeight),
      child: widget.child,
    );
  }
}

class BottomSheetContainer extends StatelessWidget {
  final String title;
  final Widget Function(String title)? titleBuilder;
  final Widget child;
  final VoidCallback? onBack;
  final double? height;

  const BottomSheetContainer({
    super.key,
    required this.title,
    required this.child,
    this.titleBuilder,
    this.onBack,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.themeText;
    return Container(
      height: height,
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border.all(color: const Color(0xFF3D3D3D)),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: height != null ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (onBack != null)
                GestureDetector(
                  onTap: onBack,
                  child: Icon(Icons.arrow_back_ios_new, color: colors.textPrimary, size: 20),
                ),

              if (titleBuilder != null)
                titleBuilder!(title)
              else
                Text(
                  title,
                  style: text.smallTitle?.copyWith(color: colors.textPrimary, fontSize: 20),
                  textAlign: TextAlign.center,
                ),

              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(Icons.close, color: colors.textPrimary, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 32),
          if (height != null) Expanded(child: child) else Flexible(child: SingleChildScrollView(child: child)),
        ],
      ),
    );
  }

  static Future<T?> show<T>(BuildContext context, {required WidgetBuilder builder, bool fixKeyboardInPlace = false}) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width),
      builder: (ctx) {
        final child = builder(ctx);
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
          child: fixKeyboardInPlace ? _StableKeyboardPadding(child: child) : child,
        );
      },
    );
  }
}
