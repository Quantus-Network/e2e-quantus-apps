import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import '../support/app_launcher.dart';
import '../support/patrol_timeouts.dart';
import '../support/selectors.dart';

void main() {
  patrolTest('create new wallet from welcome lands on home', ($) async {
    await AppLauncher.launchFresh($);

    expect($(Selectors.welcomeScreen), findsOneWidget);

    await $(Selectors.welcomeCreateWalletButton).tap();

    await $(Selectors.accountReadyDoneButton).waitUntilVisible(timeout: PatrolTimeouts.network);
    expect($('Account 1'), findsOneWidget);

    await $(Selectors.accountReadyDoneButton).tap();

    await $(Selectors.homeScreen).waitUntilVisible(timeout: PatrolTimeouts.network);
  });
}
