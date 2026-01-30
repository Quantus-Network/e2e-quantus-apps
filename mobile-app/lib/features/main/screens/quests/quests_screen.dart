import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:resonance_network_wallet/features/components/button.dart';
import 'package:resonance_network_wallet/features/components/complete_setup_action_sheet.dart';
import 'package:resonance_network_wallet/features/components/loading_text_animation.dart';
import 'package:resonance_network_wallet/features/components/quest_card.dart';
import 'package:resonance_network_wallet/features/components/quests_promo_video.dart';
import 'package:resonance_network_wallet/features/components/scaffold_base.dart';
import 'package:resonance_network_wallet/features/components/sphere.dart';
import 'package:resonance_network_wallet/features/main/screens/navbar.dart';
import 'package:resonance_network_wallet/features/main/screens/quests/king_of_the_shill_screen.dart';
import 'package:resonance_network_wallet/features/main/screens/quests/referrals_quest_screen.dart';
import 'package:resonance_network_wallet/features/styles/app_colors_theme.dart';
import 'package:resonance_network_wallet/features/styles/app_text_theme.dart';
import 'package:resonance_network_wallet/providers/account_associations_providers.dart';
import 'package:resonance_network_wallet/providers/account_stats_providers.dart';
import 'package:resonance_network_wallet/providers/opt_in_position_providers.dart';
import 'package:resonance_network_wallet/services/referral_service.dart';

class QuestsScreen extends ConsumerStatefulWidget {
  final bool playPromoVideo;
  const QuestsScreen({super.key, required this.playPromoVideo});

  @override
  ConsumerState<QuestsScreen> createState() => _QuestsScreenState();
}

class _QuestsScreenState extends ConsumerState<QuestsScreen> {
  final ReferralService _referralService = ReferralService();
  final ScrollController _scrollController = ScrollController();

  bool _isRewardProgramParticipant = false;
  bool _isLoadingParticipation = true;
  bool _isLastPromo = false;
  bool _isSubmitting = false;
  bool _isVisible = true;

  Future<void> _loadParticipationStatus() async {
    try {
      final isParticipant = await _referralService.getRewardProgramParticiation();
      setState(() {
        _isRewardProgramParticipant = isParticipant;
        _isLoadingParticipation = false;
      });
    } catch (e) {
      debugPrint('Error loading participation status: $e');
      setState(() {
        _isLoadingParticipation = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadParticipationStatus();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void refreshStatsData() {
    ref.invalidate(accountsStatsProvider);
  }

  void refreshAssociationsData() {
    ref.invalidate(accountAssociationsProvider);
  }

  void setVideoVisibility(bool isVisible) {
    if (mounted) {
      setState(() {
        _isVisible = isVisible;
      });
    }
  }

  void _setIsFinalVideo(bool isFinalVideo) {
    setState(() {
      _isLastPromo = isFinalVideo;
    });
  }

  Future<void> _handleOptIn(BuildContext context) async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      await _referralService.optInRewardProgram();
      ref.invalidate(optInPositionProvider);

      setState(() {
        _isSubmitting = false;
      });

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          this.context,
          MaterialPageRoute(
            settings: const RouteSettings(name: 'navbar'),
            builder: (context) => const Navbar(initialIndex: 3),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      print('Failed opting in reward program: $e');
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading state for users who haven't opted in to the reward program or if the promo video is not playing yet
    if (_isLoadingParticipation || !widget.playPromoVideo) {
      return ScaffoldBase(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 12,
            children: [
              Image.asset('assets/quests/quests_top_logo.png', height: 24),
              const LoadingTextAnimation(),
            ],
          ),
        ),
      );
    }

    if (!_isRewardProgramParticipant) {
      return Scaffold(
        backgroundColor: context.themeColors.background2,
        body: Stack(
          children: [
            QuestsPromoVideo(
              isSubmitting: _isSubmitting,
              closeSheet: null, // No close button for inline use
              setIsFinalVideo: _setIsFinalVideo,
              startFromBeginning: true,
              showCloseButton: false,
              isVisible: _isVisible,
            ),
            if (_isLastPromo)
              Positioned(
                bottom: 100, // Move down to avoid video text overlap
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.useOpacity(0.8)],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Button(
                        label: "I'm In",
                        isLoading: _isSubmitting,
                        variant: ButtonVariant.primary,
                        onPressed: () {
                          _handleOptIn(context);
                        },
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    }

    final associationsAsync = ref.watch(accountAssociationsProvider);
    final hasCompletedSetup = associationsAsync.maybeWhen(
      data: (associations) => associations.ethAddress != null || associations.xUsername != null,
      orElse: () => false,
    );

    return ScaffoldBase.refreshable(
      backgroundColor: const Color(0xFF0C1014),
      onRefresh: () async {
        refreshStatsData();
        refreshAssociationsData();
      },
      scrollController: _scrollController,
      decorations: [
        const Positioned(top: 180, right: -34, child: Sphere(variant: 2, size: 194)),
        const Positioned(left: -60, bottom: 0, child: Sphere(variant: 7, size: 240.68)),
      ],
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              _buildHeader(context, hasCompletedSetup),
              const SizedBox(height: 48),
              _buildQuestCards(context, hasCompletedSetup),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, bool hasCompletedSetup) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Image.asset(
          'assets/quests/quests_top_logo.png',
          height: 24,
          fit: BoxFit.contain,
        ),
        GestureDetector(
          onTap: () => showCompleteSetupActionSheet(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: ShapeDecoration(
              color: context.themeColors.settingCard,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            child: Text(
              hasCompletedSetup ? 'Setup' : 'Complete Setup',
              style: context.themeText.smallParagraph,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestCards(BuildContext context, bool hasCompletedSetup) {
    return Column(
      children: [
        QuestCard.referFriends(
          isDisabled: !hasCompletedSetup,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ReferralsQuestScreen()),
            );
          },
        ),
        const SizedBox(height: 40),
        QuestCard.kingOfTheShill(
          isDisabled: !hasCompletedSetup,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const KingOfTheShillScreen()),
            );
          },
        ),
      ],
    );
  }

}
