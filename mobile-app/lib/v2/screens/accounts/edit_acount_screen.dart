import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:resonance_network_wallet/providers/account_providers.dart';
import 'package:resonance_network_wallet/shared/extensions/toaster_extensions.dart';
import 'package:resonance_network_wallet/v2/components/quantus_button.dart';
import 'package:resonance_network_wallet/v2/components/scaffold_base.dart';
import 'package:resonance_network_wallet/v2/components/scaffold_base_bottom_content.dart';
import 'package:resonance_network_wallet/v2/components/v2_app_bar.dart';
import 'package:resonance_network_wallet/v2/theme/app_colors.dart';
import 'package:resonance_network_wallet/v2/theme/app_text_styles.dart';

class EditAccountScreen extends ConsumerStatefulWidget {
  final Account initialAccount;

  const EditAccountScreen({super.key, required this.initialAccount});

  @override
  ConsumerState<EditAccountScreen> createState() => EditAccountScreenState();
}

class EditAccountScreenState extends ConsumerState<EditAccountScreen> {
  late final TextEditingController _controller;
  final _accountsService = AccountsService();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialAccount.name);
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      context.showErrorToaster(message: "Account name can't be empty");
      return;
    }
    if (name == widget.initialAccount.name) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    setState(() => _saving = true);
    try {
      await _accountsService.updateAccountName(widget.initialAccount, name);
      if (mounted) {
        ref.invalidate(accountsProvider);
        ref.invalidate(activeAccountProvider);
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        context.showErrorToaster(message: 'Failed to rename account.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldBase(
      appBar: const V2AppBar(title: 'Account Name'),
      mainContent: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [_buildNameField(context)]),
      bottomContent: ScaffoldBaseBottomContent(
        child: QuantusButton.simple(variant: ButtonVariant.primary, label: 'Done', onTap: _save, isLoading: _saving),
      ),
    );
  }

  Widget _buildNameField(BuildContext context) {
    final textStyle = context.themeText.smallTitle!.copyWith(fontWeight: FontWeight.w400);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: context.colors.surfaceDeep, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Expanded(
            child: TextField(controller: _controller, style: textStyle),
          ),
          if (_controller.text.isNotEmpty) ...[
            const SizedBox(width: 8),
            _EditAccountClearButton(onTap: () => _controller.clear()),
          ],
        ],
      ),
    );
  }
}

class _EditAccountClearButton extends StatelessWidget {
  final VoidCallback onTap;

  const _EditAccountClearButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final size = 20.0;
    final borderRadius = 16.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: context.colors.textMuted,
            border: Border.all(color: context.colors.borderButton, width: 0.5),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: Icon(Icons.close, size: 12, color: context.colors.background),
        ),
      ),
    );
  }
}
