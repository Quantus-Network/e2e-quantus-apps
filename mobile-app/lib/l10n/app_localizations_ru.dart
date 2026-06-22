// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get walletInitErrorTitle => 'Ошибка кошелька';

  @override
  String get walletInitErrorMessage => 'Не удалось найти секретную фразу. Пожалуйста, восстановите кошелёк.';

  @override
  String get walletInitErrorButtonLabel => 'ОК';

  @override
  String get authUseDeviceBiometricsToUnlock => 'Используйте биометрию устройства для разблокировки';

  @override
  String get authAuthenticating => 'Аутентификация...';

  @override
  String get authUnlockWallet => 'Разблокировать кошелёк';

  @override
  String get authAuthorizationRequired => 'Требуется \n авторизация';

  @override
  String get welcomeTagline => 'Квантово-защищённые зашифрованные деньги';

  @override
  String get welcomeCreateNewWallet => 'Создать новый кошелёк';

  @override
  String get welcomeImportWallet => 'Импортировать кошелёк';

  @override
  String get createWalletCautionHeadline => 'Храните свою фразу восстановления в секрете';

  @override
  String get createWalletCautionBullet1 =>
      'Если вы потеряете это устройство, фраза восстановления — единственный способ вернуть доступ';

  @override
  String get createWalletCautionBullet2 =>
      'Любой, кто получит её, получит полный и постоянный контроль над вашими средствами';

  @override
  String get createWalletCautionBullet3 => 'Запишите её и храните в безопасном месте. Не сохраняйте в цифровом виде';

  @override
  String createWalletRecoveryPhraseSaveError(String error) {
    return 'Ошибка сохранения кошелька: $error';
  }

  @override
  String get recoveryPhraseBodyInstructions =>
      'Запишите эти слова по порядку и храните там, где только вы имеете доступ. Не делайте скриншот и не копируйте в заметки.';

  @override
  String get recoveryPhraseBodyCopy => 'Копировать';

  @override
  String get recoveryPhraseBodyTapToReveal => 'Нажмите, чтобы показать';

  @override
  String get recoveryPhraseBodyTapToHide => 'Нажмите, чтобы скрыть';

  @override
  String get recoveryPhraseBodyCopiedMessage => 'Фраза восстановления скопирована в буфер обмена';

  @override
  String get accountReadyAccountCreated => 'Аккаунт создан';

  @override
  String get accountReadyWalletCreated => 'Кошелёк создан';

  @override
  String get accountReadyWalletImported => 'Кошелёк импортирован';

  @override
  String get accountReadyDone => 'Готово';

  @override
  String get importWalletAppBarTitle => 'Импорт кошелька';

  @override
  String get importWalletDescription => 'Восстановите существующий кошелёк с помощью фразы из 12 или 24 слов';

  @override
  String get importWalletHint => 'Введите или вставьте фразу восстановления. Разделяйте слова пробелами.';

  @override
  String get importWalletButton => 'Импорт';

  @override
  String get importWalletValidationError => 'Фраза восстановления должна содержать 12 или 24 слова';

  @override
  String homeError(String error) {
    return 'Ошибка: $error';
  }

  @override
  String get homeNoActiveAccount => 'Нет активного аккаунта';

  @override
  String get homeCharge => 'Оплата';

  @override
  String get homeGetTestnetTokens => 'Получить токены тестовой сети ↗';

  @override
  String get homeErrorLoadingBalance => 'Ошибка загрузки баланса';

  @override
  String get homeBackupReminder => 'Сделайте резервную копию фразы восстановления';

  @override
  String get homeReceive => 'Получить';

  @override
  String get homeSend => 'Отправить';

  @override
  String get homeSwap => 'Обмен';

  @override
  String get homeActivityTitle => 'Активность';

  @override
  String get homeActivityViewAll => 'Показать всё';

  @override
  String get homeActivityErrorLoading => 'Ошибка загрузки транзакций';

  @override
  String get homeActivityRetry => 'Повторить';

  @override
  String get homeActivityEmptyTitle => 'Пока нет транзакций';

  @override
  String get homeActivityEmptyMessage => 'Ваша активность появится здесь после отправки или получения QUAN.';

  @override
  String get accountsSheetTitle => 'Аккаунты';

  @override
  String get accountsSheetFailedLoadAccounts => 'Не удалось загрузить аккаунты.';

  @override
  String get accountsSheetFailedLoadActiveAccount => 'Не удалось загрузить активный аккаунт.';

  @override
  String get accountsSheetNoAccountsFound => 'Аккаунты не найдены.';

  @override
  String get accountsSheetAddAccount => 'Добавить аккаунт';

  @override
  String get accountsSheetBalanceUnavailable => 'Баланс недоступен';

  @override
  String accountsSheetBalance(String balance, String symbol) {
    return '$balance $symbol';
  }

  @override
  String get addAccountMenuTitle => 'Добавить аккаунт';

  @override
  String get addAccountMenuCreateTitle => 'Создать новый аккаунт';

  @override
  String get addAccountMenuCreateSubtitle => 'Сгенерировать новый адрес кошелька';

  @override
  String get addAccountMenuImportTitle => 'Импортировать кошелёк';

  @override
  String get addAccountMenuImportSubtitle => 'Использовать фразу восстановления для импорта';

  @override
  String get addAccountMenuMultisigTitle => 'Создать мультиподпись';

  @override
  String get addAccountMenuMultisigSubtitle => 'Настроить общий адрес с несколькими подписантами';

  @override
  String get addAccountMenuDiscoverMultisigTitle => 'Найти мультиподпись';

  @override
  String get addAccountMenuDiscoverMultisigSubtitle => 'Найти мультиподписи, где ваши аккаунты являются подписантами';

  @override
  String get multisigTag => 'МУЛЬТИПОДПИСЬ';

  @override
  String get multisigProposeTitle => 'Предложить';

  @override
  String get multisigAddTitle => 'Создать мультиподпись';

  @override
  String get multisigDiscoverTitle => 'Найти мультиподпись';

  @override
  String get multisigCreateSubtitle => 'Дайте этой мультиподписи узнаваемое имя. Вы можете изменить его в любое время.';

  @override
  String get multisigCreateButton => 'Создать';

  @override
  String get multisigCreateCreatingButton => 'Создание';

  @override
  String multisigCreateDefaultName(int number) {
    return 'Мультиподпись $number';
  }

  @override
  String get multisigCreateErrorCouldNotCreate => 'Не удалось создать мультиподпись.';

  @override
  String get multisigCreateReadyToast => 'Мультиподпись добавлена в ваши аккаунты.';

  @override
  String get multisigCreateAlreadyExists => 'Мультиподпись с этим адресом уже существует в сети.';

  @override
  String get multisigCreateInsufficientBalance => 'Недостаточно средств для оплаты создания мультиподписи.';

  @override
  String get multisigCreateTimeoutToast =>
      'Создание мультиподписи занимает больше времени, чем ожидалось. Проверьте сеть или повторите.';

  @override
  String get multisigCreateAuthReason => 'Пройдите аутентификацию, чтобы создать эту мультиподпись';

  @override
  String get multisigCreateSignersLabel => 'ПОДПИСАНТЫ';

  @override
  String get multisigCreateSignersSubtitle => 'Добавьте хотя бы одного подписанта помимо себя.';

  @override
  String get multisigCreateAddSignerHint => 'SS58-адрес подписанта';

  @override
  String get multisigCreateAddSignerButton => 'Добавить подписанта';

  @override
  String get multisigCreateDuplicateSigner => 'Этот подписант уже в списке.';

  @override
  String get multisigCreateInvalidSigner => 'Введите действительный SS58-адрес.';

  @override
  String get multisigCreateThresholdLabel => 'ПОРОГ';

  @override
  String multisigCreateThresholdValue(int count, int total) {
    return '$count из $total';
  }

  @override
  String get multisigCreatePredictedAddressLabel => 'АДРЕС МУЛЬТИПОДПИСИ';

  @override
  String get multisigCreatePredictedAddressPlaceholder => 'Добавьте подписантов для предпросмотра адреса';

  @override
  String get multisigDone => 'Готово';

  @override
  String get multisigAddDiscoveredTitle => 'Найдено для вас';

  @override
  String get multisigAddDiscoveredSubtitle => 'Мультиподписи в сети, где один из ваших аккаунтов является подписантом';

  @override
  String get multisigAddButton => 'Добавить';

  @override
  String get multisigAddedButton => 'Добавлено';

  @override
  String get multisigAddNoneFound => 'Мультиподписи не найдены.';

  @override
  String multisigAddDiscoverFailed(String error) {
    return 'Не удалось найти мультиподписи: $error';
  }

  @override
  String multisigAddFailed(String error) {
    return 'Не удалось добавить мультиподпись: $error';
  }

  @override
  String get multisigOpenProposals => 'Открытые предложения';

  @override
  String get multisigPastProposals => 'Прошлые предложения';

  @override
  String get multisigNoOpenProposals => 'Нет открытых предложений.';

  @override
  String get multisigNoPastProposals => 'Нет прошлых предложений.';

  @override
  String multisigLoadFailed(String error) {
    return 'Не удалось загрузить: $error';
  }

  @override
  String multisigProposalToAddress(String address) {
    return 'на $address';
  }

  @override
  String get multisigStatusApproved => 'ОДОБРЕНО';

  @override
  String get multisigStatusProposed => 'ПРЕДЛОЖЕНО';

  @override
  String get multisigStatusExpired => 'ИСТЕКЛО';

  @override
  String get multisigStatusCancelled => 'ОТМЕНЕНО';

  @override
  String get multisigProposeSelectRecipientTo => 'Перевести на';

  @override
  String multisigProposeSearchHint(String symbol) {
    return 'Введите адрес $symbol';
  }

  @override
  String get multisigProposeAmountToLabel => 'ПЕРЕВЕСТИ НА';

  @override
  String get multisigProposeDepositLabel => 'Депозит:';

  @override
  String get multisigProposeCreationFeeLabel => 'Комиссия за предложение:';

  @override
  String get multisigProposeDepositRefundableNote => 'возвращается';

  @override
  String get multisigProposeMemberTotalLabel => 'ВСЕГО С ВАШЕГО АККАУНТА';

  @override
  String get multisigProposeFeeLabel => 'Комиссия за предложение:';

  @override
  String get multisigProposeFeeFetchFailed => 'Не удалось оценить комиссию';

  @override
  String get multisigProposeReviewButton => 'Проверить перевод';

  @override
  String get multisigProposeReviewProposing => 'ПРЕДЛАГАЕМЫЙ ПЕРЕВОД';

  @override
  String multisigProposeReviewFromName(String name) {
    return 'от $name';
  }

  @override
  String get multisigProposeThresholdLabel => 'ПОРОГ';

  @override
  String get multisigProposeExpiresLabel => 'ИСТЕКАЕТ';

  @override
  String multisigExpiresBlockOnly(int block) {
    return 'Блок $block';
  }

  @override
  String get multisigProposeFeeRowLabel => 'КОМИССИЯ ЗА ПРЕДЛОЖЕНИЕ';

  @override
  String get multisigProposeCreateButton => 'Отправить предложение';

  @override
  String get multisigProposeAuthReason => 'Пройдите аутентификацию, чтобы предложить транзакцию';

  @override
  String get multisigProposeAuthRequired => 'Требуется аутентификация';

  @override
  String get multisigProposeSubmitFailed => 'Не удалось создать предложение';

  @override
  String get multisigProposeTimeoutToast =>
      'Подтверждение предложения занимает больше времени, чем ожидалось. Проверьте сеть или повторите.';

  @override
  String get multisigProposeDoneHeadline => 'Предложение перевода отправлено';

  @override
  String get multisigProposeDoneSubline => 'Со-подписанты должны одобрить, прежде чем перевод сможет быть выполнен.';

  @override
  String multisigProposeDoneToChecksum(String checksum) {
    return 'на $checksum';
  }

  @override
  String multisigSignaturesCount(int current, int threshold) {
    return 'Подписи: $current/$threshold';
  }

  @override
  String get multisigProposalTitle => 'Предложение';

  @override
  String multisigProposalLoadFailed(String error) {
    return 'Ошибка: $error';
  }

  @override
  String get multisigProposalNotFound => 'Предложение не найдено.';

  @override
  String get multisigProposalSignButton => 'Подписать';

  @override
  String get multisigProposalSigningSoonNote => 'Подписание скоро станет доступно.';

  @override
  String get multisigProposalApprovingLabel => 'Одобрение…';

  @override
  String get multisigProposalApprovingNote => 'Ваше одобрение подтверждается в сети.';

  @override
  String get multisigApproveUnavailableNote => 'Это предложение больше нельзя одобрить.';

  @override
  String get activityTxApproving => 'Одобрение…';

  @override
  String get activityTxCancelling => 'Отмена…';

  @override
  String get multisigApprovalTimeoutToast =>
      'Подтверждение одобрения занимает больше времени, чем ожидалось. Проверьте сеть или повторите.';

  @override
  String get multisigProposalAlreadySignedNote => 'Вы уже одобрили это предложение.';

  @override
  String get multisigProposalAlreadyExecutedNote => 'Это предложение уже выполнено.';

  @override
  String get multisigProposalAlreadyCancelledNote => 'Это предложение уже отменено.';

  @override
  String get multisigProposalProposerLabel => 'ИНИЦИАТОР';

  @override
  String get multisigProposalStatusLabel => 'СТАТУС';

  @override
  String get multisigProposalDepositLabel => 'ДЕПОЗИТ';

  @override
  String get multisigStatusActive => 'АКТИВНО';

  @override
  String get multisigStatusExecuted => 'ВЫПОЛНЕНО';

  @override
  String get multisigStatusRemoved => 'УДАЛЕНО';

  @override
  String get multisigStatusUnknown => 'НЕИЗВЕСТНО';

  @override
  String get activityTxProposal => 'Предложение';

  @override
  String get activityTxProposing => 'Предложение';

  @override
  String get activityTxProposalCreated => 'Предложение создано';

  @override
  String get activityTxProposalApproved => 'Предложение одобрено';

  @override
  String get activityTxProposalExecuted => 'Предложение выполнено';

  @override
  String get activityTxProposalCancelled => 'Предложение отменено';

  @override
  String get multisigApproveButton => 'Одобрить';

  @override
  String get multisigAlreadyApproved => 'Уже одобрено';

  @override
  String get multisigCancelProposalButton => 'Отменить предложение';

  @override
  String get multisigProposalExpiresLabel => 'ИСТЕКАЕТ';

  @override
  String get multisigProposalAtLabel => 'В';

  @override
  String get multisigProposalThresholdLabel => 'ПОРОГ';

  @override
  String get multisigProposalApprovalsLabel => 'ОДОБРЕНИЯ';

  @override
  String get multisigProposalFeeRowLabel => 'КОМИССИЯ ЗА ПРЕДЛОЖЕНИЕ';

  @override
  String get multisigProposalSignersLabel => 'ПОДПИСАНТЫ';

  @override
  String get multisigYouLabel => 'ВЫ';

  @override
  String get multisigSignerCreatorLabel => 'СОЗДАТЕЛЬ';

  @override
  String get multisigAccountMenuDetails => 'Детали мультиподписи';

  @override
  String get multisigAccountMenuDetailsTitle => 'Детали мультиподписи';

  @override
  String get multisigAccountMenuDetailsThresholdHint =>
      'Столько одобрений подписантов требуется для выполнения предложения.';

  @override
  String multisigThresholdOf(int count, int total) {
    return '$count из $total';
  }

  @override
  String multisigApprovalsOf(int count, int threshold) {
    return '$count из $threshold';
  }

  @override
  String get multisigApproveConfirmTitle => 'Вы уверены?';

  @override
  String get multisigApproveConfirmBody => 'Вы собираетесь одобрить перевод на сумму';

  @override
  String multisigApproveConfirmTo(String address) {
    return 'на $address';
  }

  @override
  String get multisigApproveConfirmYes => 'Да, одобрить';

  @override
  String get multisigApproveConfirmNo => 'Нет, назад';

  @override
  String get multisigApproveAuthReason => 'Пройдите аутентификацию, чтобы одобрить';

  @override
  String get multisigAuthRequired => 'Требуется аутентификация';

  @override
  String get multisigApproveFailed => 'Не удалось одобрить';

  @override
  String get multisigExecuteButton => 'Выполнить';

  @override
  String get multisigExecuteConfirmTitle => 'Вы уверены?';

  @override
  String get multisigExecuteConfirmBody => 'Вы собираетесь выполнить перевод на сумму';

  @override
  String get multisigExecuteConfirmYes => 'Да, выполнить';

  @override
  String get multisigExecuteAuthReason => 'Пройдите аутентификацию, чтобы выполнить';

  @override
  String get multisigExecuteFailed => 'Не удалось выполнить';

  @override
  String get multisigExecuteUnavailableNote => 'Это предложение больше нельзя выполнить.';

  @override
  String get multisigProposalExecutingLabel => 'Выполнение…';

  @override
  String get multisigProposalExecutingNote => 'Ваше выполнение подтверждается в сети.';

  @override
  String get activityTxExecuting => 'Выполнение…';

  @override
  String get multisigExecutionTimeoutToast =>
      'Подтверждение выполнения занимает больше времени, чем ожидалось. Проверьте сеть или повторите.';

  @override
  String get multisigExecutedByOtherToast => 'Предложение было выполнено другим подписантом.';

  @override
  String get multisigFeeEstimateUnavailable => 'Оценка сетевой комиссии недоступна.';

  @override
  String get multisigCancelConfirmTitle => 'Отменить предложение?';

  @override
  String get multisigCancelConfirmBody =>
      'Отмена вернёт ваш депозит за предложение. Другие подписанты больше не смогут одобрять.';

  @override
  String get multisigCancelConfirmYes => 'Да, отменить предложение';

  @override
  String get multisigCancelConfirmKeep => 'Оставить предложение';

  @override
  String get multisigCancelAuthReason => 'Пройдите аутентификацию, чтобы отменить';

  @override
  String get multisigCancelFailed => 'Не удалось отменить';

  @override
  String get multisigProposalCancellingLabel => 'Отмена…';

  @override
  String get multisigProposalCancellingNote => 'Ваша отмена подтверждается в сети.';

  @override
  String get multisigCancelTimeoutToast =>
      'Подтверждение отмены занимает больше времени, чем ожидалось. Проверьте сеть или повторите.';

  @override
  String get multisigApproveTitle => 'Одобрить';

  @override
  String get multisigApproveDoneExecuted => 'Предложение выполнено';

  @override
  String get multisigApproveDoneRecorded => 'Одобрение записано';

  @override
  String get multisigApproveDoneExecutedSubline => 'Порог достигнут — перевод отправлен.';

  @override
  String get multisigApproveDoneRecordedSubline => 'Ожидание других со-подписантов.';

  @override
  String get createAccountAppBarTitle => 'Имя аккаунта';

  @override
  String get createAccountSubtitle => 'Дайте этому аккаунту узнаваемое имя. Вы можете изменить его в любое время.';

  @override
  String get createAccountButton => 'Создать';

  @override
  String get createAccountErrorCouldNotAdd => 'Не удалось добавить аккаунт.';

  @override
  String createAccountDefaultName(int number) {
    return 'Аккаунт $number';
  }

  @override
  String get editAccountAppBarTitle => 'Имя аккаунта';

  @override
  String get editAccountDone => 'Готово';

  @override
  String get editAccountNameEmpty => 'Имя аккаунта не может быть пустым';

  @override
  String get editAccountRenameFailed => 'Не удалось переименовать аккаунт.';

  @override
  String get accountMenuTitle => 'Аккаунты';

  @override
  String get accountMenuAccountName => 'Имя аккаунта';

  @override
  String get accountMenuAddressDetails => 'Детали адреса';

  @override
  String get accountMenuShowRecoveryPhrase => 'Показать фразу восстановления';

  @override
  String get accountMenuNotFound => 'Аккаунт не найден';

  @override
  String get accountDetailsTitle => 'Детали адреса';

  @override
  String get addHardwareAccountAddWallet => 'Добавить аппаратный кошелёк';

  @override
  String get addHardwareAccountAddAccount => 'Добавить аппаратный аккаунт';

  @override
  String get addHardwareAccountNameLabel => 'ИМЯ';

  @override
  String get addHardwareAccountNameHintWallet => 'Аппаратный кошелёк';

  @override
  String get addHardwareAccountNameHintAccount => 'Аккаунт';

  @override
  String get addHardwareAccountAddressLabel => 'АДРЕС';

  @override
  String get addHardwareAccountAddressHint => 'SS58-адрес';

  @override
  String get addHardwareAccountDebugFill => 'Отладочное заполнение';

  @override
  String get addHardwareAccountNameRequired => 'Имя обязательно';

  @override
  String get addHardwareAccountInvalidAddress => 'Недействительный адрес';

  @override
  String get sendTitle => 'Отправить';

  @override
  String get sendPayTitle => 'Оплатить';

  @override
  String get sendEnterAddress => 'Введите адрес';

  @override
  String get sendSelectRecipientSendTo => 'Отправить на';

  @override
  String sendSelectRecipientSearchHint(String symbol) {
    return 'Введите адрес $symbol';
  }

  @override
  String get sendSelectRecipientScanTitle => 'Сканировать QR-код';

  @override
  String sendSelectRecipientScanSubtitle(String symbol) {
    return 'Нажмите, чтобы отсканировать адрес $symbol';
  }

  @override
  String get sendSelectRecipientRecents => 'Недавние';

  @override
  String get sendSelectRecipientContinue => 'Продолжить';

  @override
  String get sendInputAmountSendTo => 'ОТПРАВИТЬ НА';

  @override
  String get sendInputAmountAvailableBalance => 'Доступный баланс:';

  @override
  String get sendInputAmountNetworkFee => 'Сетевая комиссия:';

  @override
  String get sendInputAmountMax => 'Макс';

  @override
  String get sendInputAmountInvalidAmount => 'Введите корректную сумму';

  @override
  String get sendInputAmountChecksumRequired => 'Требуется контрольная фраза получателя';

  @override
  String get sendReviewSending => 'ОТПРАВКА';

  @override
  String get sendReviewTo => 'ПОЛУЧАТЕЛЬ';

  @override
  String get sendReviewAmount => 'СУММА';

  @override
  String get sendReviewNetworkFee => 'СЕТЕВАЯ КОМИССИЯ';

  @override
  String get sendReviewYouPay => 'ВЫ ПЛАТИТЕ';

  @override
  String get sendReviewConfirm => 'Подтвердить';

  @override
  String get sendReviewAuthReason => 'Пройдите аутентификацию, чтобы подтвердить транзакцию';

  @override
  String get sendReviewAuthRequired => 'Для отправки требуется аутентификация';

  @override
  String get sendReviewSubmitFailed => 'Не удалось отправить транзакцию';

  @override
  String sendTxSubmittedHeadlinePaid(String amount, String symbol) {
    return '$amount $symbol оплачено';
  }

  @override
  String sendTxSubmittedHeadlineSent(String amount, String symbol) {
    return '$amount $symbol отправлено';
  }

  @override
  String get sendTxSubmittedOnItsWay => 'В пути';

  @override
  String get sendTxSubmittedToLabel => 'Получатель';

  @override
  String get sendTxSubmittedDone => 'Готово';

  @override
  String get sendLogicCantSelfTransfer => 'Нельзя перевести себе';

  @override
  String get sendLogicEnterAmount => 'Введите сумму';

  @override
  String get sendLogicInvalidAmount => 'Некорректная сумма';

  @override
  String get sendLogicBelowExistentialDeposit => 'Ниже минимального депозита';

  @override
  String get sendLogicInsufficientBalance => 'Недостаточно средств';

  @override
  String get sendLogicReviewSend => 'Проверить отправку';

  @override
  String get activityTitle => 'Активность';

  @override
  String activityError(String error) {
    return 'Ошибка: $error';
  }

  @override
  String get activityNoAccount => 'Нет аккаунта';

  @override
  String get activityEmpty => 'Пока нет транзакций';

  @override
  String get activityFilterAll => 'Все';

  @override
  String get activityFilterSend => 'Отправка';

  @override
  String get activityFilterReceive => 'Получение';

  @override
  String get activityDateToday => 'Сегодня';

  @override
  String get activityDateYesterday => 'Вчера';

  @override
  String get activityTxSending => 'Отправка';

  @override
  String get activityTxReceiving => 'Получение';

  @override
  String get activityTxPending => 'В ожидании';

  @override
  String get activityTxSent => 'Отправлено';

  @override
  String get activityTxReceived => 'Получено';

  @override
  String get activityTxMultisigCreated => 'Мультиподпись создана';

  @override
  String get activityTxMultisigCreating => 'Создание мультиподписи';

  @override
  String get activityTxMultisigLabel => 'Мультиподпись';

  @override
  String get activityTxTo => 'Кому';

  @override
  String get activityTxFrom => 'От';

  @override
  String get activityTxTimeNow => 'сейчас';

  @override
  String activityTxTimeMinutesAgo(int minutes) {
    return '$minutes мин назад';
  }

  @override
  String activityTxTimeHoursAgo(int hours) {
    return '$hours ч назад';
  }

  @override
  String activityTxTimeDaysAgo(int days) {
    return '$days дн назад';
  }

  @override
  String activityTxTimeRemaining(String days, String hours, String minutes) {
    return '$daysд:$hoursч:$minutesм';
  }

  @override
  String get activityDetailTitleSending => 'Отправка';

  @override
  String get activityDetailTitleScheduled => 'Запланировано';

  @override
  String get activityDetailTitleReceiving => 'Получение';

  @override
  String get activityDetailTitleSent => 'Отправлено';

  @override
  String get activityDetailTitleReceived => 'Получено';

  @override
  String get activityDetailTitleMultisigCreated => 'Мультиподпись создана';

  @override
  String get activityDetailTitleMultisigCreating => 'Создание мультиподписи';

  @override
  String get activityDetailTitleProposalCreated => 'Предложение создано';

  @override
  String get activityDetailTitleProposalApproved => 'Предложение одобрено';

  @override
  String get activityDetailTitleProposalExecuted => 'Предложение выполнено';

  @override
  String get activityDetailTitleProposalCancelled => 'Предложение отменено';

  @override
  String get activityDetailTitleCancelling => 'Отмена предложения';

  @override
  String get activityDetailTitleExecuting => 'Выполнение предложения';

  @override
  String get activityDetailTitleProposing => 'Предложение';

  @override
  String get activityDetailProposalTransferAmount => 'СУММА ПЕРЕВОДА';

  @override
  String get activityDetailStatusInProcess => 'В процессе';

  @override
  String get activityDetailStatusScheduled => 'Запланировано';

  @override
  String get activityDetailStatusCompleted => 'Завершено';

  @override
  String get activityDetailStatus => 'СТАТУС';

  @override
  String get activityDetailTo => 'КОМУ';

  @override
  String get activityDetailFrom => 'ОТ';

  @override
  String get activityDetailDate => 'ДАТА';

  @override
  String get activityDetailNetworkFee => 'СЕТЕВАЯ КОМИССИЯ';

  @override
  String get activityDetailTxHash => 'ХЕШ ТРАНЗАКЦИИ';

  @override
  String get activityDetailViewExplorer => 'Посмотреть в обозревателе ↗';

  @override
  String get activityDetailMultisigAddress => 'АДРЕС МУЛЬТИПОДПИСИ';

  @override
  String get activityDetailMultisigThreshold => 'ПОРОГ';

  @override
  String activityDetailMultisigThresholdValue(int threshold, int total) {
    return '$threshold из $total';
  }

  @override
  String get activityDetailMultisigSignerCount => 'ПОДПИСАНТЫ';

  @override
  String get activityDetailMultisigCreator => 'СОЗДАТЕЛЬ';

  @override
  String get activityDetailMultisigCreationFee => 'КОМИССИЯ PALLET';

  @override
  String get activityDetailMultisigDeposit => 'ЗАРЕЗЕРВИРОВАННЫЙ ДЕПОЗИТ';

  @override
  String get activityDetailMultisigFeePaidByCreator => 'Оплачено создателем';

  @override
  String get receiveTitle => 'Получить';

  @override
  String get receiveTabQrCode => 'QR-код';

  @override
  String get receiveTabAddress => 'Адрес';

  @override
  String get receiveCopy => 'Копировать';

  @override
  String receiveErrorLoadingAccount(String error) {
    return 'Ошибка загрузки данных аккаунта: $error';
  }

  @override
  String receiveClipboardContent(String accountId, String checksum) {
    return 'ID аккаунта:\n$accountId\n\nКонтрольная фраза:\n$checksum';
  }

  @override
  String get receiveCopiedMessage => 'Детали аккаунта скопированы в буфер обмена';

  @override
  String get posAmountTitle => 'Новый платёж';

  @override
  String posAmountCharge(String amount) {
    return 'Получить $amount';
  }

  @override
  String get posAmountEnterAmount => 'Введите сумму';

  @override
  String get posQrTitleScanToPay => 'Сканируйте для оплаты';

  @override
  String get posQrTitlePaymentReceived => 'Платёж получен';

  @override
  String posQrError(String error) {
    return 'Ошибка: $error';
  }

  @override
  String get posQrNoActiveAccount => 'Нет активного аккаунта';

  @override
  String get posQrInvalidAmount => 'Некорректная сумма. Нажмите для повтора.';

  @override
  String get posQrConnectionLost => 'Соединение потеряно. Нажмите для повтора.';

  @override
  String get posQrTimedOut => 'Время ожидания истекло. Нажмите для повтора.';

  @override
  String get posQrNewCharge => 'Новый платёж';

  @override
  String get posQrDone => 'Готово';

  @override
  String posQrAmountReceived(String amount) {
    return '$amount получено';
  }

  @override
  String get posQrFrom => 'От:';

  @override
  String get posQrWaitingForPayment => 'Ожидание платежа';

  @override
  String get posQrNetworkError => 'Ошибка сети';

  @override
  String get posQrTryAgain => 'Повторить';

  @override
  String posQrPaidAt(String time) {
    return 'В $time';
  }

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsWalletTitle => 'Кошелёк';

  @override
  String get settingsWalletSubtitle => 'Фраза восстановления, сброс кошелька';

  @override
  String get settingsPreferencesTitle => 'Предпочтения';

  @override
  String get settingsPreferencesSubtitle => 'Язык, валюта, режим POS, уведомления';

  @override
  String get settingsMiningRewards => 'Награды за майнинг';

  @override
  String settingsMiningRewardsSubtitle(int count) {
    return 'Намайнено блоков: $count';
  }

  @override
  String get settingsMiningRewardsError => 'Ошибка получения наград за майнинг';

  @override
  String get settingsAccountTypeTitle => 'Тип аккаунта';

  @override
  String get settingsAccountTypeSubtitle => 'Расширенные функции аккаунта';

  @override
  String get settingsHelpTitle => 'Помощь и поддержка';

  @override
  String get settingsHelpSubtitle => 'FAQ, связаться с командой';

  @override
  String get settingsAboutTitle => 'О Quantus';

  @override
  String settingsAboutHubSubtitle(String version, String build) {
    return 'Версия $version ($build)';
  }

  @override
  String get settingsWalletRecoveryPhrase => 'Фраза восстановления';

  @override
  String get settingsWalletRecoveryPhraseSubtitle => 'Посмотреть резервный пароль из 24 слов';

  @override
  String get settingsWalletReset => 'Сбросить кошелёк';

  @override
  String get settingsWalletResetSubtitle => 'Удаляет все данные с этого устройства';

  @override
  String get settingsWalletNoWalletsFound => 'Кошельки не найдены';

  @override
  String get settingsWalletFailedToLoad => 'Не удалось загрузить кошельки';

  @override
  String get settingsSelectWalletTitle => 'Выбрать кошелёк';

  @override
  String get settingsSelectWalletNoWallets => 'Кошельки не найдены';

  @override
  String settingsSelectWalletItem(int number) {
    return 'Кошелёк $number';
  }

  @override
  String get settingsRecoveryConfirmAuthReason => 'Пройдите аутентификацию, чтобы увидеть фразу восстановления';

  @override
  String get settingsRecoveryConfirmAuthRequired => 'Для просмотра фразы восстановления требуется аутентификация';

  @override
  String get settingsRecoveryPhraseTitle => 'Фраза восстановления';

  @override
  String get settingsRecoveryPhraseDone => 'Готово';

  @override
  String get settingsResetTitle => 'Сбросить кошелёк';

  @override
  String get settingsResetAuthReason => 'Пройдите аутентификацию, чтобы сбросить кошелёк';

  @override
  String settingsResetFailed(String error) {
    return 'Не удалось сбросить кошелёк: $error';
  }

  @override
  String get settingsResetAuthRequired => 'Для сброса кошелька требуется аутентификация';

  @override
  String get settingsResetCautionHeadline => 'Это сотрёт\nваш кошелёк';

  @override
  String get settingsResetCautionBullet1 => 'Все данные кошелька будут безвозвратно удалены с этого устройства';

  @override
  String get settingsResetCautionBullet2 =>
      'Ваши средства остаются в блокчейне, но только фраза восстановления может восстановить доступ';

  @override
  String get settingsResetCautionBullet3 => 'Без неё ваши средства будут потеряны навсегда';

  @override
  String get settingsResetCautionCheckbox => 'Я сохранил резервную копию фразы восстановления';

  @override
  String get settingsPreferencesCurrency => 'Валюта';

  @override
  String get settingsPreferencesCurrencySubtitle => 'Предпочтение отображения фиата';

  @override
  String get settingsPreferencesLanguage => 'Язык';

  @override
  String get settingsPreferencesLanguageSubtitle => 'Язык интерфейса приложения';

  @override
  String get settingsPreferencesPosMode => 'Режим POS';

  @override
  String get settingsPreferencesPosModeSubtitle => 'Функции точки продаж';

  @override
  String get settingsPreferencesNotifications => 'Уведомления';

  @override
  String get settingsPreferencesNotificationsSubtitle => 'Оповещения о транзакциях и кошельке';

  @override
  String get settingsCurrencyTitle => 'Валюта';

  @override
  String get settingsCurrencySearchHint => 'Поиск';

  @override
  String get settingsCurrencyNoMatch => 'Нет валют, соответствующих вашему запросу';

  @override
  String settingsCurrencyError(String error) {
    return 'Ошибка выбора валюты: $error';
  }

  @override
  String get settingsLanguageTitle => 'Язык';

  @override
  String get settingsLanguageSearchHint => 'Поиск';

  @override
  String get settingsLanguageNoMatch => 'Нет языков, соответствующих вашему запросу';

  @override
  String settingsLanguageError(String error) {
    return 'Ошибка выбора языка: $error';
  }

  @override
  String get settingsMiningTitle => 'Награды за майнинг';

  @override
  String get settingsMiningRedeem => 'Получить';

  @override
  String get settingsMiningStatusMining => 'Майнинг';

  @override
  String get settingsMiningStatusPending => 'В ожидании';

  @override
  String get settingsMiningBlocksMined => 'НАМАЙНЕНО БЛОКОВ';

  @override
  String get settingsMiningBlocksAcrossTestnets => 'блоков во всех тестовых сетях';

  @override
  String get settingsMiningStatTestnetBlocks => 'БЛОКИ ТЕСТОВОЙ СЕТИ';

  @override
  String get settingsMiningStatTestnetRewards => 'НАГРАДЫ ТЕСТОВОЙ СЕТИ';

  @override
  String get settingsMiningStatRedeemed => 'ПОЛУЧЕНО';

  @override
  String get settingsMiningStatRedeemable => 'ДОСТУПНО К ПОЛУЧЕНИЮ';

  @override
  String get settingsMiningQuanEarned => 'ЗАРАБОТАНО QUAN';

  @override
  String get settingsMiningViewTelemetry => 'Посмотреть телеметрию ↗';

  @override
  String get settingsMiningNoDataTitle => 'Пока нет данных о майнинге';

  @override
  String get settingsMiningNoDataBody => 'Настройте майнинг-узел Quantus, чтобы начать зарабатывать награды.';

  @override
  String get settingsMiningSetupGuide => 'Руководство по настройке майнинга ↗';

  @override
  String get settingsMiningLoadError => 'Не удалось загрузить награды за майнинг';

  @override
  String get settingsMiningCheckConnection => 'Проверьте подключение';

  @override
  String get settingsMiningTestnetBlocks => 'блоков';

  @override
  String get settingsMiningDiracSince => 'ноя 2025';

  @override
  String get settingsMiningSchrodingerSince => 'окт 2025';

  @override
  String get settingsMiningResonanceSince => 'июл 2025';

  @override
  String get settingsTestnetTitle => 'Награды тестовой сети';

  @override
  String get settingsTestnetLoadError => 'Не удалось загрузить награды тестовой сети';

  @override
  String settingsTestnetTotalBlocks(int count) {
    return '$count блоков';
  }

  @override
  String get settingsTestnetTotalDescription => 'Всего блоков, намайненных во всех тестовых сетях';

  @override
  String get settingsTestnetBreakdown => 'Разбивка';

  @override
  String settingsTestnetRowBlocks(int count) {
    return '$count блоков';
  }

  @override
  String get settingsHelpScreenTitle => 'Помощь и поддержка';

  @override
  String get settingsHelpEmail => 'Поддержка по эл. почте';

  @override
  String get settingsHelpTelegram => 'Telegram';

  @override
  String get settingsAboutScreenTitle => 'О приложении';

  @override
  String get settingsAboutIntro =>
      'Quantus — это блокчейн Layer 1, защищённый ML-DSA Dilithium-5, золотым стандартом квантово-устойчивого шифрования. Создан для будущего, где классической криптографии уже недостаточно. Постквантовая криптография для всех.';

  @override
  String get settingsAboutTerms => 'Условия использования';

  @override
  String get settingsAboutTermsSubtitle => 'quantus.com/terms/';

  @override
  String get settingsAboutPrivacy => 'Политика конфиденциальности';

  @override
  String get settingsAboutPrivacySubtitle => 'quantus.com/privacy-policy/';

  @override
  String get settingsAboutWebsite => 'Посетить сайт';

  @override
  String get settingsAboutWebsiteSubtitle => 'quantus.com';

  @override
  String settingsAboutVersion(String version, String build) {
    return 'Версия $version ($build)';
  }

  @override
  String get settingsAccountTypeScreenTitle => 'Тип аккаунта';

  @override
  String get settingsAccountTypeIntro =>
      'Расширенные функции аккаунта скоро появятся. Они дадут вам больше контроля над тем, как транзакции авторизуются и защищаются.';

  @override
  String get settingsAccountTypeReversibleTitle => 'Обратимые транзакции';

  @override
  String get settingsAccountTypeReversibleSubtitle => 'Отменяйте отправки в течение определённого времени';

  @override
  String get settingsAccountTypeHighSecurityTitle => 'Аккаунт повышенной безопасности';

  @override
  String get settingsAccountTypeHighSecuritySubtitle => 'Требуется одобрение хранителя';

  @override
  String get settingsAccountTypeMultiSigTitle => 'Мультиподпись';

  @override
  String get settingsAccountTypeMultiSigSubtitle => 'Требуется несколько одобрений';

  @override
  String get settingsAccountTypeHardwareTitle => 'Аппаратный кошелёк';

  @override
  String get settingsAccountTypeHardwareSubtitle => 'Подключите аппаратное устройство';

  @override
  String get settingsAccountTypeComingSoon => 'Скоро';

  @override
  String get swapTitle => 'Обмен';

  @override
  String get swapFrom => 'Из';

  @override
  String get swapTo => 'В';

  @override
  String get swapRefundAddress => 'Адрес возврата';

  @override
  String swapRefundAddressHint(String network) {
    return 'Адрес $network';
  }

  @override
  String get swapSlippageTolerance => 'Допустимое проскальзывание';

  @override
  String get swapRate => 'Курс';

  @override
  String get swapGetQuote => 'Получить котировку';

  @override
  String swapRateLabel(String amount, String symbol) {
    return '1 QUAN = $amount $symbol';
  }

  @override
  String swapRateZero(String symbol) {
    return '1 QUAN = 0 $symbol';
  }

  @override
  String get swapTokenPickerTitle => 'Выбрать токен';

  @override
  String get swapTokenPickerLoadError => 'Не удалось загрузить токены';

  @override
  String get swapReviewTitle => 'Проверить котировку';

  @override
  String get swapReviewTotalFees => 'Всего комиссий';

  @override
  String get swapReviewTotalAmount => 'Общая сумма';

  @override
  String swapReviewSlippageWarning(String amount, String percent) {
    return 'Вы можете получить до \$$amount меньше из-за установленного вами проскальзывания $percent%';
  }

  @override
  String get swapReviewConfirm => 'Подтвердить';

  @override
  String get swapDepositAmount => 'Сумма депозита';

  @override
  String get swapDepositAmountCopied => 'Сумма депозита скопирована в буфер обмена';

  @override
  String get swapDepositDemoWarning => 'Только для демонстрации — не отправляйте средства!';

  @override
  String get swapDepositShareQr => 'Поделиться QR';

  @override
  String swapDepositShareContent(String network, String token, String address) {
    return 'Сеть: $network\nТокен: $token\nАдрес: $address';
  }

  @override
  String swapDepositNotice(String symbol, String network) {
    return 'Используйте кошелёк $symbol или $network для внесения средств. Внесение других активов может привести к потере средств.';
  }

  @override
  String get swapDepositProcessingTitle => 'Обработка обмена';

  @override
  String get swapDepositProcessingBody => 'Это может занять несколько минут...';

  @override
  String get swapDepositCompleteTitle => 'Обмен завершён';

  @override
  String swapDepositCompleteBody(String amount) {
    return 'Ваш обмен на $amount QUAN завершён.';
  }

  @override
  String get swapDepositTestnetBanner => 'ТОЛЬКО ДЕМО — МЫ ВСЁ ЕЩЁ В ТЕСТОВОЙ СЕТИ';

  @override
  String get swapDepositSentFunds => 'Я отправил средства';

  @override
  String get swapDepositDone => 'Готово';

  @override
  String get swapRefundPickerTitle => 'Адреса возврата';

  @override
  String get swapRefundPickerEmpty => 'Нет недавних адресов возврата';

  @override
  String get componentQrScannerTitle => 'Сканировать QR-код';

  @override
  String get componentQrScannerNoCode => 'QR-код не найден на изображении';

  @override
  String get componentShare => 'Поделиться';

  @override
  String get componentAddressLabel => 'АДРЕС';

  @override
  String get componentCheckphraseLabel => 'КОНТРОЛЬНАЯ ФРАЗА';

  @override
  String get componentCheckphraseCopied => 'Контрольная фраза скопирована';

  @override
  String get componentNameFieldHint => 'Введите имя для вашего аккаунта';

  @override
  String get commonLoading => 'Загрузка...';

  @override
  String commonAmountBalance(String balance, String symbol) {
    return '$balance $symbol';
  }

  @override
  String get commonContinue => 'Продолжить';

  @override
  String get redeemToLabel => 'Получить на';

  @override
  String redeemAddressHint(String symbol) {
    return 'Вставьте адрес $symbol';
  }

  @override
  String redeemAmountCta(String amount) {
    return 'Получить $amount';
  }

  @override
  String get redeemConfirmTitle => 'Подтвердить получение';

  @override
  String get redeemConfirmAmount => 'Сумма';

  @override
  String get redeemConfirmTo => 'Кому';

  @override
  String get redeemConfirmFee => 'Комиссия';

  @override
  String get redeemFeeValue => 'Комиссия 0,1% от объёма';

  @override
  String get redeemProgressTitle => 'Получение...';

  @override
  String get redeemCompleteTitle => 'Получение завершено';

  @override
  String get redeemFailedTitle => 'Получение не удалось';

  @override
  String get redeemingLabel => 'ПОЛУЧЕНИЕ';

  @override
  String get redeemStepCircuits => 'Подготовка схем';

  @override
  String get redeemStepTransfers => 'Получение переводов';

  @override
  String get redeemStepNullifiers => 'Вычисление нуллификаторов';

  @override
  String get redeemStepCheckNullifiers => 'Проверка нуллификаторов';

  @override
  String get redeemStepProofs => 'Генерация ZK-доказательств';

  @override
  String get redeemStepAggregate => 'Агрегация и отправка';

  @override
  String redeemFetchedCount(int count) {
    return 'Получено: $count';
  }

  @override
  String get redeemCancel => 'Отмена';

  @override
  String get redeemRetry => 'Повторить';

  @override
  String get redeemClose => 'Закрыть';

  @override
  String get redeemDone => 'Готово';

  @override
  String redeemSuccessBanner(String amount, int count) {
    return '$amount получено за $count партий(и)';
  }
}
