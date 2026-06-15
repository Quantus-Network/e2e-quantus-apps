import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resonance_network_wallet/providers/route_intent_providers.dart';
import 'package:resonance_network_wallet/v2/screens/home/home_screen.dart';

/// Returns to Home and opens the Accounts popup. When [newAccountId] is given,
/// that account is pre-selected (highlighted, not activated); otherwise the
/// active account is scrolled into view. Used by every in-app add/edit flow that
/// should land back on the accounts list.
void finishAccountAddition(BuildContext context, WidgetRef ref, {String? newAccountId}) {
  ref.read(openAccountsIntentProvider.notifier).state = OpenAccountsIntent(highlightAccountId: newAccountId);
  Navigator.of(
    context,
  ).pushAndRemoveUntil(MaterialPageRoute<void>(builder: (_) => const HomeScreen()), (route) => false);
}
