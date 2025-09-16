import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final pendingCancellationsProvider = StateNotifierProvider<PendingCancellationsNotifier, Set<String>>((ref) {
  return PendingCancellationsNotifier();
});

class PendingCancellationsNotifier extends StateNotifier<Set<String>> {
  static const String _key = 'pending_cancellations';

  PendingCancellationsNotifier() : super(<String>{}) {
    _loadPendingCancellations();
  }

  Future<void> _loadPendingCancellations() async {
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getStringList(_key) ?? [];
    state = pending.toSet();
  }

  Future<void> addPendingCancellation(String transactionId) async {
    state = {...state, transactionId};
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, state.toList());
  }

  Future<void> removePendingCancellation(String transactionId) async {
    state = state.where((id) => id != transactionId).toSet();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, state.toList());
  }

  Set<String> getPendingCancellations() => state;
}