import 'package:flutter/widgets.dart';

/// Stable widget [Key]s used by the E2E tests.
///
/// Selecting by key keeps tests independent of locale and copy changes. Each
/// key here must match a `Key('...')` attached to the corresponding widget in
/// `lib/`.
class Selectors {
  Selectors._();

  static const Key welcomeScreen = Key('welcome_screen');
  static const Key welcomeCreateWalletButton = Key('welcome_create_wallet_button');
  static const Key welcomeImportWalletButton = Key('welcome_import_wallet_button');

  static const Key accountReadyDoneButton = Key('account_ready_done_button');

  static const Key homeScreen = Key('home_screen');
}
