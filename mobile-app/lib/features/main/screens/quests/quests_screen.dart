import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resonance_network_wallet/features/components/complete_setup_action_sheet.dart';
import 'package:resonance_network_wallet/features/components/quest_card.dart';
import 'package:resonance_network_wallet/features/components/scaffold_base.dart';
import 'package:resonance_network_wallet/features/main/screens/quests/king_of_the_shill_screen.dart';
import 'package:resonance_network_wallet/features/main/screens/quests/referrals_quest_screen.dart';
import 'package:resonance_network_wallet/features/styles/app_colors_theme.dart';
import 'package:resonance_network_wallet/features/styles/app_text_theme.dart';
import 'package:resonance_network_wallet/providers/account_associations_providers.dart';
import 'package:resonance_network_wallet/providers/account_stats_providers.dart';

class QuestsScreen extends ConsumerStatefulWidget {
  const QuestsScreen({super.key});

  @override
  ConsumerState<QuestsScreen> createState() => _QuestsScreenState();
}

class _QuestsScreenState extends ConsumerState<QuestsScreen> {
  final ScrollController _scrollController = ScrollController();

  void refreshStatsData() {
    ref.invalidate(accountsStatsProvider);
  }

  void refreshAssociationsData() {
    ref.invalidate(accountAssociationsProvider);
  }

  @override
  Widget build(BuildContext context) {
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
