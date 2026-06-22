// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get walletInitErrorTitle => 'वॉलेट त्रुटि';

  @override
  String get walletInitErrorMessage => 'गुप्त वाक्यांश नहीं मिल सका। कृपया अपना वॉलेट पुनर्स्थापित करें।';

  @override
  String get walletInitErrorButtonLabel => 'ठीक है';

  @override
  String get authUseDeviceBiometricsToUnlock => 'अनलॉक करने के लिए डिवाइस बायोमेट्रिक्स का उपयोग करें';

  @override
  String get authAuthenticating => 'प्रमाणित किया जा रहा है...';

  @override
  String get authUnlockWallet => 'वॉलेट अनलॉक करें';

  @override
  String get authAuthorizationRequired => 'प्राधिकरण \n आवश्यक है';

  @override
  String get welcomeTagline => 'क्वांटम-सुरक्षित एन्क्रिप्टेड मुद्रा';

  @override
  String get welcomeCreateNewWallet => 'नया वॉलेट बनाएं';

  @override
  String get welcomeImportWallet => 'वॉलेट आयात करें';

  @override
  String get createWalletCautionHeadline => 'अपने रिकवरी वाक्यांश को गुप्त रखें';

  @override
  String get createWalletCautionBullet1 =>
      'यदि आप यह डिवाइस खो देते हैं, तो रिकवरी वाक्यांश ही वापसी का एकमात्र रास्ता है';

  @override
  String get createWalletCautionBullet2 => 'जिसे भी यह मिल जाएगा, उसका आपके धन पर स्थायी रूप से पूरा नियंत्रण होगा';

  @override
  String get createWalletCautionBullet3 => 'इसे लिखकर किसी सुरक्षित स्थान पर रखें। इसे डिजिटल रूप से सहेजें नहीं';

  @override
  String createWalletRecoveryPhraseSaveError(String error) {
    return 'वॉलेट सहेजने में त्रुटि: $error';
  }

  @override
  String get recoveryPhraseBodyInstructions =>
      'इन शब्दों को क्रम में लिखें और ऐसी जगह रखें जहाँ केवल आप पहुँच सकें। स्क्रीनशॉट न लें या नोट्स ऐप में कॉपी न करें।';

  @override
  String get recoveryPhraseBodyCopy => 'कॉपी करें';

  @override
  String get recoveryPhraseBodyTapToReveal => 'दिखाने के लिए टैप करें';

  @override
  String get recoveryPhraseBodyTapToHide => 'छिपाने के लिए टैप करें';

  @override
  String get recoveryPhraseBodyCopiedMessage => 'रिकवरी वाक्यांश क्लिपबोर्ड पर कॉपी हो गया';

  @override
  String get accountReadyAccountCreated => 'खाता बनाया गया';

  @override
  String get accountReadyWalletCreated => 'वॉलेट बनाया गया';

  @override
  String get accountReadyWalletImported => 'वॉलेट आयात किया गया';

  @override
  String get accountReadyDone => 'हो गया';

  @override
  String get importWalletAppBarTitle => 'वॉलेट आयात करें';

  @override
  String get importWalletDescription => 'अपने 12 या 24 शब्दों के रिकवरी वाक्यांश से मौजूदा वॉलेट पुनर्स्थापित करें';

  @override
  String get importWalletHint => 'अपना रिकवरी वाक्यांश टाइप करें या पेस्ट करें। शब्दों को स्पेस से अलग करें।';

  @override
  String get importWalletButton => 'आयात करें';

  @override
  String get importWalletValidationError => 'रिकवरी वाक्यांश 12 या 24 शब्दों का होना चाहिए';

  @override
  String homeError(String error) {
    return 'त्रुटि: $error';
  }

  @override
  String get homeNoActiveAccount => 'कोई सक्रिय खाता नहीं';

  @override
  String get homeCharge => 'चार्ज';

  @override
  String get homeGetTestnetTokens => 'टेस्टनेट टोकन प्राप्त करें ↗';

  @override
  String get homeErrorLoadingBalance => 'बैलेंस लोड करने में त्रुटि';

  @override
  String get homeBackupReminder => 'अपने रिकवरी वाक्यांश का बैकअप लें';

  @override
  String get homeReceive => 'प्राप्त करें';

  @override
  String get homeSend => 'भेजें';

  @override
  String get homeSwap => 'स्वैप';

  @override
  String get homeActivityTitle => 'गतिविधि';

  @override
  String get homeActivityViewAll => 'सभी देखें';

  @override
  String get homeActivityErrorLoading => 'लेनदेन लोड करने में त्रुटि';

  @override
  String get homeActivityRetry => 'पुनः प्रयास करें';

  @override
  String get homeActivityEmptyTitle => 'अभी तक कोई लेनदेन नहीं';

  @override
  String get homeActivityEmptyMessage => 'QUAN भेजने या प्राप्त करने के बाद आपकी गतिविधि यहाँ दिखाई देगी।';

  @override
  String get accountsSheetTitle => 'खाते';

  @override
  String get accountsSheetFailedLoadAccounts => 'खाते लोड करने में विफल।';

  @override
  String get accountsSheetFailedLoadActiveAccount => 'सक्रिय खाता लोड करने में विफल।';

  @override
  String get accountsSheetNoAccountsFound => 'कोई खाता नहीं मिला।';

  @override
  String get accountsSheetAddAccount => 'खाता जोड़ें';

  @override
  String get accountsSheetBalanceUnavailable => 'बैलेंस उपलब्ध नहीं';

  @override
  String accountsSheetBalance(String balance, String symbol) {
    return '$balance $symbol';
  }

  @override
  String get addAccountMenuTitle => 'खाता जोड़ें';

  @override
  String get addAccountMenuCreateTitle => 'नया खाता बनाएं';

  @override
  String get addAccountMenuCreateSubtitle => 'एक नया वॉलेट पता बनाएं';

  @override
  String get addAccountMenuImportTitle => 'वॉलेट आयात करें';

  @override
  String get addAccountMenuImportSubtitle => 'आयात के लिए रिकवरी वाक्यांश का उपयोग करें';

  @override
  String get addAccountMenuMultisigTitle => 'मल्टीसिग बनाएं';

  @override
  String get addAccountMenuMultisigSubtitle => 'कई हस्ताक्षरकर्ताओं के साथ एक साझा पता सेट करें';

  @override
  String get addAccountMenuDiscoverMultisigTitle => 'मल्टीसिग खोजें';

  @override
  String get addAccountMenuDiscoverMultisigSubtitle => 'ऐसे मल्टीसिग खोजें जहाँ आपके खाते हस्ताक्षरकर्ता हैं';

  @override
  String get multisigTag => 'मल्टीसिग';

  @override
  String get multisigProposeTitle => 'प्रस्ताव';

  @override
  String get multisigAddTitle => 'मल्टीसिग बनाएं';

  @override
  String get multisigDiscoverTitle => 'मल्टीसिग खोजें';

  @override
  String get multisigCreateSubtitle => 'इस मल्टीसिग को एक ऐसा नाम दें जिसे आप पहचान सकें। आप इसे कभी भी बदल सकते हैं।';

  @override
  String get multisigCreateButton => 'बनाएं';

  @override
  String get multisigCreateCreatingButton => 'बनाया जा रहा है';

  @override
  String multisigCreateDefaultName(int number) {
    return 'मल्टीसिग $number';
  }

  @override
  String get multisigCreateErrorCouldNotCreate => 'मल्टीसिग नहीं बनाया जा सका।';

  @override
  String get multisigCreateReadyToast => 'मल्टीसिग आपके खातों में जोड़ा गया।';

  @override
  String get multisigCreateAlreadyExists => 'इस पते के साथ एक मल्टीसिग पहले से ही ऑन-चेन मौजूद है।';

  @override
  String get multisigCreateInsufficientBalance => 'मल्टीसिग बनाने की फीस के लिए अपर्याप्त बैलेंस।';

  @override
  String get multisigCreateTimeoutToast =>
      'मल्टीसिग बनाने में अपेक्षा से अधिक समय लग रहा है। चेन जांचें या पुनः प्रयास करें।';

  @override
  String get multisigCreateAuthReason => 'यह मल्टीसिग बनाने के लिए प्रमाणित करें';

  @override
  String get multisigCreateSignersLabel => 'हस्ताक्षरकर्ता';

  @override
  String get multisigCreateSignersSubtitle => 'अपने अलावा कम से कम एक और हस्ताक्षरकर्ता जोड़ें।';

  @override
  String get multisigCreateAddSignerHint => 'हस्ताक्षरकर्ता SS58 पता';

  @override
  String get multisigCreateAddSignerButton => 'हस्ताक्षरकर्ता जोड़ें';

  @override
  String get multisigCreateDuplicateSigner => 'यह हस्ताक्षरकर्ता पहले से ही सूची में है।';

  @override
  String get multisigCreateInvalidSigner => 'एक मान्य SS58 पता दर्ज करें।';

  @override
  String get multisigCreateThresholdLabel => 'सीमा';

  @override
  String multisigCreateThresholdValue(int count, int total) {
    return '$total में से $count';
  }

  @override
  String get multisigCreatePredictedAddressLabel => 'मल्टीसिग पता';

  @override
  String get multisigCreatePredictedAddressPlaceholder => 'पता देखने के लिए हस्ताक्षरकर्ता जोड़ें';

  @override
  String get multisigDone => 'हो गया';

  @override
  String get multisigAddDiscoveredTitle => 'आपके लिए खोजा गया';

  @override
  String get multisigAddDiscoveredSubtitle => 'चेन पर मल्टीसिग जहाँ आपका कोई खाता हस्ताक्षरकर्ता है';

  @override
  String get multisigAddButton => 'जोड़ें';

  @override
  String get multisigAddedButton => 'जोड़ा गया';

  @override
  String get multisigAddNoneFound => 'कोई मल्टीसिग नहीं मिला।';

  @override
  String multisigAddDiscoverFailed(String error) {
    return 'मल्टीसिग नहीं खोजा जा सका: $error';
  }

  @override
  String multisigAddFailed(String error) {
    return 'मल्टीसिग नहीं जोड़ा जा सका: $error';
  }

  @override
  String get multisigOpenProposals => 'खुले प्रस्ताव';

  @override
  String get multisigPastProposals => 'पिछले प्रस्ताव';

  @override
  String get multisigNoOpenProposals => 'कोई खुला प्रस्ताव नहीं।';

  @override
  String get multisigNoPastProposals => 'कोई पिछला प्रस्ताव नहीं।';

  @override
  String multisigLoadFailed(String error) {
    return 'लोड करने में विफल: $error';
  }

  @override
  String multisigProposalToAddress(String address) {
    return '$address को';
  }

  @override
  String get multisigStatusApproved => 'स्वीकृत';

  @override
  String get multisigStatusProposed => 'प्रस्तावित';

  @override
  String get multisigStatusExpired => 'समाप्त';

  @override
  String get multisigStatusCancelled => 'रद्द';

  @override
  String get multisigProposeSelectRecipientTo => 'इसको स्थानांतरित करें';

  @override
  String multisigProposeSearchHint(String symbol) {
    return '$symbol पता दर्ज करें';
  }

  @override
  String get multisigProposeAmountToLabel => 'इसको स्थानांतरित करें';

  @override
  String get multisigProposeDepositLabel => 'जमा:';

  @override
  String get multisigProposeCreationFeeLabel => 'प्रस्ताव फीस:';

  @override
  String get multisigProposeDepositRefundableNote => 'वापसी योग्य';

  @override
  String get multisigProposeMemberTotalLabel => 'आपके खाते से कुल';

  @override
  String get multisigProposeFeeLabel => 'प्रस्ताव फीस:';

  @override
  String get multisigProposeFeeFetchFailed => 'फीस का अनुमान नहीं लगाया जा सका';

  @override
  String get multisigProposeReviewButton => 'स्थानांतरण की समीक्षा करें';

  @override
  String get multisigProposeReviewProposing => 'प्रस्तावित स्थानांतरण';

  @override
  String multisigProposeReviewFromName(String name) {
    return '$name से';
  }

  @override
  String get multisigProposeThresholdLabel => 'सीमा';

  @override
  String get multisigProposeExpiresLabel => 'समाप्ति';

  @override
  String multisigExpiresBlockOnly(int block) {
    return 'ब्लॉक $block';
  }

  @override
  String get multisigProposeFeeRowLabel => 'प्रस्ताव फीस';

  @override
  String get multisigProposeCreateButton => 'प्रस्ताव सबमिट करें';

  @override
  String get multisigProposeAuthReason => 'लेनदेन प्रस्तावित करने के लिए प्रमाणित करें';

  @override
  String get multisigProposeAuthRequired => 'प्रमाणीकरण आवश्यक';

  @override
  String get multisigProposeSubmitFailed => 'प्रस्ताव बनाने में विफल';

  @override
  String get multisigProposeTimeoutToast =>
      'प्रस्ताव की पुष्टि में अपेक्षा से अधिक समय लग रहा है। चेन जांचें या पुनः प्रयास करें।';

  @override
  String get multisigProposeDoneHeadline => 'स्थानांतरण प्रस्ताव सबमिट किया गया';

  @override
  String get multisigProposeDoneSubline =>
      'स्थानांतरण निष्पादित होने से पहले सह-हस्ताक्षरकर्ताओं को स्वीकृति देनी होगी।';

  @override
  String multisigProposeDoneToChecksum(String checksum) {
    return '$checksum को';
  }

  @override
  String multisigSignaturesCount(int current, int threshold) {
    return 'हस्ताक्षर: $current/$threshold';
  }

  @override
  String get multisigProposalTitle => 'प्रस्ताव';

  @override
  String multisigProposalLoadFailed(String error) {
    return 'विफल: $error';
  }

  @override
  String get multisigProposalNotFound => 'प्रस्ताव नहीं मिला।';

  @override
  String get multisigProposalSignButton => 'हस्ताक्षर करें';

  @override
  String get multisigProposalSigningSoonNote => 'हस्ताक्षर जल्द ही उपलब्ध होगा।';

  @override
  String get multisigProposalApprovingLabel => 'स्वीकृत किया जा रहा है…';

  @override
  String get multisigProposalApprovingNote => 'आपकी स्वीकृति ऑन-चेन पुष्टि हो रही है।';

  @override
  String get multisigApproveUnavailableNote => 'इस प्रस्ताव को अब स्वीकृत नहीं किया जा सकता।';

  @override
  String get activityTxApproving => 'स्वीकृत किया जा रहा है…';

  @override
  String get activityTxCancelling => 'रद्द किया जा रहा है…';

  @override
  String get multisigApprovalTimeoutToast =>
      'स्वीकृति की पुष्टि में अपेक्षा से अधिक समय लग रहा है। चेन जांचें या पुनः प्रयास करें।';

  @override
  String get multisigProposalAlreadySignedNote => 'आप पहले ही इस प्रस्ताव को स्वीकृत कर चुके हैं।';

  @override
  String get multisigProposalAlreadyExecutedNote => 'यह प्रस्ताव पहले ही निष्पादित हो चुका है।';

  @override
  String get multisigProposalAlreadyCancelledNote => 'यह प्रस्ताव पहले ही रद्द हो चुका है।';

  @override
  String get multisigProposalProposerLabel => 'प्रस्तावक';

  @override
  String get multisigProposalStatusLabel => 'स्थिति';

  @override
  String get multisigProposalDepositLabel => 'जमा';

  @override
  String get multisigStatusActive => 'सक्रिय';

  @override
  String get multisigStatusExecuted => 'निष्पादित';

  @override
  String get multisigStatusRemoved => 'हटाया गया';

  @override
  String get multisigStatusUnknown => 'अज्ञात';

  @override
  String get activityTxProposal => 'प्रस्ताव';

  @override
  String get activityTxProposing => 'प्रस्तावित किया जा रहा है';

  @override
  String get activityTxProposalCreated => 'प्रस्ताव बनाया गया';

  @override
  String get activityTxProposalApproved => 'प्रस्ताव स्वीकृत';

  @override
  String get activityTxProposalExecuted => 'प्रस्ताव निष्पादित';

  @override
  String get activityTxProposalCancelled => 'प्रस्ताव रद्द';

  @override
  String get multisigApproveButton => 'स्वीकृत करें';

  @override
  String get multisigAlreadyApproved => 'पहले से स्वीकृत';

  @override
  String get multisigCancelProposalButton => 'प्रस्ताव रद्द करें';

  @override
  String get multisigProposalExpiresLabel => 'समाप्ति';

  @override
  String get multisigProposalAtLabel => 'समय';

  @override
  String get multisigProposalThresholdLabel => 'सीमा';

  @override
  String get multisigProposalApprovalsLabel => 'स्वीकृतियाँ';

  @override
  String get multisigProposalFeeRowLabel => 'प्रस्ताव फीस';

  @override
  String get multisigProposalSignersLabel => 'हस्ताक्षरकर्ता';

  @override
  String get multisigYouLabel => 'आप';

  @override
  String get multisigSignerCreatorLabel => 'निर्माता';

  @override
  String get multisigAccountMenuDetails => 'मल्टीसिग विवरण';

  @override
  String get multisigAccountMenuDetailsTitle => 'मल्टीसिग विवरण';

  @override
  String get multisigAccountMenuDetailsThresholdHint =>
      'प्रस्ताव निष्पादित करने के लिए इतनी हस्ताक्षरकर्ता स्वीकृतियाँ आवश्यक हैं।';

  @override
  String multisigThresholdOf(int count, int total) {
    return '$total में से $count';
  }

  @override
  String multisigApprovalsOf(int count, int threshold) {
    return '$threshold में से $count';
  }

  @override
  String get multisigApproveConfirmTitle => 'क्या आप निश्चित हैं?';

  @override
  String get multisigApproveConfirmBody => 'आप इतनी राशि के स्थानांतरण को स्वीकृत करने वाले हैं';

  @override
  String multisigApproveConfirmTo(String address) {
    return '$address को';
  }

  @override
  String get multisigApproveConfirmYes => 'हाँ, स्वीकृत करें';

  @override
  String get multisigApproveConfirmNo => 'नहीं, वापस जाएं';

  @override
  String get multisigApproveAuthReason => 'स्वीकृत करने के लिए प्रमाणित करें';

  @override
  String get multisigAuthRequired => 'प्रमाणीकरण आवश्यक';

  @override
  String get multisigApproveFailed => 'स्वीकृत करने में विफल';

  @override
  String get multisigExecuteButton => 'निष्पादित करें';

  @override
  String get multisigExecuteConfirmTitle => 'क्या आप निश्चित हैं?';

  @override
  String get multisigExecuteConfirmBody => 'आप इतनी राशि के स्थानांतरण को निष्पादित करने वाले हैं';

  @override
  String get multisigExecuteConfirmYes => 'हाँ, निष्पादित करें';

  @override
  String get multisigExecuteAuthReason => 'निष्पादित करने के लिए प्रमाणित करें';

  @override
  String get multisigExecuteFailed => 'निष्पादित करने में विफल';

  @override
  String get multisigExecuteUnavailableNote => 'इस प्रस्ताव को अब निष्पादित नहीं किया जा सकता।';

  @override
  String get multisigProposalExecutingLabel => 'निष्पादित किया जा रहा है…';

  @override
  String get multisigProposalExecutingNote => 'आपका निष्पादन ऑन-चेन पुष्टि हो रहा है।';

  @override
  String get activityTxExecuting => 'निष्पादित किया जा रहा है…';

  @override
  String get multisigExecutionTimeoutToast =>
      'निष्पादन की पुष्टि में अपेक्षा से अधिक समय लग रहा है। चेन जांचें या पुनः प्रयास करें।';

  @override
  String get multisigExecutedByOtherToast => 'प्रस्ताव किसी अन्य हस्ताक्षरकर्ता द्वारा निष्पादित किया गया।';

  @override
  String get multisigFeeEstimateUnavailable => 'नेटवर्क फीस का अनुमान उपलब्ध नहीं है।';

  @override
  String get multisigCancelConfirmTitle => 'प्रस्ताव रद्द करें?';

  @override
  String get multisigCancelConfirmBody =>
      'रद्द करने से आपकी प्रस्ताव जमा वापस मिल जाएगी। अन्य हस्ताक्षरकर्ता अब स्वीकृत नहीं कर पाएंगे।';

  @override
  String get multisigCancelConfirmYes => 'हाँ, प्रस्ताव रद्द करें';

  @override
  String get multisigCancelConfirmKeep => 'प्रस्ताव रखें';

  @override
  String get multisigCancelAuthReason => 'रद्द करने के लिए प्रमाणित करें';

  @override
  String get multisigCancelFailed => 'रद्द करने में विफल';

  @override
  String get multisigProposalCancellingLabel => 'रद्द किया जा रहा है…';

  @override
  String get multisigProposalCancellingNote => 'आपकी रद्दीकरण ऑन-चेन पुष्टि हो रही है।';

  @override
  String get multisigCancelTimeoutToast =>
      'रद्दीकरण की पुष्टि में अपेक्षा से अधिक समय लग रहा है। चेन जांचें या पुनः प्रयास करें।';

  @override
  String get multisigApproveTitle => 'स्वीकृत करें';

  @override
  String get multisigApproveDoneExecuted => 'प्रस्ताव निष्पादित';

  @override
  String get multisigApproveDoneRecorded => 'स्वीकृति दर्ज की गई';

  @override
  String get multisigApproveDoneExecutedSubline => 'सीमा पूरी हुई — स्थानांतरण भेजा गया।';

  @override
  String get multisigApproveDoneRecordedSubline => 'अधिक सह-हस्ताक्षरकर्ताओं की प्रतीक्षा में।';

  @override
  String get createAccountAppBarTitle => 'खाते का नाम';

  @override
  String get createAccountSubtitle => 'इस खाते को एक ऐसा नाम दें जिसे आप पहचान सकें। आप इसे कभी भी बदल सकते हैं।';

  @override
  String get createAccountButton => 'बनाएं';

  @override
  String get createAccountErrorCouldNotAdd => 'खाता नहीं जोड़ा जा सका।';

  @override
  String createAccountDefaultName(int number) {
    return 'खाता $number';
  }

  @override
  String get editAccountAppBarTitle => 'खाते का नाम';

  @override
  String get editAccountDone => 'हो गया';

  @override
  String get editAccountNameEmpty => 'खाते का नाम खाली नहीं हो सकता';

  @override
  String get editAccountRenameFailed => 'खाते का नाम बदलने में विफल।';

  @override
  String get accountMenuTitle => 'खाते';

  @override
  String get accountMenuAccountName => 'खाते का नाम';

  @override
  String get accountMenuAddressDetails => 'पता विवरण';

  @override
  String get accountMenuShowRecoveryPhrase => 'रिकवरी वाक्यांश दिखाएं';

  @override
  String get accountMenuNotFound => 'खाता नहीं मिला';

  @override
  String get accountDetailsTitle => 'पता विवरण';

  @override
  String get addHardwareAccountAddWallet => 'हार्डवेयर वॉलेट जोड़ें';

  @override
  String get addHardwareAccountAddAccount => 'हार्डवेयर खाता जोड़ें';

  @override
  String get addHardwareAccountNameLabel => 'नाम';

  @override
  String get addHardwareAccountNameHintWallet => 'हार्डवेयर वॉलेट';

  @override
  String get addHardwareAccountNameHintAccount => 'खाता';

  @override
  String get addHardwareAccountAddressLabel => 'पता';

  @override
  String get addHardwareAccountAddressHint => 'SS58 पता';

  @override
  String get addHardwareAccountDebugFill => 'डिबग भरें';

  @override
  String get addHardwareAccountNameRequired => 'नाम आवश्यक है';

  @override
  String get addHardwareAccountInvalidAddress => 'अमान्य पता';

  @override
  String get sendTitle => 'भेजें';

  @override
  String get sendPayTitle => 'भुगतान करें';

  @override
  String get sendEnterAddress => 'पता दर्ज करें';

  @override
  String get sendSelectRecipientSendTo => 'इसको भेजें';

  @override
  String sendSelectRecipientSearchHint(String symbol) {
    return '$symbol पता दर्ज करें';
  }

  @override
  String get sendSelectRecipientScanTitle => 'QR कोड स्कैन करें';

  @override
  String sendSelectRecipientScanSubtitle(String symbol) {
    return '$symbol पता स्कैन करने के लिए टैप करें';
  }

  @override
  String get sendSelectRecipientRecents => 'हाल के';

  @override
  String get sendSelectRecipientContinue => 'जारी रखें';

  @override
  String get sendInputAmountSendTo => 'इसको भेजें';

  @override
  String get sendInputAmountAvailableBalance => 'उपलब्ध बैलेंस:';

  @override
  String get sendInputAmountNetworkFee => 'नेटवर्क फीस:';

  @override
  String get sendInputAmountMax => 'अधिकतम';

  @override
  String get sendInputAmountInvalidAmount => 'कृपया एक मान्य राशि दर्ज करें';

  @override
  String get sendInputAmountChecksumRequired => 'प्राप्तकर्ता चेकसम आवश्यक है';

  @override
  String get sendReviewSending => 'भेजा जा रहा है';

  @override
  String get sendReviewTo => 'प्राप्तकर्ता';

  @override
  String get sendReviewAmount => 'राशि';

  @override
  String get sendReviewNetworkFee => 'नेटवर्क फीस';

  @override
  String get sendReviewYouPay => 'आप भुगतान करते हैं';

  @override
  String get sendReviewConfirm => 'पुष्टि करें';

  @override
  String get sendReviewAuthReason => 'लेनदेन की पुष्टि के लिए प्रमाणित करें';

  @override
  String get sendReviewAuthRequired => 'भेजने के लिए प्रमाणीकरण आवश्यक है';

  @override
  String get sendReviewSubmitFailed => 'लेनदेन सबमिट करने में विफल';

  @override
  String sendTxSubmittedHeadlinePaid(String amount, String symbol) {
    return '$amount $symbol भुगतान किया गया';
  }

  @override
  String sendTxSubmittedHeadlineSent(String amount, String symbol) {
    return '$amount $symbol भेजा गया';
  }

  @override
  String get sendTxSubmittedOnItsWay => 'रास्ते में है';

  @override
  String get sendTxSubmittedToLabel => 'प्राप्तकर्ता';

  @override
  String get sendTxSubmittedDone => 'हो गया';

  @override
  String get sendLogicCantSelfTransfer => 'स्वयं को स्थानांतरण नहीं कर सकते';

  @override
  String get sendLogicEnterAmount => 'राशि दर्ज करें';

  @override
  String get sendLogicInvalidAmount => 'अमान्य राशि';

  @override
  String get sendLogicBelowExistentialDeposit => 'अस्तित्वगत जमा से कम';

  @override
  String get sendLogicInsufficientBalance => 'अपर्याप्त बैलेंस';

  @override
  String get sendLogicReviewSend => 'भेजने की समीक्षा करें';

  @override
  String get activityTitle => 'गतिविधि';

  @override
  String activityError(String error) {
    return 'त्रुटि: $error';
  }

  @override
  String get activityNoAccount => 'कोई खाता नहीं';

  @override
  String get activityEmpty => 'अभी तक कोई लेनदेन नहीं';

  @override
  String get activityFilterAll => 'सभी';

  @override
  String get activityFilterSend => 'भेजें';

  @override
  String get activityFilterReceive => 'प्राप्त करें';

  @override
  String get activityDateToday => 'आज';

  @override
  String get activityDateYesterday => 'कल';

  @override
  String get activityTxSending => 'भेजा जा रहा है';

  @override
  String get activityTxReceiving => 'प्राप्त किया जा रहा है';

  @override
  String get activityTxPending => 'लंबित';

  @override
  String get activityTxSent => 'भेजा गया';

  @override
  String get activityTxReceived => 'प्राप्त हुआ';

  @override
  String get activityTxMultisigCreated => 'मल्टीसिग बनाया गया';

  @override
  String get activityTxMultisigCreating => 'मल्टीसिग बनाया जा रहा है';

  @override
  String get activityTxMultisigLabel => 'मल्टीसिग';

  @override
  String get activityTxTo => 'को';

  @override
  String get activityTxFrom => 'से';

  @override
  String get activityTxTimeNow => 'अभी';

  @override
  String activityTxTimeMinutesAgo(int minutes) {
    return '$minutes मिनट पहले';
  }

  @override
  String activityTxTimeHoursAgo(int hours) {
    return '$hours घंटे पहले';
  }

  @override
  String activityTxTimeDaysAgo(int days) {
    return '$days दिन पहले';
  }

  @override
  String activityTxTimeRemaining(String days, String hours, String minutes) {
    return '$daysदि:$hoursघं:$minutesमि';
  }

  @override
  String get activityDetailTitleSending => 'भेजा जा रहा है';

  @override
  String get activityDetailTitleScheduled => 'निर्धारित';

  @override
  String get activityDetailTitleReceiving => 'प्राप्त किया जा रहा है';

  @override
  String get activityDetailTitleSent => 'भेजा गया';

  @override
  String get activityDetailTitleReceived => 'प्राप्त हुआ';

  @override
  String get activityDetailTitleMultisigCreated => 'मल्टीसिग बनाया गया';

  @override
  String get activityDetailTitleMultisigCreating => 'मल्टीसिग बनाया जा रहा है';

  @override
  String get activityDetailTitleProposalCreated => 'प्रस्ताव बनाया गया';

  @override
  String get activityDetailTitleProposalApproved => 'प्रस्ताव स्वीकृत';

  @override
  String get activityDetailTitleProposalExecuted => 'प्रस्ताव निष्पादित';

  @override
  String get activityDetailTitleProposalCancelled => 'प्रस्ताव रद्द';

  @override
  String get activityDetailTitleCancelling => 'प्रस्ताव रद्द किया जा रहा है';

  @override
  String get activityDetailTitleExecuting => 'प्रस्ताव निष्पादित किया जा रहा है';

  @override
  String get activityDetailTitleProposing => 'प्रस्तावित किया जा रहा है';

  @override
  String get activityDetailProposalTransferAmount => 'स्थानांतरण राशि';

  @override
  String get activityDetailStatusInProcess => 'प्रक्रिया में';

  @override
  String get activityDetailStatusScheduled => 'निर्धारित';

  @override
  String get activityDetailStatusCompleted => 'पूर्ण';

  @override
  String get activityDetailStatus => 'स्थिति';

  @override
  String get activityDetailTo => 'को';

  @override
  String get activityDetailFrom => 'से';

  @override
  String get activityDetailDate => 'दिनांक';

  @override
  String get activityDetailNetworkFee => 'नेटवर्क फीस';

  @override
  String get activityDetailTxHash => 'लेनदेन हैश';

  @override
  String get activityDetailViewExplorer => 'एक्सप्लोरर में देखें ↗';

  @override
  String get activityDetailMultisigAddress => 'मल्टीसिग पता';

  @override
  String get activityDetailMultisigThreshold => 'सीमा';

  @override
  String activityDetailMultisigThresholdValue(int threshold, int total) {
    return '$total में से $threshold';
  }

  @override
  String get activityDetailMultisigSignerCount => 'हस्ताक्षरकर्ता';

  @override
  String get activityDetailMultisigCreator => 'निर्माता';

  @override
  String get activityDetailMultisigCreationFee => 'PALLET फीस';

  @override
  String get activityDetailMultisigDeposit => 'आरक्षित जमा';

  @override
  String get activityDetailMultisigFeePaidByCreator => 'निर्माता द्वारा भुगतान';

  @override
  String get receiveTitle => 'प्राप्त करें';

  @override
  String get receiveTabQrCode => 'QR कोड';

  @override
  String get receiveTabAddress => 'पता';

  @override
  String get receiveCopy => 'कॉपी करें';

  @override
  String receiveErrorLoadingAccount(String error) {
    return 'खाता डेटा लोड करने में त्रुटि: $error';
  }

  @override
  String receiveClipboardContent(String accountId, String checksum) {
    return 'खाता आईडी:\n$accountId\n\nचेकफ्रेज़:\n$checksum';
  }

  @override
  String get receiveCopiedMessage => 'खाता विवरण क्लिपबोर्ड पर कॉपी हुआ';

  @override
  String get posAmountTitle => 'नया चार्ज';

  @override
  String posAmountCharge(String amount) {
    return '$amount चार्ज करें';
  }

  @override
  String get posAmountEnterAmount => 'राशि दर्ज करें';

  @override
  String get posQrTitleScanToPay => 'भुगतान के लिए स्कैन करें';

  @override
  String get posQrTitlePaymentReceived => 'भुगतान प्राप्त हुआ';

  @override
  String posQrError(String error) {
    return 'त्रुटि: $error';
  }

  @override
  String get posQrNoActiveAccount => 'कोई सक्रिय खाता नहीं';

  @override
  String get posQrInvalidAmount => 'अमान्य राशि। पुनः प्रयास के लिए टैप करें।';

  @override
  String get posQrConnectionLost => 'कनेक्शन टूट गया। पुनः प्रयास के लिए टैप करें।';

  @override
  String get posQrTimedOut => 'समय समाप्त। पुनः प्रयास के लिए टैप करें।';

  @override
  String get posQrNewCharge => 'नया चार्ज';

  @override
  String get posQrDone => 'हो गया';

  @override
  String posQrAmountReceived(String amount) {
    return '$amount प्राप्त हुआ';
  }

  @override
  String get posQrFrom => 'से:';

  @override
  String get posQrWaitingForPayment => 'भुगतान की प्रतीक्षा';

  @override
  String get posQrNetworkError => 'नेटवर्क त्रुटि';

  @override
  String get posQrTryAgain => 'पुनः प्रयास करें';

  @override
  String posQrPaidAt(String time) {
    return '$time पर';
  }

  @override
  String get settingsTitle => 'सेटिंग्स';

  @override
  String get settingsWalletTitle => 'वॉलेट';

  @override
  String get settingsWalletSubtitle => 'रिकवरी वाक्यांश, वॉलेट रीसेट करें';

  @override
  String get settingsPreferencesTitle => 'प्राथमिकताएं';

  @override
  String get settingsPreferencesSubtitle => 'भाषा, मुद्रा, POS मोड, सूचनाएं';

  @override
  String get settingsMiningRewards => 'माइनिंग पुरस्कार';

  @override
  String settingsMiningRewardsSubtitle(int count) {
    return '$count ब्लॉक माइन किए गए';
  }

  @override
  String get settingsMiningRewardsError => 'माइनिंग पुरस्कार प्राप्त करने में त्रुटि';

  @override
  String get settingsAccountTypeTitle => 'खाता प्रकार';

  @override
  String get settingsAccountTypeSubtitle => 'उन्नत खाता सुविधाएं';

  @override
  String get settingsHelpTitle => 'सहायता और समर्थन';

  @override
  String get settingsHelpSubtitle => 'अक्सर पूछे जाने वाले प्रश्न, टीम से संपर्क करें';

  @override
  String get settingsAboutTitle => 'Quantus के बारे में';

  @override
  String settingsAboutHubSubtitle(String version, String build) {
    return 'संस्करण $version ($build)';
  }

  @override
  String get settingsWalletRecoveryPhrase => 'रिकवरी वाक्यांश';

  @override
  String get settingsWalletRecoveryPhraseSubtitle => 'अपना 24-शब्द बैकअप पासवर्ड देखें';

  @override
  String get settingsWalletReset => 'वॉलेट रीसेट करें';

  @override
  String get settingsWalletResetSubtitle => 'इस डिवाइस से सारा डेटा हटाता है';

  @override
  String get settingsWalletNoWalletsFound => 'कोई वॉलेट नहीं मिला';

  @override
  String get settingsWalletFailedToLoad => 'वॉलेट लोड करने में विफल';

  @override
  String get settingsSelectWalletTitle => 'वॉलेट चुनें';

  @override
  String get settingsSelectWalletNoWallets => 'कोई वॉलेट नहीं मिला';

  @override
  String settingsSelectWalletItem(int number) {
    return 'वॉलेट $number';
  }

  @override
  String get settingsRecoveryConfirmAuthReason => 'रिकवरी वाक्यांश देखने के लिए प्रमाणित करें';

  @override
  String get settingsRecoveryConfirmAuthRequired => 'रिकवरी वाक्यांश देखने के लिए प्रमाणीकरण आवश्यक है';

  @override
  String get settingsRecoveryPhraseTitle => 'रिकवरी वाक्यांश';

  @override
  String get settingsRecoveryPhraseDone => 'हो गया';

  @override
  String get settingsResetTitle => 'वॉलेट रीसेट करें';

  @override
  String get settingsResetAuthReason => 'वॉलेट रीसेट करने के लिए प्रमाणित करें';

  @override
  String settingsResetFailed(String error) {
    return 'वॉलेट रीसेट करने में विफल: $error';
  }

  @override
  String get settingsResetAuthRequired => 'वॉलेट रीसेट करने के लिए प्रमाणीकरण आवश्यक है';

  @override
  String get settingsResetCautionHeadline => 'यह आपका\nवॉलेट मिटा देगा';

  @override
  String get settingsResetCautionBullet1 => 'सभी वॉलेट डेटा इस डिवाइस से स्थायी रूप से हटा दिया जाएगा';

  @override
  String get settingsResetCautionBullet2 =>
      'आपका धन ब्लॉकचेन पर रहता है लेकिन केवल आपका रिकवरी वाक्यांश ही पहुँच बहाल कर सकता है';

  @override
  String get settingsResetCautionBullet3 => 'इसके बिना, आपका धन हमेशा के लिए चला जाएगा';

  @override
  String get settingsResetCautionCheckbox => 'मैंने अपने रिकवरी वाक्यांश का बैकअप ले लिया है';

  @override
  String get settingsPreferencesCurrency => 'मुद्रा';

  @override
  String get settingsPreferencesCurrencySubtitle => 'फिएट प्रदर्शन प्राथमिकता';

  @override
  String get settingsPreferencesLanguage => 'भाषा';

  @override
  String get settingsPreferencesLanguageSubtitle => 'ऐप प्रदर्शन भाषा';

  @override
  String get settingsPreferencesPosMode => 'POS मोड';

  @override
  String get settingsPreferencesPosModeSubtitle => 'पॉइंट ऑफ सेल सुविधाएं';

  @override
  String get settingsPreferencesNotifications => 'सूचनाएं';

  @override
  String get settingsPreferencesNotificationsSubtitle => 'लेनदेन और वॉलेट अलर्ट';

  @override
  String get settingsCurrencyTitle => 'मुद्रा';

  @override
  String get settingsCurrencySearchHint => 'खोजें';

  @override
  String get settingsCurrencyNoMatch => 'आपकी खोज से कोई मुद्रा मेल नहीं खाती';

  @override
  String settingsCurrencyError(String error) {
    return 'मुद्रा चुनने में त्रुटि: $error';
  }

  @override
  String get settingsLanguageTitle => 'भाषा';

  @override
  String get settingsLanguageSearchHint => 'खोजें';

  @override
  String get settingsLanguageNoMatch => 'आपकी खोज से कोई भाषा मेल नहीं खाती';

  @override
  String settingsLanguageError(String error) {
    return 'भाषा चुनने में त्रुटि: $error';
  }

  @override
  String get settingsMiningTitle => 'माइनिंग पुरस्कार';

  @override
  String get settingsMiningRedeem => 'रिडीम करें';

  @override
  String get settingsMiningStatusMining => 'माइनिंग';

  @override
  String get settingsMiningStatusPending => 'लंबित';

  @override
  String get settingsMiningBlocksMined => 'माइन किए गए ब्लॉक';

  @override
  String get settingsMiningBlocksAcrossTestnets => 'सभी टेस्टनेट में ब्लॉक';

  @override
  String get settingsMiningStatTestnetBlocks => 'टेस्टनेट ब्लॉक';

  @override
  String get settingsMiningStatTestnetRewards => 'टेस्टनेट पुरस्कार';

  @override
  String get settingsMiningStatRedeemed => 'रिडीम किया गया';

  @override
  String get settingsMiningStatRedeemable => 'रिडीम योग्य';

  @override
  String get settingsMiningQuanEarned => 'अर्जित QUAN';

  @override
  String get settingsMiningViewTelemetry => 'टेलीमेट्री देखें ↗';

  @override
  String get settingsMiningNoDataTitle => 'अभी तक कोई माइनिंग डेटा नहीं';

  @override
  String get settingsMiningNoDataBody => 'पुरस्कार अर्जित करना शुरू करने के लिए एक Quantus माइनिंग नोड सेट करें।';

  @override
  String get settingsMiningSetupGuide => 'माइनिंग सेटअप गाइड ↗';

  @override
  String get settingsMiningLoadError => 'माइनिंग पुरस्कार लोड करने में विफल';

  @override
  String get settingsMiningCheckConnection => 'कृपया अपना कनेक्शन जांचें';

  @override
  String get settingsMiningTestnetBlocks => 'ब्लॉक';

  @override
  String get settingsMiningDiracSince => 'नव 2025';

  @override
  String get settingsMiningSchrodingerSince => 'अक्टू 2025';

  @override
  String get settingsMiningResonanceSince => 'जुल 2025';

  @override
  String get settingsTestnetTitle => 'टेस्टनेट पुरस्कार';

  @override
  String get settingsTestnetLoadError => 'टेस्टनेट पुरस्कार लोड करने में विफल';

  @override
  String settingsTestnetTotalBlocks(int count) {
    return '$count ब्लॉक';
  }

  @override
  String get settingsTestnetTotalDescription => 'सभी टेस्टनेट में माइन किए गए कुल ब्लॉक';

  @override
  String get settingsTestnetBreakdown => 'विवरण';

  @override
  String settingsTestnetRowBlocks(int count) {
    return '$count ब्लॉक';
  }

  @override
  String get settingsHelpScreenTitle => 'सहायता और समर्थन';

  @override
  String get settingsHelpEmail => 'ईमेल समर्थन';

  @override
  String get settingsHelpTelegram => 'Telegram';

  @override
  String get settingsAboutScreenTitle => 'के बारे में';

  @override
  String get settingsAboutIntro =>
      'Quantus एक Layer 1 ब्लॉकचेन है जो ML-DSA Dilithium-5 द्वारा सुरक्षित है, जो क्वांटम-प्रतिरोधी एन्क्रिप्शन का स्वर्ण मानक है। एक ऐसे भविष्य के लिए बनाया गया जहाँ पारंपरिक क्रिप्टोग्राफी पर्याप्त नहीं रह जाएगी। सभी के लिए पोस्ट-क्वांटम क्रिप्टोग्राफी।';

  @override
  String get settingsAboutTerms => 'सेवा की शर्तें';

  @override
  String get settingsAboutTermsSubtitle => 'quantus.com/terms/';

  @override
  String get settingsAboutPrivacy => 'गोपनीयता नीति';

  @override
  String get settingsAboutPrivacySubtitle => 'quantus.com/privacy-policy/';

  @override
  String get settingsAboutWebsite => 'वेबसाइट पर जाएं';

  @override
  String get settingsAboutWebsiteSubtitle => 'quantus.com';

  @override
  String settingsAboutVersion(String version, String build) {
    return 'संस्करण $version ($build)';
  }

  @override
  String get settingsAccountTypeScreenTitle => 'खाता प्रकार';

  @override
  String get settingsAccountTypeIntro =>
      'उन्नत खाता सुविधाएं जल्द ही आ रही हैं। ये आपको इस पर अधिक नियंत्रण देंगी कि लेनदेन कैसे अधिकृत और सुरक्षित किए जाते हैं।';

  @override
  String get settingsAccountTypeReversibleTitle => 'प्रतिवर्ती लेनदेन';

  @override
  String get settingsAccountTypeReversibleSubtitle => 'एक समय सीमा के भीतर अपने भेजे गए लेनदेन वापस करें';

  @override
  String get settingsAccountTypeHighSecurityTitle => 'उच्च सुरक्षा खाता';

  @override
  String get settingsAccountTypeHighSecuritySubtitle => 'गार्जियन की स्वीकृति आवश्यक';

  @override
  String get settingsAccountTypeMultiSigTitle => 'मल्टी-सिग्नेचर';

  @override
  String get settingsAccountTypeMultiSigSubtitle => 'कई स्वीकृतियाँ आवश्यक';

  @override
  String get settingsAccountTypeHardwareTitle => 'हार्डवेयर वॉलेट';

  @override
  String get settingsAccountTypeHardwareSubtitle => 'एक हार्डवेयर डिवाइस जोड़ें';

  @override
  String get settingsAccountTypeComingSoon => 'जल्द आ रहा है';

  @override
  String get swapTitle => 'स्वैप';

  @override
  String get swapFrom => 'से';

  @override
  String get swapTo => 'को';

  @override
  String get swapRefundAddress => 'रिफंड पता';

  @override
  String swapRefundAddressHint(String network) {
    return '$network पता';
  }

  @override
  String get swapSlippageTolerance => 'स्लिपेज सहनशीलता';

  @override
  String get swapRate => 'दर';

  @override
  String get swapGetQuote => 'कोट प्राप्त करें';

  @override
  String swapRateLabel(String amount, String symbol) {
    return '1 QUAN = $amount $symbol';
  }

  @override
  String swapRateZero(String symbol) {
    return '1 QUAN = 0 $symbol';
  }

  @override
  String get swapTokenPickerTitle => 'टोकन चुनें';

  @override
  String get swapTokenPickerLoadError => 'टोकन लोड करने में विफल';

  @override
  String get swapReviewTitle => 'कोट की समीक्षा करें';

  @override
  String get swapReviewTotalFees => 'कुल फीस';

  @override
  String get swapReviewTotalAmount => 'कुल राशि';

  @override
  String swapReviewSlippageWarning(String amount, String percent) {
    return 'आपके द्वारा निर्धारित $percent% स्लिपेज के आधार पर आपको \$$amount तक कम मिल सकता है';
  }

  @override
  String get swapReviewConfirm => 'पुष्टि करें';

  @override
  String get swapDepositAmount => 'जमा राशि';

  @override
  String get swapDepositAmountCopied => 'जमा राशि क्लिपबोर्ड पर कॉपी हुई';

  @override
  String get swapDepositDemoWarning => 'केवल डेमो उद्देश्यों के लिए - धन न भेजें!';

  @override
  String get swapDepositShareQr => 'QR साझा करें';

  @override
  String swapDepositShareContent(String network, String token, String address) {
    return 'नेटवर्क: $network\nटोकन: $token\nपता: $address';
  }

  @override
  String swapDepositNotice(String symbol, String network) {
    return 'धन जमा करने के लिए अपने $symbol या $network वॉलेट का उपयोग करें। अन्य संपत्ति जमा करने से धन की हानि हो सकती है।';
  }

  @override
  String get swapDepositProcessingTitle => 'स्वैप संसाधित हो रहा है';

  @override
  String get swapDepositProcessingBody => 'इसमें कुछ मिनट लग सकते हैं...';

  @override
  String get swapDepositCompleteTitle => 'स्वैप पूर्ण';

  @override
  String swapDepositCompleteBody(String amount) {
    return 'आपका $amount QUAN का स्वैप पूर्ण हो गया है।';
  }

  @override
  String get swapDepositTestnetBanner => 'केवल डेमो - हम अभी भी टेस्टनेट पर हैं';

  @override
  String get swapDepositSentFunds => 'मैंने धन भेज दिया है';

  @override
  String get swapDepositDone => 'हो गया';

  @override
  String get swapRefundPickerTitle => 'रिफंड पते';

  @override
  String get swapRefundPickerEmpty => 'कोई हालिया रिफंड पता नहीं';

  @override
  String get componentQrScannerTitle => 'QR कोड स्कैन करें';

  @override
  String get componentQrScannerNoCode => 'छवि में कोई QR कोड नहीं मिला';

  @override
  String get componentShare => 'साझा करें';

  @override
  String get componentAddressLabel => 'पता';

  @override
  String get componentCheckphraseLabel => 'चेकफ्रेज़';

  @override
  String get componentCheckphraseCopied => 'चेकफ्रेज़ कॉपी हुआ';

  @override
  String get componentNameFieldHint => 'अपने खाते के लिए एक नाम दर्ज करें';

  @override
  String get commonLoading => 'लोड हो रहा है...';

  @override
  String commonAmountBalance(String balance, String symbol) {
    return '$balance $symbol';
  }

  @override
  String get commonContinue => 'जारी रखें';

  @override
  String get redeemToLabel => 'इसमें रिडीम करें';

  @override
  String redeemAddressHint(String symbol) {
    return '$symbol पता पेस्ट करें';
  }

  @override
  String redeemAmountCta(String amount) {
    return '$amount रिडीम करें';
  }

  @override
  String get redeemConfirmTitle => 'रिडीम की पुष्टि करें';

  @override
  String get redeemConfirmAmount => 'राशि';

  @override
  String get redeemConfirmTo => 'को';

  @override
  String get redeemConfirmFee => 'फीस';

  @override
  String get redeemFeeValue => '0.1% वॉल्यूम फीस';

  @override
  String get redeemProgressTitle => 'रिडीम किया जा रहा है...';

  @override
  String get redeemCompleteTitle => 'रिडीम पूर्ण';

  @override
  String get redeemFailedTitle => 'रिडीम विफल';

  @override
  String get redeemingLabel => 'रिडीम किया जा रहा है';

  @override
  String get redeemStepCircuits => 'सर्किट तैयार किए जा रहे हैं';

  @override
  String get redeemStepTransfers => 'स्थानांतरण प्राप्त किए जा रहे हैं';

  @override
  String get redeemStepNullifiers => 'नलिफायर की गणना की जा रही है';

  @override
  String get redeemStepCheckNullifiers => 'नलिफायर की जांच की जा रही है';

  @override
  String get redeemStepProofs => 'ZK प्रमाण उत्पन्न किए जा रहे हैं';

  @override
  String get redeemStepAggregate => 'एकत्रित और सबमिट किया जा रहा है';

  @override
  String redeemFetchedCount(int count) {
    return '$count प्राप्त';
  }

  @override
  String get redeemCancel => 'रद्द करें';

  @override
  String get redeemRetry => 'पुनः प्रयास करें';

  @override
  String get redeemClose => 'बंद करें';

  @override
  String get redeemDone => 'हो गया';

  @override
  String redeemSuccessBanner(String amount, int count) {
    return '$count बैच में $amount रिडीम किया गया';
  }
}
