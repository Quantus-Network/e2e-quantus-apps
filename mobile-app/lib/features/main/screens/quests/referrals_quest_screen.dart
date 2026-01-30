import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:resonance_network_wallet/features/components/copy_icon.dart';
import 'package:resonance_network_wallet/features/components/inner_shadow_container.dart';
import 'package:resonance_network_wallet/features/components/scaffold_base.dart';
import 'package:resonance_network_wallet/features/components/wallet_app_bar.dart';
import 'package:resonance_network_wallet/providers/account_associations_providers.dart';
import 'package:resonance_network_wallet/providers/account_stats_providers.dart';
import 'package:resonance_network_wallet/services/referral_service.dart';
import 'package:resonance_network_wallet/shared/extensions/clipboard_extensions.dart';
import 'package:share_plus/share_plus.dart';

class ReferralsQuestScreen extends ConsumerStatefulWidget {
  const ReferralsQuestScreen({super.key});

  @override
  ConsumerState<ReferralsQuestScreen> createState() => _ReferralsQuestScreenState();
}

class _ReferralsQuestScreenState extends ConsumerState<ReferralsQuestScreen> {
  final ReferralService _referralService = ReferralService();
  String? _referralCode;

  Future<void> _loadReferralCode() async {
    try {
      final myReferralCode = await _referralService.getMyInviteCode();
      setState(() {
        _referralCode = myReferralCode;
      });
    } catch (e) {
      debugPrint('Error loading account data: $e');
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _shareReferralLink() async {
    final params = await _referralService.getShareLinkParameters(context.sharePositionRect());
    SharePlus.instance.share(params);
  }

  void _copyReferralCode() {
    if (_referralCode != null) {
      ClipboardExtensions.copyTextWithSnackbar(context, _referralCode!, message: 'Referral code copied to clipboard');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadReferralCode();
  }

  void refreshStatsData() {
    ref.invalidate(accountsStatsProvider);
    ref.invalidate(accountAssociationsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(accountsStatsProvider);
    final referralsCount = statsAsync.value?.referralCount ?? 0;

    return ScaffoldBase(
      appBar: WalletAppBar(
        title: 'Referrals',
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () {
              // TODO: Show info
            },
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                // Main Card
                InnerShadowContainer(
                  shadows: const [
                    BoxShadow(
                      color: Color(0x19FFFFFF),
                      offset: Offset(-2, -2),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: Color(0x19FFFFFF),
                      offset: Offset(2, 2),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 80), // Leave space for the button
                    clipBehavior: Clip.antiAlias,
                    decoration: ShapeDecoration(
                      color: const Color(0xFF0C1014),
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(
                          width: 1,
                          color: Color(0x7F6734BA),
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: Stack(
                    children: [
                      // Gradient Blob
                      Positioned(
                        left: -156,
                        top: 72,
                        child: Container(
                          width: 531,
                          height: 531,
                          decoration: ShapeDecoration(
                            gradient: const RadialGradient(
                              center: Alignment.bottomCenter,
                              radius: 1.2,
                              colors: [
                                Color(0xFFFFE91F),
                                Color(0xFFED4CCE),
                                Color(0xFF0000FF),
                                Color(0xFF0C1014),
                              ],
                              stops: [0.0, 0.2, 0.5, 1.0],
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          ),
                        ),
                      ),
                      
                      // Content
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Section
                            Center(
                              child: Column(
                                children: [
                                  const Text(
                                    'REFER FRIENDS',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontFamily: 'Fira Code',
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Invite friends. Earn rewards. \nClimb the leaderboard.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.50),
                                      fontSize: 14,
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 40),
                            
                          // Avatars Row (Placeholders)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildAvatar(const [Color(0xFF0000FF), Color(0xFF0C1014)]),
                              Transform.translate(offset: const Offset(-16, 0), child: _buildAvatar(const [Color(0xFF8B0000), Color(0xFFED4CCE)])),
                              Transform.translate(offset: const Offset(-32, 0), child: _buildAvatar(const [Color(0xFFFFD700), Color(0xFFFFE91F)])),
                            ],
                          ),

                            const SizedBox(height: 40),

                            // Stats Box
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: ShapeDecoration(
                                color: const Color(0xFF0C1014).withOpacity(0.4),
                                shape: RoundedRectangleBorder(
                                  side: const BorderSide(
                                    width: 1,
                                    color: Color(0x33F4F6F9),
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                shadows: const [
                                  BoxShadow(
                                    color: Color(0x3F000000),
                                    blurRadius: 4,
                                    offset: Offset(4, 4),
                                    spreadRadius: 0,
                                  )
                                ],
                              ),
                              child: Column(
                                children: [
                                  _buildStatRow('Referrals', '$referralsCount', Colors.white),
                                  const SizedBox(height: 16),
                                  _buildStatRow('Rank', '#-', const Color(0xFFED4CCE)), // Rank not available yet
                                ],
                              ),
                            ),

                            const Spacer(),

                            // Invite Code Section
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Your invite code',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontFamily: 'Fira Code',
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                  GestureDetector(
                                  onTap: _copyReferralCode,
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(14),
                                    decoration: ShapeDecoration(
                                      color: const Color(0xFF6B46C1).withOpacity(0.2),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _referralCode ?? 'Loading...',
                                          style: const TextStyle(
                                            color: Color(0xFFF4F6F9),
                                            fontSize: 12,
                                            fontFamily: 'Fira Code',
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                        const CopyIcon(width: 16, color: Color(0xFFF4F6F9)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

                // Bottom Button
                Positioned(
                  bottom: 24,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: _shareReferralLink,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: ShapeDecoration(
                          color: const Color(0x33F4F6F9),
                          shape: RoundedRectangleBorder(
                            side: const BorderSide(
                              width: 1,
                              color: Color(0x33F4F6F9),
                            ),
                            borderRadius: BorderRadius.circular(42),
                          ),
                        ),
                        child: const Text(
                          'Share Link',
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(List<Color> colors) {
    return Container(
      width: 64,
      height: 64,
      decoration: ShapeDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        shape: const OvalBorder(
          side: BorderSide(
            width: 2.67,
            strokeAlign: BorderSide.strokeAlignOutside,
            color: Color(0xFF0C1014),
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFF4F6F9),
            fontSize: 14,
            fontFamily: 'Fira Code',
            fontWeight: FontWeight.w400,
          ),
        ),
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: valueColor,
            fontSize: 14,
            fontFamily: 'Fira Code',
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
