// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get walletInitErrorTitle => 'Wallet-Fehler';

  @override
  String get walletInitErrorMessage =>
      'Geheime Phrase konnte nicht gefunden werden. Bitte stelle deine Wallet wieder her.';

  @override
  String get walletInitErrorButtonLabel => 'OK';

  @override
  String get authUseDeviceBiometricsToUnlock => 'Geräte-Biometrie zum Entsperren verwenden';

  @override
  String get authAuthenticating => 'Authentifizierung...';

  @override
  String get authUnlockWallet => 'Wallet entsperren';

  @override
  String get authAuthorizationRequired => 'Autorisierung \n erforderlich';

  @override
  String get welcomeTagline => 'Quantensicheres verschlüsseltes Geld';

  @override
  String get welcomeCreateNewWallet => 'Neue Wallet erstellen';

  @override
  String get welcomeImportWallet => 'Wallet importieren';

  @override
  String get createWalletCautionHeadline => 'Halte deine Wiederherstellungsphrase geheim';

  @override
  String get createWalletCautionBullet1 =>
      'Wenn du dieses Gerät verlierst, ist die Wiederherstellungsphrase der einzige Weg zurück';

  @override
  String get createWalletCautionBullet2 => 'Jeder, der sie erhält, hat dauerhaft die volle Kontrolle über deine Gelder';

  @override
  String get createWalletCautionBullet3 => 'Schreibe sie auf und bewahre sie sicher auf. Speichere sie nicht digital';

  @override
  String createWalletRecoveryPhraseSaveError(String error) {
    return 'Fehler beim Speichern der Wallet: $error';
  }

  @override
  String get recoveryPhraseBodyInstructions =>
      'Schreibe diese Wörter der Reihe nach auf und bewahre sie an einem Ort auf, auf den nur du Zugriff hast. Mache keinen Screenshot und kopiere sie nicht in eine Notiz-App.';

  @override
  String get recoveryPhraseBodyCopy => 'Kopieren';

  @override
  String get recoveryPhraseBodyTapToReveal => 'Zum Anzeigen tippen';

  @override
  String get recoveryPhraseBodyTapToHide => 'Zum Verbergen tippen';

  @override
  String get recoveryPhraseBodyCopiedMessage => 'Wiederherstellungsphrase in die Zwischenablage kopiert';

  @override
  String get accountReadyAccountCreated => 'Konto erstellt';

  @override
  String get accountReadyWalletCreated => 'Wallet erstellt';

  @override
  String get accountReadyWalletImported => 'Wallet importiert';

  @override
  String get accountReadyDone => 'Fertig';

  @override
  String get importWalletAppBarTitle => 'Wallet importieren';

  @override
  String get importWalletDescription =>
      'Stelle eine bestehende Wallet mit deiner 12- oder 24-Wörter-Wiederherstellungsphrase wieder her';

  @override
  String get importWalletHint =>
      'Gib deine Wiederherstellungsphrase ein oder füge sie ein. Trenne Wörter mit Leerzeichen.';

  @override
  String get importWalletButton => 'Importieren';

  @override
  String get importWalletValidationError => 'Die Wiederherstellungsphrase muss 12 oder 24 Wörter enthalten';

  @override
  String homeError(String error) {
    return 'Fehler: $error';
  }

  @override
  String get homeNoActiveAccount => 'Kein aktives Konto';

  @override
  String get homeCharge => 'Kassieren';

  @override
  String get homeGetTestnetTokens => 'Testnet-Token erhalten ↗';

  @override
  String get homeErrorLoadingBalance => 'Fehler beim Laden des Guthabens';

  @override
  String get homeBackupReminder => 'Sichere deine Wiederherstellungsphrase';

  @override
  String get homeReceive => 'Empfangen';

  @override
  String get homeSend => 'Senden';

  @override
  String get homeSwap => 'Tauschen';

  @override
  String get homeActivityTitle => 'Aktivität';

  @override
  String get homeActivityViewAll => 'Alle anzeigen';

  @override
  String get homeActivityErrorLoading => 'Fehler beim Laden der Transaktionen';

  @override
  String get homeActivityRetry => 'Erneut versuchen';

  @override
  String get homeActivityEmptyTitle => 'Noch keine Transaktionen';

  @override
  String get homeActivityEmptyMessage => 'Deine Aktivität erscheint hier, sobald du QUAN sendest oder empfängst.';

  @override
  String get accountsSheetTitle => 'Konten';

  @override
  String get accountsSheetFailedLoadAccounts => 'Konten konnten nicht geladen werden.';

  @override
  String get accountsSheetFailedLoadActiveAccount => 'Aktives Konto konnte nicht geladen werden.';

  @override
  String get accountsSheetNoAccountsFound => 'Keine Konten gefunden.';

  @override
  String get accountsSheetAddAccount => 'Konto hinzufügen';

  @override
  String get accountsSheetBalanceUnavailable => 'Guthaben nicht verfügbar';

  @override
  String accountsSheetBalance(String balance, String symbol) {
    return '$balance $symbol';
  }

  @override
  String get addAccountMenuTitle => 'Konto hinzufügen';

  @override
  String get addAccountMenuCreateTitle => 'Neues Konto erstellen';

  @override
  String get addAccountMenuCreateSubtitle => 'Eine neue Wallet-Adresse generieren';

  @override
  String get addAccountMenuImportTitle => 'Wallet importieren';

  @override
  String get addAccountMenuImportSubtitle => 'Eine Wiederherstellungsphrase zum Importieren verwenden';

  @override
  String get addAccountMenuMultisigTitle => 'Multisig erstellen';

  @override
  String get addAccountMenuMultisigSubtitle => 'Eine geteilte Adresse mit mehreren Unterzeichnern einrichten';

  @override
  String get addAccountMenuDiscoverMultisigTitle => 'Multisig entdecken';

  @override
  String get addAccountMenuDiscoverMultisigSubtitle => 'Multisigs finden, bei denen deine Konten Unterzeichner sind';

  @override
  String get multisigTag => 'MULTISIG';

  @override
  String get multisigProposeTitle => 'Vorschlagen';

  @override
  String get multisigAddTitle => 'Multisig erstellen';

  @override
  String get multisigDiscoverTitle => 'Multisig entdecken';

  @override
  String get multisigCreateSubtitle =>
      'Gib dieser Multisig einen Namen, den du wiedererkennst. Du kannst ihn jederzeit ändern.';

  @override
  String get multisigCreateButton => 'Erstellen';

  @override
  String get multisigCreateCreatingButton => 'Wird erstellt';

  @override
  String multisigCreateDefaultName(int number) {
    return 'Multisig $number';
  }

  @override
  String get multisigCreateErrorCouldNotCreate => 'Multisig konnte nicht erstellt werden.';

  @override
  String get multisigCreateReadyToast => 'Multisig zu deinen Konten hinzugefügt.';

  @override
  String get multisigCreateAlreadyExists => 'Eine Multisig mit dieser Adresse existiert bereits on-chain.';

  @override
  String get multisigCreateInsufficientBalance => 'Unzureichendes Guthaben für die Multisig-Erstellungsgebühren.';

  @override
  String get multisigCreateTimeoutToast =>
      'Die Multisig-Erstellung dauert länger als erwartet. Prüfe die Chain oder versuche es erneut.';

  @override
  String get multisigCreateAuthReason => 'Authentifiziere dich, um diese Multisig zu erstellen';

  @override
  String get multisigCreateSignersLabel => 'UNTERZEICHNER';

  @override
  String get multisigCreateSignersSubtitle => 'Füge neben dir selbst mindestens einen weiteren Unterzeichner hinzu.';

  @override
  String get multisigCreateAddSignerHint => 'SS58-Adresse des Unterzeichners';

  @override
  String get multisigCreateAddSignerButton => 'Unterzeichner hinzufügen';

  @override
  String get multisigCreateDuplicateSigner => 'Dieser Unterzeichner ist bereits in der Liste.';

  @override
  String get multisigCreateInvalidSigner => 'Gib eine gültige SS58-Adresse ein.';

  @override
  String get multisigCreateThresholdLabel => 'SCHWELLENWERT';

  @override
  String multisigCreateThresholdValue(int count, int total) {
    return '$count von $total';
  }

  @override
  String get multisigCreatePredictedAddressLabel => 'MULTISIG-ADRESSE';

  @override
  String get multisigCreatePredictedAddressPlaceholder => 'Füge Unterzeichner hinzu, um die Adresse anzuzeigen';

  @override
  String get multisigDone => 'Fertig';

  @override
  String get multisigAddDiscoveredTitle => 'Für dich entdeckt';

  @override
  String get multisigAddDiscoveredSubtitle =>
      'Multisigs auf der Chain, bei denen eines deiner Konten Unterzeichner ist';

  @override
  String get multisigAddButton => 'Hinzufügen';

  @override
  String get multisigAddedButton => 'Hinzugefügt';

  @override
  String get multisigAddNoneFound => 'Keine Multisigs gefunden.';

  @override
  String multisigAddDiscoverFailed(String error) {
    return 'Multisigs konnten nicht entdeckt werden: $error';
  }

  @override
  String multisigAddFailed(String error) {
    return 'Multisig konnte nicht hinzugefügt werden: $error';
  }

  @override
  String get multisigOpenProposals => 'Offene Vorschläge';

  @override
  String get multisigPastProposals => 'Frühere Vorschläge';

  @override
  String get multisigNoOpenProposals => 'Keine offenen Vorschläge.';

  @override
  String get multisigNoPastProposals => 'Keine früheren Vorschläge.';

  @override
  String multisigLoadFailed(String error) {
    return 'Laden fehlgeschlagen: $error';
  }

  @override
  String multisigProposalToAddress(String address) {
    return 'an $address';
  }

  @override
  String get multisigStatusApproved => 'GENEHMIGT';

  @override
  String get multisigStatusProposed => 'VORGESCHLAGEN';

  @override
  String get multisigStatusExpired => 'ABGELAUFEN';

  @override
  String get multisigStatusCancelled => 'STORNIERT';

  @override
  String get multisigProposeSelectRecipientTo => 'Übertragen an';

  @override
  String multisigProposeSearchHint(String symbol) {
    return '$symbol-Adresse eingeben';
  }

  @override
  String get multisigProposeAmountToLabel => 'ÜBERTRAGEN AN';

  @override
  String get multisigProposeDepositLabel => 'Kaution:';

  @override
  String get multisigProposeCreationFeeLabel => 'Vorschlagsgebühr:';

  @override
  String get multisigProposeDepositRefundableNote => 'erstattbar';

  @override
  String get multisigProposeMemberTotalLabel => 'GESAMT VON DEINEM KONTO';

  @override
  String get multisigProposeFeeLabel => 'Vorschlagsgebühr:';

  @override
  String get multisigProposeFeeFetchFailed => 'Gebühr kann nicht geschätzt werden';

  @override
  String get multisigProposeReviewButton => 'Übertragung prüfen';

  @override
  String get multisigProposeReviewProposing => 'VORGESCHLAGENE ÜBERTRAGUNG';

  @override
  String multisigProposeReviewFromName(String name) {
    return 'von $name';
  }

  @override
  String get multisigProposeThresholdLabel => 'SCHWELLENWERT';

  @override
  String get multisigProposeExpiresLabel => 'LÄUFT AB';

  @override
  String multisigExpiresBlockOnly(int block) {
    return 'Block $block';
  }

  @override
  String get multisigProposeFeeRowLabel => 'VORSCHLAGSGEBÜHR';

  @override
  String get multisigProposeCreateButton => 'Vorschlag einreichen';

  @override
  String get multisigProposeAuthReason => 'Authentifiziere dich, um die Transaktion vorzuschlagen';

  @override
  String get multisigProposeAuthRequired => 'Authentifizierung erforderlich';

  @override
  String get multisigProposeSubmitFailed => 'Vorschlag konnte nicht erstellt werden';

  @override
  String get multisigProposeTimeoutToast =>
      'Die Bestätigung des Vorschlags dauert länger als erwartet. Prüfe die Chain oder versuche es erneut.';

  @override
  String get multisigProposeDoneHeadline => 'Übertragungsvorschlag eingereicht';

  @override
  String get multisigProposeDoneSubline =>
      'Mitunterzeichner müssen zustimmen, bevor die Übertragung ausgeführt werden kann.';

  @override
  String multisigProposeDoneToChecksum(String checksum) {
    return 'an $checksum';
  }

  @override
  String multisigSignaturesCount(int current, int threshold) {
    return 'Signaturen: $current/$threshold';
  }

  @override
  String get multisigProposalTitle => 'Vorschlag';

  @override
  String multisigProposalLoadFailed(String error) {
    return 'Fehlgeschlagen: $error';
  }

  @override
  String get multisigProposalNotFound => 'Vorschlag nicht gefunden.';

  @override
  String get multisigProposalSignButton => 'Signieren';

  @override
  String get multisigProposalSigningSoonNote => 'Das Signieren wird bald verfügbar sein.';

  @override
  String get multisigProposalApprovingLabel => 'Wird genehmigt…';

  @override
  String get multisigProposalApprovingNote => 'Deine Genehmigung wird on-chain bestätigt.';

  @override
  String get multisigApproveUnavailableNote => 'Dieser Vorschlag kann nicht mehr genehmigt werden.';

  @override
  String get activityTxApproving => 'Wird genehmigt…';

  @override
  String get activityTxCancelling => 'Wird storniert…';

  @override
  String get multisigApprovalTimeoutToast =>
      'Die Bestätigung der Genehmigung dauert länger als erwartet. Prüfe die Chain oder versuche es erneut.';

  @override
  String get multisigProposalAlreadySignedNote => 'Du hast diesen Vorschlag bereits genehmigt.';

  @override
  String get multisigProposalAlreadyExecutedNote => 'Dieser Vorschlag wurde bereits ausgeführt.';

  @override
  String get multisigProposalAlreadyCancelledNote => 'Dieser Vorschlag wurde bereits storniert.';

  @override
  String get multisigProposalProposerLabel => 'ANTRAGSTELLER';

  @override
  String get multisigProposalStatusLabel => 'STATUS';

  @override
  String get multisigProposalDepositLabel => 'KAUTION';

  @override
  String get multisigStatusActive => 'AKTIV';

  @override
  String get multisigStatusExecuted => 'AUSGEFÜHRT';

  @override
  String get multisigStatusRemoved => 'ENTFERNT';

  @override
  String get multisigStatusUnknown => 'UNBEKANNT';

  @override
  String get activityTxProposal => 'Vorschlag';

  @override
  String get activityTxProposing => 'Wird vorgeschlagen';

  @override
  String get activityTxProposalCreated => 'Vorschlag erstellt';

  @override
  String get activityTxProposalApproved => 'Vorschlag genehmigt';

  @override
  String get activityTxProposalExecuted => 'Vorschlag ausgeführt';

  @override
  String get activityTxProposalCancelled => 'Vorschlag storniert';

  @override
  String get multisigApproveButton => 'Genehmigen';

  @override
  String get multisigAlreadyApproved => 'Bereits genehmigt';

  @override
  String get multisigCancelProposalButton => 'Vorschlag stornieren';

  @override
  String get multisigProposalExpiresLabel => 'LÄUFT AB';

  @override
  String get multisigProposalAtLabel => 'AM';

  @override
  String get multisigProposalThresholdLabel => 'SCHWELLENWERT';

  @override
  String get multisigProposalApprovalsLabel => 'GENEHMIGUNGEN';

  @override
  String get multisigProposalFeeRowLabel => 'VORSCHLAGSGEBÜHR';

  @override
  String get multisigProposalSignersLabel => 'UNTERZEICHNER';

  @override
  String get multisigYouLabel => 'DU';

  @override
  String get multisigSignerCreatorLabel => 'ERSTELLER';

  @override
  String get multisigAccountMenuDetails => 'Multisig-Details';

  @override
  String get multisigAccountMenuDetailsTitle => 'Multisig-Details';

  @override
  String get multisigAccountMenuDetailsThresholdHint =>
      'So viele Unterzeichner-Genehmigungen sind erforderlich, um einen Vorschlag auszuführen.';

  @override
  String multisigThresholdOf(int count, int total) {
    return '$count von $total';
  }

  @override
  String multisigApprovalsOf(int count, int threshold) {
    return '$count von $threshold';
  }

  @override
  String get multisigApproveConfirmTitle => 'Bist du sicher?';

  @override
  String get multisigApproveConfirmBody => 'Du bist dabei, eine Übertragung zu genehmigen über';

  @override
  String multisigApproveConfirmTo(String address) {
    return 'an $address';
  }

  @override
  String get multisigApproveConfirmYes => 'Ja, genehmigen';

  @override
  String get multisigApproveConfirmNo => 'Nein, zurück';

  @override
  String get multisigApproveAuthReason => 'Authentifiziere dich, um zu genehmigen';

  @override
  String get multisigAuthRequired => 'Authentifizierung erforderlich';

  @override
  String get multisigApproveFailed => 'Genehmigung fehlgeschlagen';

  @override
  String get multisigExecuteButton => 'Ausführen';

  @override
  String get multisigExecuteConfirmTitle => 'Bist du sicher?';

  @override
  String get multisigExecuteConfirmBody => 'Du bist dabei, eine Übertragung auszuführen über';

  @override
  String get multisigExecuteConfirmYes => 'Ja, ausführen';

  @override
  String get multisigExecuteAuthReason => 'Authentifiziere dich, um auszuführen';

  @override
  String get multisigExecuteFailed => 'Ausführung fehlgeschlagen';

  @override
  String get multisigExecuteUnavailableNote => 'Dieser Vorschlag kann nicht mehr ausgeführt werden.';

  @override
  String get multisigProposalExecutingLabel => 'Wird ausgeführt…';

  @override
  String get multisigProposalExecutingNote => 'Deine Ausführung wird on-chain bestätigt.';

  @override
  String get activityTxExecuting => 'Wird ausgeführt…';

  @override
  String get multisigExecutionTimeoutToast =>
      'Die Bestätigung der Ausführung dauert länger als erwartet. Prüfe die Chain oder versuche es erneut.';

  @override
  String get multisigExecutedByOtherToast => 'Der Vorschlag wurde von einem anderen Unterzeichner ausgeführt.';

  @override
  String get multisigFeeEstimateUnavailable => 'Schätzung der Netzwerkgebühr nicht verfügbar.';

  @override
  String get multisigCancelConfirmTitle => 'Vorschlag stornieren?';

  @override
  String get multisigCancelConfirmBody =>
      'Durch das Stornieren wird deine Vorschlagskaution erstattet. Andere Unterzeichner können nicht mehr genehmigen.';

  @override
  String get multisigCancelConfirmYes => 'Ja, Vorschlag stornieren';

  @override
  String get multisigCancelConfirmKeep => 'Vorschlag behalten';

  @override
  String get multisigCancelAuthReason => 'Authentifiziere dich, um zu stornieren';

  @override
  String get multisigCancelFailed => 'Stornierung fehlgeschlagen';

  @override
  String get multisigProposalCancellingLabel => 'Wird storniert…';

  @override
  String get multisigProposalCancellingNote => 'Deine Stornierung wird on-chain bestätigt.';

  @override
  String get multisigCancelTimeoutToast =>
      'Die Bestätigung der Stornierung dauert länger als erwartet. Prüfe die Chain oder versuche es erneut.';

  @override
  String get multisigApproveTitle => 'Genehmigen';

  @override
  String get multisigApproveDoneExecuted => 'Vorschlag ausgeführt';

  @override
  String get multisigApproveDoneRecorded => 'Genehmigung erfasst';

  @override
  String get multisigApproveDoneExecutedSubline => 'Schwellenwert erreicht — Übertragung ausgelöst.';

  @override
  String get multisigApproveDoneRecordedSubline => 'Warten auf weitere Mitunterzeichner.';

  @override
  String get createAccountAppBarTitle => 'Kontoname';

  @override
  String get createAccountSubtitle =>
      'Gib diesem Konto einen Namen, den du wiedererkennst. Du kannst ihn jederzeit ändern.';

  @override
  String get createAccountButton => 'Erstellen';

  @override
  String get createAccountErrorCouldNotAdd => 'Konto konnte nicht hinzugefügt werden.';

  @override
  String createAccountDefaultName(int number) {
    return 'Konto $number';
  }

  @override
  String get editAccountAppBarTitle => 'Kontoname';

  @override
  String get editAccountDone => 'Fertig';

  @override
  String get editAccountNameEmpty => 'Der Kontoname darf nicht leer sein';

  @override
  String get editAccountRenameFailed => 'Konto konnte nicht umbenannt werden.';

  @override
  String get accountMenuTitle => 'Konten';

  @override
  String get accountMenuAccountName => 'Kontoname';

  @override
  String get accountMenuAddressDetails => 'Adressdetails';

  @override
  String get accountMenuShowRecoveryPhrase => 'Wiederherstellungsphrase anzeigen';

  @override
  String get accountMenuNotFound => 'Konto nicht gefunden';

  @override
  String get accountDetailsTitle => 'Adressdetails';

  @override
  String get addHardwareAccountAddWallet => 'Hardware-Wallet hinzufügen';

  @override
  String get addHardwareAccountAddAccount => 'Hardware-Konto hinzufügen';

  @override
  String get addHardwareAccountNameLabel => 'NAME';

  @override
  String get addHardwareAccountNameHintWallet => 'Hardware-Wallet';

  @override
  String get addHardwareAccountNameHintAccount => 'Konto';

  @override
  String get addHardwareAccountAddressLabel => 'ADRESSE';

  @override
  String get addHardwareAccountAddressHint => 'SS58-Adresse';

  @override
  String get addHardwareAccountDebugFill => 'Debug-Befüllung';

  @override
  String get addHardwareAccountNameRequired => 'Name ist erforderlich';

  @override
  String get addHardwareAccountInvalidAddress => 'Ungültige Adresse';

  @override
  String get sendTitle => 'Senden';

  @override
  String get sendPayTitle => 'Bezahlen';

  @override
  String get sendEnterAddress => 'Adresse eingeben';

  @override
  String get sendSelectRecipientSendTo => 'Senden an';

  @override
  String sendSelectRecipientSearchHint(String symbol) {
    return '$symbol-Adresse eingeben';
  }

  @override
  String get sendSelectRecipientScanTitle => 'QR-Code scannen';

  @override
  String sendSelectRecipientScanSubtitle(String symbol) {
    return 'Tippen, um eine $symbol-Adresse zu scannen';
  }

  @override
  String get sendSelectRecipientRecents => 'Zuletzt verwendet';

  @override
  String get sendSelectRecipientContinue => 'Weiter';

  @override
  String get sendInputAmountSendTo => 'SENDEN AN';

  @override
  String get sendInputAmountAvailableBalance => 'Verfügbares Guthaben:';

  @override
  String get sendInputAmountNetworkFee => 'Netzwerkgebühr:';

  @override
  String get sendInputAmountMax => 'Max';

  @override
  String get sendInputAmountInvalidAmount => 'Bitte gib einen gültigen Betrag ein';

  @override
  String get sendInputAmountChecksumRequired => 'Prüfphrase des Empfängers ist erforderlich';

  @override
  String get sendReviewSending => 'SENDEN';

  @override
  String get sendReviewTo => 'AN';

  @override
  String get sendReviewAmount => 'BETRAG';

  @override
  String get sendReviewNetworkFee => 'NETZWERKGEBÜHR';

  @override
  String get sendReviewYouPay => 'DU ZAHLST';

  @override
  String get sendReviewConfirm => 'Bestätigen';

  @override
  String get sendReviewAuthReason => 'Authentifiziere dich, um die Transaktion zu bestätigen';

  @override
  String get sendReviewAuthRequired => 'Authentifizierung zum Senden erforderlich';

  @override
  String get sendReviewSubmitFailed => 'Senden der Transaktion fehlgeschlagen';

  @override
  String sendTxSubmittedHeadlinePaid(String amount, String symbol) {
    return '$amount $symbol bezahlt';
  }

  @override
  String sendTxSubmittedHeadlineSent(String amount, String symbol) {
    return '$amount $symbol gesendet';
  }

  @override
  String get sendTxSubmittedOnItsWay => 'Unterwegs';

  @override
  String get sendTxSubmittedToLabel => 'An';

  @override
  String get sendTxSubmittedDone => 'Fertig';

  @override
  String get sendLogicCantSelfTransfer => 'Keine Übertragung an sich selbst möglich';

  @override
  String get sendLogicEnterAmount => 'Betrag eingeben';

  @override
  String get sendLogicInvalidAmount => 'Ungültiger Betrag';

  @override
  String get sendLogicBelowExistentialDeposit => 'Unter dem Mindestguthaben';

  @override
  String get sendLogicInsufficientBalance => 'Unzureichendes Guthaben';

  @override
  String get sendLogicReviewSend => 'Senden prüfen';

  @override
  String get activityTitle => 'Aktivität';

  @override
  String activityError(String error) {
    return 'Fehler: $error';
  }

  @override
  String get activityNoAccount => 'Kein Konto';

  @override
  String get activityEmpty => 'Noch keine Transaktionen';

  @override
  String get activityFilterAll => 'Alle';

  @override
  String get activityFilterSend => 'Senden';

  @override
  String get activityFilterReceive => 'Empfangen';

  @override
  String get activityDateToday => 'Heute';

  @override
  String get activityDateYesterday => 'Gestern';

  @override
  String get activityTxSending => 'Wird gesendet';

  @override
  String get activityTxReceiving => 'Wird empfangen';

  @override
  String get activityTxPending => 'Ausstehend';

  @override
  String get activityTxSent => 'Gesendet';

  @override
  String get activityTxReceived => 'Empfangen';

  @override
  String get activityTxMultisigCreated => 'Multisig erstellt';

  @override
  String get activityTxMultisigCreating => 'Multisig wird erstellt';

  @override
  String get activityTxMultisigLabel => 'Multisig';

  @override
  String get activityTxTo => 'An';

  @override
  String get activityTxFrom => 'Von';

  @override
  String get activityTxTimeNow => 'jetzt';

  @override
  String activityTxTimeMinutesAgo(int minutes) {
    return 'vor $minutes Min';
  }

  @override
  String activityTxTimeHoursAgo(int hours) {
    return 'vor $hours Std';
  }

  @override
  String activityTxTimeDaysAgo(int days) {
    return 'vor $days T';
  }

  @override
  String activityTxTimeRemaining(String days, String hours, String minutes) {
    return '${days}T:${hours}Std:${minutes}Min';
  }

  @override
  String get activityDetailTitleSending => 'Wird gesendet';

  @override
  String get activityDetailTitleScheduled => 'Geplant';

  @override
  String get activityDetailTitleReceiving => 'Wird empfangen';

  @override
  String get activityDetailTitleSent => 'Gesendet';

  @override
  String get activityDetailTitleReceived => 'Empfangen';

  @override
  String get activityDetailTitleMultisigCreated => 'Multisig erstellt';

  @override
  String get activityDetailTitleMultisigCreating => 'Multisig wird erstellt';

  @override
  String get activityDetailTitleProposalCreated => 'Vorschlag erstellt';

  @override
  String get activityDetailTitleProposalApproved => 'Vorschlag genehmigt';

  @override
  String get activityDetailTitleProposalExecuted => 'Vorschlag ausgeführt';

  @override
  String get activityDetailTitleProposalCancelled => 'Vorschlag storniert';

  @override
  String get activityDetailTitleCancelling => 'Vorschlag wird storniert';

  @override
  String get activityDetailTitleExecuting => 'Vorschlag wird ausgeführt';

  @override
  String get activityDetailTitleProposing => 'Wird vorgeschlagen';

  @override
  String get activityDetailProposalTransferAmount => 'ÜBERTRAGUNGSBETRAG';

  @override
  String get activityDetailStatusInProcess => 'In Bearbeitung';

  @override
  String get activityDetailStatusScheduled => 'Geplant';

  @override
  String get activityDetailStatusCompleted => 'Abgeschlossen';

  @override
  String get activityDetailStatus => 'STATUS';

  @override
  String get activityDetailTo => 'AN';

  @override
  String get activityDetailFrom => 'VON';

  @override
  String get activityDetailDate => 'DATUM';

  @override
  String get activityDetailNetworkFee => 'NETZWERKGEBÜHR';

  @override
  String get activityDetailTxHash => 'TX-HASH';

  @override
  String get activityDetailViewExplorer => 'Im Explorer anzeigen ↗';

  @override
  String get activityDetailMultisigAddress => 'MULTISIG-ADRESSE';

  @override
  String get activityDetailMultisigThreshold => 'SCHWELLENWERT';

  @override
  String activityDetailMultisigThresholdValue(int threshold, int total) {
    return '$threshold von $total';
  }

  @override
  String get activityDetailMultisigSignerCount => 'UNTERZEICHNER';

  @override
  String get activityDetailMultisigCreator => 'ERSTELLER';

  @override
  String get activityDetailMultisigCreationFee => 'PALLET-GEBÜHR';

  @override
  String get activityDetailMultisigDeposit => 'RESERVIERTE KAUTION';

  @override
  String get activityDetailMultisigFeePaidByCreator => 'Vom Ersteller bezahlt';

  @override
  String get receiveTitle => 'Empfangen';

  @override
  String get receiveTabQrCode => 'QR-Code';

  @override
  String get receiveTabAddress => 'Adresse';

  @override
  String get receiveCopy => 'Kopieren';

  @override
  String receiveErrorLoadingAccount(String error) {
    return 'Fehler beim Laden der Kontodaten: $error';
  }

  @override
  String receiveClipboardContent(String accountId, String checksum) {
    return 'Konto-ID:\n$accountId\n\nPrüfphrase:\n$checksum';
  }

  @override
  String get receiveCopiedMessage => 'Kontodetails in die Zwischenablage kopiert';

  @override
  String get posAmountTitle => 'Neue Forderung';

  @override
  String posAmountCharge(String amount) {
    return '$amount kassieren';
  }

  @override
  String get posAmountEnterAmount => 'Betrag eingeben';

  @override
  String get posQrTitleScanToPay => 'Zum Bezahlen scannen';

  @override
  String get posQrTitlePaymentReceived => 'Zahlung erhalten';

  @override
  String posQrError(String error) {
    return 'Fehler: $error';
  }

  @override
  String get posQrNoActiveAccount => 'Kein aktives Konto';

  @override
  String get posQrInvalidAmount => 'Ungültiger Betrag. Zum Wiederholen tippen.';

  @override
  String get posQrConnectionLost => 'Verbindung verloren. Zum Wiederholen tippen.';

  @override
  String get posQrTimedOut => 'Zeitüberschreitung. Zum Wiederholen tippen.';

  @override
  String get posQrNewCharge => 'Neue Forderung';

  @override
  String get posQrDone => 'Fertig';

  @override
  String posQrAmountReceived(String amount) {
    return '$amount erhalten';
  }

  @override
  String get posQrFrom => 'Von:';

  @override
  String get posQrWaitingForPayment => 'Warten auf Zahlung';

  @override
  String get posQrNetworkError => 'Netzwerkfehler';

  @override
  String get posQrTryAgain => 'Erneut versuchen';

  @override
  String posQrPaidAt(String time) {
    return 'Um $time';
  }

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsWalletTitle => 'Wallet';

  @override
  String get settingsWalletSubtitle => 'Wiederherstellungsphrase, Wallet zurücksetzen';

  @override
  String get settingsPreferencesTitle => 'Präferenzen';

  @override
  String get settingsPreferencesSubtitle => 'Sprache, Währung, POS-Modus, Benachrichtigungen';

  @override
  String get settingsMiningRewards => 'Mining-Belohnungen';

  @override
  String settingsMiningRewardsSubtitle(int count) {
    return '$count Blöcke gemined';
  }

  @override
  String get settingsMiningRewardsError => 'Fehler beim Abrufen der Mining-Belohnungen';

  @override
  String get settingsAccountTypeTitle => 'Kontotyp';

  @override
  String get settingsAccountTypeSubtitle => 'Erweiterte Kontofunktionen';

  @override
  String get settingsHelpTitle => 'Hilfe & Support';

  @override
  String get settingsHelpSubtitle => 'FAQs, Team kontaktieren';

  @override
  String get settingsAboutTitle => 'Über Quantus';

  @override
  String settingsAboutHubSubtitle(String version, String build) {
    return 'Version $version ($build)';
  }

  @override
  String get settingsWalletRecoveryPhrase => 'Wiederherstellungsphrase';

  @override
  String get settingsWalletRecoveryPhraseSubtitle => 'Zeige dein 24-Wörter-Backup-Passwort';

  @override
  String get settingsWalletReset => 'Wallet zurücksetzen';

  @override
  String get settingsWalletResetSubtitle => 'Entfernt alle Daten von diesem Gerät';

  @override
  String get settingsWalletNoWalletsFound => 'Keine Wallets gefunden';

  @override
  String get settingsWalletFailedToLoad => 'Wallets konnten nicht geladen werden';

  @override
  String get settingsSelectWalletTitle => 'Wallet auswählen';

  @override
  String get settingsSelectWalletNoWallets => 'Keine Wallets gefunden';

  @override
  String settingsSelectWalletItem(int number) {
    return 'Wallet $number';
  }

  @override
  String get settingsRecoveryConfirmAuthReason => 'Authentifiziere dich, um die Wiederherstellungsphrase zu sehen';

  @override
  String get settingsRecoveryConfirmAuthRequired =>
      'Authentifizierung erforderlich, um die Wiederherstellungsphrase zu sehen';

  @override
  String get settingsRecoveryPhraseTitle => 'Wiederherstellungsphrase';

  @override
  String get settingsRecoveryPhraseDone => 'Fertig';

  @override
  String get settingsResetTitle => 'Wallet zurücksetzen';

  @override
  String get settingsResetAuthReason => 'Authentifiziere dich, um die Wallet zurückzusetzen';

  @override
  String settingsResetFailed(String error) {
    return 'Wallet konnte nicht zurückgesetzt werden: $error';
  }

  @override
  String get settingsResetAuthRequired => 'Authentifizierung erforderlich, um die Wallet zurückzusetzen';

  @override
  String get settingsResetCautionHeadline => 'Dies löscht\ndeine Wallet';

  @override
  String get settingsResetCautionBullet1 => 'Alle Wallet-Daten werden dauerhaft von diesem Gerät entfernt';

  @override
  String get settingsResetCautionBullet2 =>
      'Deine Gelder bleiben auf der Blockchain, aber nur deine Wiederherstellungsphrase kann den Zugriff wiederherstellen';

  @override
  String get settingsResetCautionBullet3 => 'Ohne sie sind deine Gelder für immer verloren';

  @override
  String get settingsResetCautionCheckbox => 'Ich habe meine Wiederherstellungsphrase gesichert';

  @override
  String get settingsPreferencesCurrency => 'Währung';

  @override
  String get settingsPreferencesCurrencySubtitle => 'Fiat-Anzeigeeinstellung';

  @override
  String get settingsPreferencesLanguage => 'Sprache';

  @override
  String get settingsPreferencesLanguageSubtitle => 'Anzeigesprache der App';

  @override
  String get settingsPreferencesPosMode => 'POS-Modus';

  @override
  String get settingsPreferencesPosModeSubtitle => 'Point-of-Sale-Funktionen';

  @override
  String get settingsPreferencesNotifications => 'Benachrichtigungen';

  @override
  String get settingsPreferencesNotificationsSubtitle => 'Transaktions- und Wallet-Hinweise';

  @override
  String get settingsCurrencyTitle => 'Währung';

  @override
  String get settingsCurrencySearchHint => 'Suchen';

  @override
  String get settingsCurrencyNoMatch => 'Keine Währungen entsprechen deiner Suche';

  @override
  String settingsCurrencyError(String error) {
    return 'Fehler bei der Währungsauswahl: $error';
  }

  @override
  String get settingsLanguageTitle => 'Sprache';

  @override
  String get settingsLanguageSearchHint => 'Suchen';

  @override
  String get settingsLanguageNoMatch => 'Keine Sprachen entsprechen deiner Suche';

  @override
  String settingsLanguageError(String error) {
    return 'Fehler bei der Sprachauswahl: $error';
  }

  @override
  String get settingsMiningTitle => 'Mining-Belohnungen';

  @override
  String get settingsMiningRedeem => 'Einlösen';

  @override
  String get settingsMiningStatusMining => 'Mining';

  @override
  String get settingsMiningStatusPending => 'Ausstehend';

  @override
  String get settingsMiningBlocksMined => 'GEMINTE BLÖCKE';

  @override
  String get settingsMiningBlocksAcrossTestnets => 'Blöcke über alle Testnets';

  @override
  String get settingsMiningStatTestnetBlocks => 'TESTNET-BLÖCKE';

  @override
  String get settingsMiningStatTestnetRewards => 'TESTNET-BELOHNUNGEN';

  @override
  String get settingsMiningStatRedeemed => 'EINGELÖST';

  @override
  String get settingsMiningStatRedeemable => 'EINLÖSBAR';

  @override
  String get settingsMiningQuanEarned => 'VERDIENTE QUAN';

  @override
  String get settingsMiningViewTelemetry => 'Telemetrie anzeigen ↗';

  @override
  String get settingsMiningNoDataTitle => 'Noch keine Mining-Daten';

  @override
  String get settingsMiningNoDataBody => 'Richte einen Quantus-Mining-Node ein, um Belohnungen zu verdienen.';

  @override
  String get settingsMiningSetupGuide => 'Mining-Einrichtungsanleitung ↗';

  @override
  String get settingsMiningLoadError => 'Mining-Belohnungen konnten nicht geladen werden';

  @override
  String get settingsMiningCheckConnection => 'Bitte überprüfe deine Verbindung';

  @override
  String get settingsMiningTestnetBlocks => 'Blöcke';

  @override
  String get settingsMiningDiracSince => 'Nov 2025';

  @override
  String get settingsMiningSchrodingerSince => 'Okt 2025';

  @override
  String get settingsMiningResonanceSince => 'Jul 2025';

  @override
  String get settingsTestnetTitle => 'Testnet-Belohnungen';

  @override
  String get settingsTestnetLoadError => 'Testnet-Belohnungen konnten nicht geladen werden';

  @override
  String settingsTestnetTotalBlocks(int count) {
    return '$count Blöcke';
  }

  @override
  String get settingsTestnetTotalDescription => 'Gesamtzahl der über alle Testnets geminten Blöcke';

  @override
  String get settingsTestnetBreakdown => 'Aufschlüsselung';

  @override
  String settingsTestnetRowBlocks(int count) {
    return '$count Blöcke';
  }

  @override
  String get settingsHelpScreenTitle => 'Hilfe & Support';

  @override
  String get settingsHelpEmail => 'E-Mail-Support';

  @override
  String get settingsHelpTelegram => 'Telegram';

  @override
  String get settingsAboutScreenTitle => 'Über';

  @override
  String get settingsAboutIntro =>
      'Quantus ist eine Layer-1-Blockchain, gesichert durch ML-DSA Dilithium-5, den Goldstandard der quantenresistenten Verschlüsselung. Gebaut für eine Zukunft, in der klassische Kryptografie nicht mehr ausreicht. Post-Quanten-Kryptografie für alle.';

  @override
  String get settingsAboutTerms => 'Nutzungsbedingungen';

  @override
  String get settingsAboutTermsSubtitle => 'quantus.com/terms/';

  @override
  String get settingsAboutPrivacy => 'Datenschutzrichtlinie';

  @override
  String get settingsAboutPrivacySubtitle => 'quantus.com/privacy-policy/';

  @override
  String get settingsAboutWebsite => 'Website besuchen';

  @override
  String get settingsAboutWebsiteSubtitle => 'quantus.com';

  @override
  String settingsAboutVersion(String version, String build) {
    return 'Version $version ($build)';
  }

  @override
  String get settingsAccountTypeScreenTitle => 'Kontotyp';

  @override
  String get settingsAccountTypeIntro =>
      'Erweiterte Kontofunktionen kommen bald. Sie geben dir mehr Kontrolle darüber, wie Transaktionen autorisiert und gesichert werden.';

  @override
  String get settingsAccountTypeReversibleTitle => 'Umkehrbare Transaktionen';

  @override
  String get settingsAccountTypeReversibleSubtitle => 'Mache deine Sendungen innerhalb eines Zeitfensters rückgängig';

  @override
  String get settingsAccountTypeHighSecurityTitle => 'Hochsicherheitskonto';

  @override
  String get settingsAccountTypeHighSecuritySubtitle => 'Genehmigung durch Guardian erforderlich';

  @override
  String get settingsAccountTypeMultiSigTitle => 'Multi-Signatur';

  @override
  String get settingsAccountTypeMultiSigSubtitle => 'Mehrere Genehmigungen erforderlich';

  @override
  String get settingsAccountTypeHardwareTitle => 'Hardware-Wallet';

  @override
  String get settingsAccountTypeHardwareSubtitle => 'Ein Hardware-Gerät koppeln';

  @override
  String get settingsAccountTypeComingSoon => 'Demnächst';

  @override
  String get swapTitle => 'Tauschen';

  @override
  String get swapFrom => 'Von';

  @override
  String get swapTo => 'Zu';

  @override
  String get swapRefundAddress => 'Rückerstattungsadresse';

  @override
  String swapRefundAddressHint(String network) {
    return '$network-Adresse';
  }

  @override
  String get swapSlippageTolerance => 'Slippage-Toleranz';

  @override
  String get swapRate => 'Kurs';

  @override
  String get swapGetQuote => 'Angebot einholen';

  @override
  String swapRateLabel(String amount, String symbol) {
    return '1 QUAN = $amount $symbol';
  }

  @override
  String swapRateZero(String symbol) {
    return '1 QUAN = 0 $symbol';
  }

  @override
  String get swapTokenPickerTitle => 'Token auswählen';

  @override
  String get swapTokenPickerLoadError => 'Token konnten nicht geladen werden';

  @override
  String get swapReviewTitle => 'Angebot prüfen';

  @override
  String get swapReviewTotalFees => 'Gesamtgebühren';

  @override
  String get swapReviewTotalAmount => 'Gesamtbetrag';

  @override
  String swapReviewSlippageWarning(String amount, String percent) {
    return 'Du könntest bis zu \$$amount weniger erhalten, basierend auf der von dir festgelegten Slippage von $percent%';
  }

  @override
  String get swapReviewConfirm => 'Bestätigen';

  @override
  String get swapDepositAmount => 'Einzahlungsbetrag';

  @override
  String get swapDepositAmountCopied => 'Einzahlungsbetrag in die Zwischenablage kopiert';

  @override
  String get swapDepositDemoWarning => 'Nur zu Demozwecken - sende keine Gelder!';

  @override
  String get swapDepositShareQr => 'QR teilen';

  @override
  String swapDepositShareContent(String network, String token, String address) {
    return 'Netzwerk: $network\nToken: $token\nAdresse: $address';
  }

  @override
  String swapDepositNotice(String symbol, String network) {
    return 'Verwende deine $symbol- oder $network-Wallet, um Gelder einzuzahlen. Das Einzahlen anderer Vermögenswerte kann zum Verlust von Geldern führen.';
  }

  @override
  String get swapDepositProcessingTitle => 'Swap wird verarbeitet';

  @override
  String get swapDepositProcessingBody => 'Dies kann einige Minuten dauern...';

  @override
  String get swapDepositCompleteTitle => 'Swap abgeschlossen';

  @override
  String swapDepositCompleteBody(String amount) {
    return 'Dein Swap über $amount QUAN ist abgeschlossen.';
  }

  @override
  String get swapDepositTestnetBanner => 'NUR DEMO - WIR SIND NOCH IM TESTNET';

  @override
  String get swapDepositSentFunds => 'Ich habe die Gelder gesendet';

  @override
  String get swapDepositDone => 'Fertig';

  @override
  String get swapRefundPickerTitle => 'Rückerstattungsadressen';

  @override
  String get swapRefundPickerEmpty => 'Keine kürzlichen Rückerstattungsadressen';

  @override
  String get componentQrScannerTitle => 'QR-Code scannen';

  @override
  String get componentQrScannerNoCode => 'Kein QR-Code im Bild gefunden';

  @override
  String get componentShare => 'Teilen';

  @override
  String get componentAddressLabel => 'ADRESSE';

  @override
  String get componentCheckphraseLabel => 'PRÜFPHRASE';

  @override
  String get componentCheckphraseCopied => 'Prüfphrase kopiert';

  @override
  String get componentNameFieldHint => 'Gib einen Namen für dein Konto ein';

  @override
  String get commonLoading => 'Wird geladen...';

  @override
  String commonAmountBalance(String balance, String symbol) {
    return '$balance $symbol';
  }

  @override
  String get commonContinue => 'Weiter';

  @override
  String get redeemToLabel => 'Einlösen an';

  @override
  String redeemAddressHint(String symbol) {
    return 'Füge eine $symbol-Adresse ein';
  }

  @override
  String redeemAmountCta(String amount) {
    return '$amount einlösen';
  }

  @override
  String get redeemConfirmTitle => 'Einlösen bestätigen';

  @override
  String get redeemConfirmAmount => 'Betrag';

  @override
  String get redeemConfirmTo => 'An';

  @override
  String get redeemConfirmFee => 'Gebühr';

  @override
  String get redeemFeeValue => '0,1 % Volumengebühr';

  @override
  String get redeemProgressTitle => 'Wird eingelöst...';

  @override
  String get redeemCompleteTitle => 'Einlösen abgeschlossen';

  @override
  String get redeemFailedTitle => 'Einlösen fehlgeschlagen';

  @override
  String get redeemingLabel => 'WIRD EINGELÖST';

  @override
  String get redeemStepCircuits => 'Schaltkreise werden vorbereitet';

  @override
  String get redeemStepTransfers => 'Übertragungen werden abgerufen';

  @override
  String get redeemStepNullifiers => 'Nullifier werden berechnet';

  @override
  String get redeemStepCheckNullifiers => 'Nullifier werden geprüft';

  @override
  String get redeemStepProofs => 'ZK-Beweise werden generiert';

  @override
  String get redeemStepAggregate => 'Wird aggregiert & gesendet';

  @override
  String redeemFetchedCount(int count) {
    return '$count abgerufen';
  }

  @override
  String get redeemCancel => 'Abbrechen';

  @override
  String get redeemRetry => 'Erneut versuchen';

  @override
  String get redeemClose => 'Schließen';

  @override
  String get redeemDone => 'Fertig';

  @override
  String redeemSuccessBanner(String amount, int count) {
    return '$amount in $count Charge(s) eingelöst';
  }
}
