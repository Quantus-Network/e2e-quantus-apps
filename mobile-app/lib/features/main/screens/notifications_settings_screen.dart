import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/svg.dart';
import 'package:resonance_network_wallet/features/components/scaffold_base.dart';
import 'package:resonance_network_wallet/features/components/sphere.dart';
import 'package:resonance_network_wallet/features/components/wallet_app_bar.dart';
import 'package:resonance_network_wallet/features/styles/app_colors_theme.dart';
import 'package:resonance_network_wallet/features/styles/app_text_theme.dart';
import 'package:resonance_network_wallet/shared/extensions/media_query_data_extension.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() => _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends State<NotificationsSettingsScreen> {
  bool _isNotificationsEnabled = false;
  bool _isSentTokensNotificationEnabled = false;
  bool _isReceivedTokensNotificationEnabled = false;
  bool _isRecoveryTimerEndingNotificationEnabled = false;
  bool _isReversibleTransactionsNotificationEnabled = false;
  bool _isUpdateFromQuantusNotificationEnabled = false;

  @override
  void initState() {
    super.initState();
  }

  void _toggleNotifications(bool enable) {
    setState(() {
      _isNotificationsEnabled = enable;
    });
  }

  void _toggleSentTokensNotification(bool enable) {
    setState(() {
      _isSentTokensNotificationEnabled = enable;
    });
  }

  void _toggleReceivedTokensNotification(bool enable) {
    setState(() {
      _isReceivedTokensNotificationEnabled = enable;
    });
  }

  void _toggleRecoveryTimerEndingNotification(bool enable) {
    setState(() {
      _isRecoveryTimerEndingNotificationEnabled = enable;
    });
  }

  void _toggleReversibleTransactionsNotification(bool enable) {
    setState(() {
      _isReversibleTransactionsNotificationEnabled = enable;
    });
  }

  void _toggleUpdateFromQuantusNotification(bool enable) {
    setState(() {
      _isUpdateFromQuantusNotificationEnabled = enable;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldBase(
      decorations: [
        const Positioned(bottom: 40, left: -80, child: Sphere(variant: 4, size: 251.62)),
        const Positioned(top: -10, right: -30, child: Sphere(variant: 3, size: 194)),
      ],
      appBar: WalletAppBar(title: 'Notifications Settings'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.only(top: 12, bottom: 12, left: 12, right: 26),
            decoration: ShapeDecoration(
              color: context.themeColors.buttonGlass,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset('assets/notification/notification_settings_icon.png', width: 21, height: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Notifications', style: context.themeText.largeTag),
                      const SizedBox(height: 4),
                      Text(
                        _isNotificationsEnabled ? 'ON' : 'OFF',
                        style: context.themeText.detail?.copyWith(color: context.themeColors.textMuted),
                      ),
                    ],
                  ),
                ),
                CupertinoSwitch(
                  value: _isNotificationsEnabled,
                  onChanged: _toggleNotifications,
                  activeTrackColor: context.themeColors.buttonSuccess,
                  inactiveTrackColor: context.themeColors.textMuted,
                  thumbColor: context.themeColors.buttonNeutral,
                ),
              ],
            ),
          ),
          if (_isNotificationsEnabled) ...[
            const SizedBox(height: 25),
            _buildNotificationToggle(
              context,
              label: 'Sent Tokens',
              value: _isSentTokensNotificationEnabled,
              onChanged: _toggleSentTokensNotification,
            ),
            const SizedBox(height: 12),
            _buildNotificationToggle(
              context,
              label: 'Received Tokens',
              value: _isReceivedTokensNotificationEnabled,
              onChanged: _toggleReceivedTokensNotification,
            ),
            const SizedBox(height: 12),
            _buildNotificationToggle(
              context,
              label: 'Recovery Timer Ending',
              value: _isRecoveryTimerEndingNotificationEnabled,
              onChanged: _toggleRecoveryTimerEndingNotification,
            ),
            const SizedBox(height: 12),
            _buildNotificationToggle(
              context,
              label: 'Reversible Transactions',
              value: _isReversibleTransactionsNotificationEnabled,
              onChanged: _toggleReversibleTransactionsNotification,
            ),
            const SizedBox(height: 12),
            _buildNotificationToggle(
              context,
              label: 'Update From Quantus',
              value: _isUpdateFromQuantusNotificationEnabled,
              onChanged: _toggleUpdateFromQuantusNotification,
            ),
          ],
        ],
      ),
    );
  }

  Container _buildNotificationToggle(
    BuildContext context, {
    required String label,
    required bool value,
    required void Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.only(top: 13, bottom: 13, left: 18, right: 26),
      decoration: ShapeDecoration(
        color: context.themeColors.buttonGlass,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: context.themeText.smallParagraph),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: context.themeColors.buttonSuccess,
            inactiveTrackColor: context.themeColors.textMuted,
            thumbColor: context.themeColors.buttonNeutral,
          ),
        ],
      ),
    );
  }
}
