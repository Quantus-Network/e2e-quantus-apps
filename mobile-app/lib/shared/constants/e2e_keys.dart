/// Stable widget key identifiers shared between production widgets and E2E tests.
///
/// These live in `lib/` (not in the test folder) so that production screens and
/// the Patrol selectors in `patrol_test/support/selectors.dart` reference the
/// exact same strings. This keeps the two in lockstep and avoids the drift that
/// happens when each side hardcodes its own copy of a key.
///
/// Keep these as plain [String] constants (not [Key]s) so this file stays free
/// of any test-framework dependency and can be imported anywhere.
class E2EKeys {
  E2EKeys._();

  static const String welcomeScreen = 'welcome_screen';
  static const String welcomeCreateWalletButton = 'welcome_create_wallet_button';
  static const String welcomeImportWalletButton = 'welcome_import_wallet_button';

  static const String accountReadyDoneButton = 'account_ready_done_button';

  static const String importWalletScreen = 'import_wallet_screen';
  static const String importWalletSeedPhraseField = 'import_wallet_seed_phrase_field';
  static const String importWalletButton = 'import_wallet_button';

  static const String homeScreen = 'home_screen';
  static const String homeSendButton = 'home_send_button';
  static const String homePendingSendActivityItem = 'home_pending_send_activity_item';

  static const String sendSelectRecipientScreen = 'send_select_recipient_screen';
  static const String sendRecipientField = 'send_recipient_field';
  static const String sendContinueButton = 'send_continue_button';

  static const String sendInputAmountScreen = 'send_input_amount_screen';
  static const String sendAmountField = 'send_amount_field';
  static const String sendReviewButton = 'send_review_button';

  static const String sendReviewScreen = 'send_review_screen';
  static const String sendConfirmButton = 'send_confirm_button';

  static const String sendTxSubmittedScreen = 'send_tx_submitted_screen';
  static const String sendTxSubmittedDoneButton = 'send_tx_submitted_done_button';
}
