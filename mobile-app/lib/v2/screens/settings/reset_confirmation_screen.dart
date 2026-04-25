import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resonance_network_wallet/services/local_auth_service.dart';
import 'package:resonance_network_wallet/services/logout_service.dart';
import 'package:resonance_network_wallet/shared/extensions/toaster_extensions.dart';
import 'package:resonance_network_wallet/v2/components/quantus_button.dart';
import 'package:resonance_network_wallet/v2/components/scaffold_base.dart';
import 'package:resonance_network_wallet/v2/components/scaffold_base_bottom_content.dart';
import 'package:resonance_network_wallet/v2/components/v2_app_bar.dart';
import 'package:resonance_network_wallet/v2/theme/app_colors.dart';
import 'package:resonance_network_wallet/v2/theme/app_text_styles.dart';

const _resetCheckboxLabel = "I've backed up my recovery phrase";

class ResetConfirmationScreen extends ConsumerStatefulWidget {
  const ResetConfirmationScreen({super.key});

  @override
  ConsumerState<ResetConfirmationScreen> createState() => _ResetConfirmationScreenState();
}

class _ResetConfirmationScreenState extends ConsumerState<ResetConfirmationScreen> {
  static const _items = <String>[
    'All wallet data will be permanently removed from this device',
    'Your funds stay on the blockchain but only your recovery phrase can restore access',
    'Without it, your funds are gone forever',
  ];

  bool _backedUpChecked = false;
  bool _isResetting = false;

  Future<void> _resetAndClearData() async {
    setState(() => _isResetting = true);

    final authed = await LocalAuthService().authenticate(localizedReason: 'Authenticate to reset wallet');

    if (authed && mounted) {
      if (mounted) ref.read(logoutServiceProvider).logout(context);
    } else {
      if (mounted) {
        context.showErrorToaster(message: 'Authentication required to reset wallet');
      }

      return;
    }

    setState(() => _isResetting = false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.themeText;
    final headlineStyle = text.mediumTitle?.copyWith(
      fontSize: 28,
      fontWeight: FontWeight.w500,
      color: colors.textPrimary,
      height: 1.35,
    );
    final bodyStyle = text.paragraph?.copyWith(color: colors.textMuted, fontSize: 16, height: 1.35);
    final numStyle = text.paragraph?.copyWith(
      fontSize: 16,
      fontFamily: AppTextTheme.fontFamilySecondary,
      fontWeight: FontWeight.w400,
      color: colors.accentOrange,
      height: 1.35,
    );
    return ScaffoldBase(
      appBar: const V2AppBar(title: 'Reset Wallet'),
      mainContent: SingleChildScrollView(
        child: Column(
          children: [
            Icon(Icons.warning_amber_outlined, size: 40, color: colors.accentOrange),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 278),
              child: Text('This will erase\nyour wallet', textAlign: TextAlign.center, style: headlineStyle),
            ),
            const SizedBox(height: 40),
            for (var i = 0; i < _items.length; i++) ...[
              _NumberedRow(
                indexLabel: (i + 1).toString().padLeft(2, '0'),
                text: _items[i],
                numberStyle: numStyle!,
                bodyStyle: bodyStyle!,
              ),
              if (i < _items.length - 1) ...[
                const SizedBox(height: 16),
                Divider(color: colors.surfaceDeep, height: 1, thickness: 1),
                const SizedBox(height: 24),
              ],
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomContent: _BottomBar(
        colors: colors,
        text: text,
        checked: _backedUpChecked,
        isResetting: _isResetting,
        onToggleChecked: () => setState(() => _backedUpChecked = !_backedUpChecked),
        onContinue: _resetAndClearData,
      ),
    );
  }
}

class _NumberedRow extends StatelessWidget {
  const _NumberedRow({
    required this.indexLabel,
    required this.text,
    required this.numberStyle,
    required this.bodyStyle,
  });

  final String indexLabel;
  final String text;
  final TextStyle numberStyle;
  final TextStyle bodyStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(indexLabel, style: numberStyle),
        const SizedBox(width: 16),
        Expanded(child: Text(text, style: bodyStyle)),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.colors,
    required this.text,
    required this.checked,
    required this.isResetting,
    required this.onToggleChecked,
    required this.onContinue,
  });

  final AppColorsV2 colors;
  final AppTextTheme text;
  final bool checked;
  final bool isResetting;
  final VoidCallback onToggleChecked;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final labelStyle = text.paragraph?.copyWith(color: colors.textMuted, fontSize: 16);
    return ScaffoldBaseBottomContent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            checked: checked,
            label: 'Recovery phrase backup confirmation',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onToggleChecked,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FigmaStyleCheckbox(value: checked, colors: colors),
                    const SizedBox(width: 16),
                    Expanded(child: Text(_resetCheckboxLabel, style: labelStyle)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          QuantusButton.simple(
            label: 'Continue',
            onTap: onContinue,
            variant: ButtonVariant.primary,
            isDisabled: !checked,
            isLoading: isResetting,
          ),
        ],
      ),
    );
  }
}

class _FigmaStyleCheckbox extends StatelessWidget {
  const _FigmaStyleCheckbox({required this.value, required this.colors});

  final bool value;
  final AppColorsV2 colors;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: value ? colors.accentOrange : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: colors.borderButton, width: 1),
        ),
        alignment: Alignment.center,
        child: value ? Icon(Icons.check, size: 14, color: colors.background) : null,
      ),
    );
  }
}
