import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import '../support/app_launcher.dart';
import '../support/patrol_timeouts.dart';
import '../support/selectors.dart';
import '../support/test_env.dart';

void main() {
  patrolTest('import existing wallet from welcome lands on home', ($) async {
    await AppLauncher.launchFresh($);

    expect($(Selectors.welcomeScreen), findsOneWidget);

    await $(Selectors.welcomeImportWalletButton).tap();

    await $(Selectors.importWalletScreen).waitUntilVisible(timeout: PatrolTimeouts.visible);

    await $(Selectors.importWalletSeedPhraseField).enterText(TestEnv.importMnemonic);

    await $(Selectors.importWalletButton).tap();

    await $(Selectors.homeScreen).waitUntilVisible(timeout: PatrolTimeouts.network);
  });
}
