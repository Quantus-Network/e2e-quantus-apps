import 'package:flutter/material.dart';
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:resonance_network_wallet/shared/utils/share_utils.dart';
import 'package:resonance_network_wallet/v2/components/address_details_card.dart';
import 'package:resonance_network_wallet/v2/components/scaffold_base.dart';
import 'package:resonance_network_wallet/v2/components/scaffold_base_bottom_content.dart';
import 'package:resonance_network_wallet/v2/components/share_account_button.dart';
import 'package:resonance_network_wallet/v2/components/v2_app_bar.dart';

class AccountDetailsScreen extends StatefulWidget {
  final Account account;

  const AccountDetailsScreen({super.key, required this.account});

  @override
  State<AccountDetailsScreen> createState() => _AccountDetailsScreenState();
}

class _AccountDetailsScreenState extends State<AccountDetailsScreen> {
  final _checksumService = HumanReadableChecksumService();
  String? _checksum;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final c = await _checksumService.getHumanReadableName(widget.account.accountId);
    if (mounted) {
      setState(() {
        _checksum = c;
        _isLoading = false;
      });
    }
  }

  void _share() {
    if (_isLoading || _checksum == null) return;

    shareAccountDetails(context, widget.account.accountId, checksum: _checksum!);
  }

  @override
  Widget build(BuildContext context) {
    final account = widget.account;
    return ScaffoldBase(
      appBar: const V2AppBar(title: 'Address Details'),
      mainContent: AddressDetailsCard(accountId: account.accountId, checksum: _checksum),
      bottomContent: ScaffoldBaseBottomContent(
        child: ShareAccountButton(onTap: _share, isDisabled: _isLoading),
      ),
    );
  }
}
