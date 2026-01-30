import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:resonance_network_wallet/features/styles/app_colors_theme.dart';
import 'package:resonance_network_wallet/providers/account_associations_providers.dart';
import 'package:resonance_network_wallet/providers/opt_in_position_providers.dart';
import 'package:resonance_network_wallet/shared/extensions/snackbar_extensions.dart';

void showCompleteSetupActionSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const CompleteSetupActionSheet(),
  );
}

class CompleteSetupActionSheet extends ConsumerStatefulWidget {
  const CompleteSetupActionSheet({super.key});

  @override
  ConsumerState<CompleteSetupActionSheet> createState() => _CompleteSetupActionSheetState();
}

class _CompleteSetupActionSheetState extends ConsumerState<CompleteSetupActionSheet> {
  final _taskmasterService = TaskmasterService();
  final _ethAddressController = TextEditingController();
  final _xHandleController = TextEditingController();
  final _bioController = TextEditingController();

  bool _isSubmitting = false;
  bool _hasInitialized = false;
  String? _originalEthAddress;
  String? _originalXUsername;

  bool get _isBioValid => _bioController.text.trim().toLowerCase().contains('@quantusnetwork');

  @override
  void dispose() {
    _ethAddressController.dispose();
    _xHandleController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _initializeData(AccountAssociations associations) {
    if (_hasInitialized) return;

    _originalEthAddress = associations.ethAddress;
    _originalXUsername = associations.xUsername;

    if (associations.ethAddress != null) {
      _ethAddressController.text = associations.ethAddress!;
    }
    if (associations.xUsername != null) {
      _xHandleController.text = associations.xUsername!;
    }

    _hasInitialized = true;
  }

  Future<void> _handleLinkAccounts() async {
    final ethAddress = _ethAddressController.text.trim();
    final xHandle = _xHandleController.text.trim();

    setState(() => _isSubmitting = true);

    try {
      final optInStatus = ref.read(optInPositionProvider);
      final isAlreadyOptedIn = optInStatus.maybeWhen(
        data: (position) => position.position > 0,
        orElse: () => false,
      );

      if (!isAlreadyOptedIn) {
        await _taskmasterService.optInRewardProgram();
      }

      if (ethAddress.isNotEmpty && ethAddress != _originalEthAddress) {
        await _taskmasterService.associateEthAddress(ethAddress);
      }

      final normalizedHandle = xHandle.startsWith('@') ? xHandle.substring(1) : xHandle;
      if (normalizedHandle.isNotEmpty && normalizedHandle != _originalXUsername) {
        await _taskmasterService.associateXHandle(normalizedHandle);
      }

      ref.invalidate(accountAssociationsProvider);
      ref.invalidate(optInPositionProvider);

      if (mounted) {
        context.showSuccessSnackbar(
          title: 'Success',
          message: 'Accounts linked successfully!',
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackbar(
          title: 'Error',
          message: e.toString(),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final associationsAsync = ref.watch(accountAssociationsProvider);

    associationsAsync.whenData((associations) {
      _initializeData(associations);
    });

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      padding: EdgeInsets.only(
        left: 26,
        right: 26,
        top: 40,
        bottom: 40 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const ShapeDecoration(
        color: Color(0xFF0C1014),
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 1,
            strokeAlign: BorderSide.strokeAlignOutside,
            color: Color(0x66F4F6F9),
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 64),
            _buildForm(),
            const SizedBox(height: 32),
            _buildLinkButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SizedBox(
      width: double.infinity,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'COMPLETE ACCOUNT SETUP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontFamily: 'Fira Code',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 264,
                  child: Text(
                    'Link your accounts once to participate in referrals and raids.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.50),
                      fontSize: 14,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          // Close button
           GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Icon(Icons.close, color: context.themeColors.textPrimary, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputSection(
          title: 'Connect your wallet',
          controller: _ethAddressController,
          hintText: 'Enter ETH Address',
        ),
        const SizedBox(height: 32),
        _buildInputSection(
          title: 'Connect your X handle',
          controller: _xHandleController,
          hintText: 'Enter username',
        ),
        const SizedBox(height: 32),
        _buildBioSection(),
      ],
    );
  }

  Widget _buildInputSection({
    required String title,
    required TextEditingController controller,
    required String hintText,
  }) {
    return Container(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 323,
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFFF4F6F9),
                fontSize: 18,
                fontFamily: 'Fira Code',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 15),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: ShapeDecoration(
              color: const Color(0x0AF4F6F9),
              shape: RoundedRectangleBorder(
                side: const BorderSide(
                  width: 1,
                  color: Color(0x19F4F6F9),
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: TextField(
              controller: controller,
              autocorrect: false,
              textCapitalization: TextCapitalization.none,
              style: const TextStyle(
                color: Color(0xFFF4F6F9),
                fontSize: 14,
                fontFamily: 'Fira Code',
                fontWeight: FontWeight.w400,
              ),
              decoration: InputDecoration.collapsed(
                hintText: '|$hintText',
                hintStyle: const TextStyle(
                  color: Color(0x7FF4F6F9),
                  fontSize: 14,
                  fontFamily: 'Fira Code',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBioSection() {
    return Container(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  width: 323,
                  child: Text(
                    'Verify your X account',
                    style: TextStyle(
                      color: Color(0xFFF4F6F9),
                      fontSize: 18,
                      fontFamily: 'Fira Code',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const SizedBox(
                  width: 323,
                  child: Text(
                    'To confirm this account belongs to you, please update your X bio to include @QuantusNetwork',
                    style: TextStyle(
                      color: Color(0x7FF4F6F9),
                      fontSize: 14,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: ShapeDecoration(
              color: const Color(0x0AF4F6F9),
              shape: RoundedRectangleBorder(
                side: const BorderSide(
                  width: 1,
                  color: Color(0x19F4F6F9),
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: TextField(
              controller: _bioController,
              onChanged: (_) => setState(() {}),
              autocorrect: false,
              textCapitalization: TextCapitalization.none,
              style: const TextStyle(
                color: Color(0xFFF4F6F9),
                fontSize: 14,
                fontFamily: 'Fira Code',
                fontWeight: FontWeight.w400,
              ),
              decoration: const InputDecoration.collapsed(
                hintText: '|Updated Bio',
                hintStyle: TextStyle(
                  color: Color(0x7FF4F6F9),
                  fontSize: 14,
                  fontFamily: 'Fira Code',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkButton() {
    final bool isEnabled = _isBioValid && !_isSubmitting;

    return GestureDetector(
      onTap: isEnabled ? _handleLinkAccounts : null,
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.40,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: ShapeDecoration(
            gradient: const LinearGradient(
              begin: Alignment(0.02, 0.50),
              end: Alignment(1.00, 0.50),
              colors: [Color(0x7F0000FF), Color(0x19ED4CCE), Color(0x7FFFE91F)],
            ),
            shape: RoundedRectangleBorder(
              side: const BorderSide(
                width: 1,
                color: Color(0x33F4F6F9),
              ),
              borderRadius: BorderRadius.circular(42),
            ),
          ),
          child: Center(
            child: _isSubmitting
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: context.themeColors.textPrimary,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Link Accounts',
                    style: TextStyle(
                      color: Color(0xFFF4F6F9),
                      fontSize: 18,
                      fontFamily: 'Fira Code',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
