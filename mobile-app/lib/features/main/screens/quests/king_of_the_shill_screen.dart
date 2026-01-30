import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:resonance_network_wallet/features/components/inner_shadow_container.dart';
import 'package:resonance_network_wallet/features/components/raid_submission_action_sheet.dart';
import 'package:resonance_network_wallet/features/components/scaffold_base.dart';
import 'package:resonance_network_wallet/features/components/wallet_app_bar.dart';
import 'package:resonance_network_wallet/providers/raider_quest_providers.dart';
import 'package:url_launcher/url_launcher.dart';

class KingOfTheShillScreen extends ConsumerStatefulWidget {
  const KingOfTheShillScreen({super.key});

  @override
  ConsumerState<KingOfTheShillScreen> createState() => _KingOfTheShillScreenState();
}

class _KingOfTheShillScreenState extends ConsumerState<KingOfTheShillScreen> {
  void _showHowItWorksDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) => GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: GestureDetector(
              onTap: () {},
              child: Container(
                width: 280,
                padding: const EdgeInsets.all(24),
                decoration: ShapeDecoration(
                  color: const Color(0xFF0C1014),
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(width: 1, color: Color(0x66F4F6F9)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'HOW IT WORKS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontFamily: 'Fira Code',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: const Icon(Icons.close, color: Colors.white, size: 24),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _buildStep('Step 1', 'Find an active raid on X (Twitter)'),
                    const SizedBox(height: 16),
                    _buildStep('Step 2', 'Reply to the raid post with your shill'),
                    const SizedBox(height: 16),
                    _buildStep('Step 3', 'Submit your reply URL here to get verified and earn rewards'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontFamily: 'Fira Code',
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          description,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.50),
            fontSize: 14,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  void refreshRaiderSubmissions() {
    ref.invalidate(raiderSubmissionsProvider);
  }

  String _formatTimeAgo(String url) {
    return '';
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final raiderSubmissionsAsync = ref.watch(raiderSubmissionsProvider);

    return ScaffoldBase(
      appBar: WalletAppBar(
        title: 'King of The Shill',
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: _showHowItWorksDialog,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                clipBehavior: Clip.antiAlias,
                decoration: ShapeDecoration(
                  color: const Color(0xFF0C1014),
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(width: 1, color: Color(0x7F6734BA)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: InnerShadowContainer.standard(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: RadialGradient(
                              center: Alignment(-0.8, 0.6),
                              radius: 1.0,
                              colors: [
                                Color(0xFFFFE91F),
                                Color(0xFFED4CCE),
                                Color(0xFF0000FF),
                                Color(0xFF0C1014),
                              ],
                              stops: [0.05, 0.15, 0.35, 0.6],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Column(
                                children: [
                                  const Text(
                                    'KING OF THE SHILL',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontFamily: 'Fira Code',
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Join social raids. Get rewarded for\nverified posts.',
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
                            raiderSubmissionsAsync.when(
                              loading: () => const Center(
                                child: CircularProgressIndicator(color: Colors.white),
                              ),
                              error: (_, __) => _buildStatsBox(0, 0),
                              data: (state) {
                                if (state is RaiderSubmissionsOk) {
                                  return _buildStatsBox(state.submissions.length, 0);
                                }
                                return _buildStatsBox(0, 0);
                              },
                            ),
                            const SizedBox(height: 24),
                            _buildPastSubmissionsSection(raiderSubmissionsAsync),
                            const Spacer(),
                            _buildSubmitSection(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () => showRaidSubmissionActionSheet(context),
              child: InnerShadowContainer.standard(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: ShapeDecoration(
                    color: const Color(0x33F4F6F9),
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(width: 1, color: Color(0x33F4F6F9)),
                      borderRadius: BorderRadius.circular(42),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'Add Raid Submission',
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
          ],
        ),
      ),
    );
  }

  Widget _buildStatsBox(int submissions, int verifiedPosts) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: const Color(0xFF0C1014).withOpacity(0.4),
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 1, color: Color(0x33F4F6F9)),
          borderRadius: BorderRadius.circular(8),
        ),
        shadows: const [
          BoxShadow(
            color: Color(0x3F000000),
            blurRadius: 4,
            offset: Offset(4, 4),
          )
        ],
      ),
      child: Column(
        children: [
          _buildStatRow('Submissions', '$submissions', Colors.white),
          const SizedBox(height: 16),
          _buildStatRow('Verified posts', verifiedPosts.toString().padLeft(2, '0'), Colors.white),
          const SizedBox(height: 16),
          _buildStatRow('Rank', '#-', const Color(0xFFED4CCE)),
        ],
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

  Widget _buildPastSubmissionsSection(AsyncValue<RaiderSubmissionsState> raiderSubmissionsAsync) {
    return Column(
      children: [
        const Text(
          'Past Submissions',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontFamily: 'Fira Code',
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: ShapeDecoration(
            shape: RoundedRectangleBorder(
              side: const BorderSide(width: 1, color: Color(0x33F4F6F9)),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: raiderSubmissionsAsync.when(
            loading: () => const Center(
              child: SizedBox(
                height: 80,
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
            error: (_, __) => Text(
              'Failed to load submissions',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
                fontFamily: 'Inter',
              ),
            ),
            data: (state) {
              if (state is RaiderSubmissionsOk && state.submissions.isNotEmpty) {
                return Column(
                  children: state.submissions.take(4).map((url) => _buildSubmissionRow(url)).toList(),
                );
              }
              return Text(
                'No submissions yet',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                  fontFamily: 'Inter',
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSubmissionRow(String url) {
    final displayUrl = url.length > 30 ? '${url.substring(0, 30)}...' : url;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _openUrl(url),
              child: Text(
                displayUrl,
                style: const TextStyle(
                  color: Color(0xFFF4F6F9),
                  fontSize: 12,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                  decoration: TextDecoration.underline,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Text(
            _formatTimeAgo(url),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 10,
              fontFamily: 'Fira Code',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitSection() {
    return Column(
      children: [
        const Text(
          'Submit Your Reply',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontFamily: 'Fira Code',
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => showRaidSubmissionActionSheet(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: ShapeDecoration(
              color: Colors.white.withValues(alpha: 0.24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              '|https://x.com/....',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
                fontFamily: 'Fira Code',
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
