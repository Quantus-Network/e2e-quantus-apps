import 'package:flutter/widgets.dart';
import 'package:resonance_network_wallet/shared/constants/e2e_keys.dart';

/// Stable widget [Key]s used by the E2E tests.
///
/// Selecting by key keeps tests independent of locale and copy changes. The key
/// strings come from [E2EKeys] in `lib/`, which the production widgets use too,
/// so the test selectors and the app can never drift apart.
class Selectors {
  Selectors._();

  static const Key welcomeScreen = Key(E2EKeys.welcomeScreen);
  static const Key welcomeCreateWalletButton = Key(E2EKeys.welcomeCreateWalletButton);
  static const Key welcomeImportWalletButton = Key(E2EKeys.welcomeImportWalletButton);

  static const Key accountReadyDoneButton = Key(E2EKeys.accountReadyDoneButton);

  static const Key importWalletScreen = Key(E2EKeys.importWalletScreen);
  static const Key importWalletSeedPhraseField = Key(E2EKeys.importWalletSeedPhraseField);
  static const Key importWalletButton = Key(E2EKeys.importWalletButton);

  static const Key homeScreen = Key(E2EKeys.homeScreen);
}
