// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get walletInitErrorTitle => '钱包错误';

  @override
  String get walletInitErrorMessage => '无法找到助记词，请恢复您的钱包。';

  @override
  String get walletInitErrorButtonLabel => '确定';

  @override
  String get authUseDeviceBiometricsToUnlock => '使用设备生物识别解锁';

  @override
  String get authAuthenticating => '正在验证…';

  @override
  String get authUnlockWallet => '解锁钱包';

  @override
  String get authAuthorizationRequired => '需要\n授权';

  @override
  String get welcomeTagline => '抗量子加密货币';

  @override
  String get welcomeCreateNewWallet => '创建新钱包';

  @override
  String get welcomeImportWallet => '导入钱包';

  @override
  String get createWalletCautionHeadline => '请妥善保管您的助记词';

  @override
  String get createWalletCautionBullet1 => '如果您丢失此设备，助记词是恢复的唯一途径';

  @override
  String get createWalletCautionBullet2 => '任何获得它的人都将永久完全控制您的资金';

  @override
  String get createWalletCautionBullet3 => '请将其写下并保存在安全的地方，切勿以数字方式保存';

  @override
  String createWalletRecoveryPhraseSaveError(String error) {
    return '保存钱包出错：$error';
  }

  @override
  String get recoveryPhraseBodyInstructions => '请按顺序将这些单词写下，并保存在只有您能访问的地方。请勿截屏或复制到笔记应用。';

  @override
  String get recoveryPhraseBodyCopy => '复制';

  @override
  String get recoveryPhraseBodyTapToReveal => '点击显示';

  @override
  String get recoveryPhraseBodyTapToHide => '点击隐藏';

  @override
  String get recoveryPhraseBodyCopiedMessage => '助记词已复制到剪贴板';

  @override
  String get accountReadyAccountCreated => '账户已创建';

  @override
  String get accountReadyWalletCreated => '钱包已创建';

  @override
  String get accountReadyWalletImported => '钱包已导入';

  @override
  String get accountReadyDone => '完成';

  @override
  String get importWalletAppBarTitle => '导入钱包';

  @override
  String get importWalletDescription => '使用您的 12 或 24 个助记词恢复现有钱包';

  @override
  String get importWalletHint => '输入或粘贴您的助记词，单词之间用空格分隔。';

  @override
  String get importWalletButton => '导入';

  @override
  String get importWalletValidationError => '助记词必须为 12 或 24 个单词';

  @override
  String homeError(String error) {
    return '错误：$error';
  }

  @override
  String get homeNoActiveAccount => '没有活动账户';

  @override
  String get homeCharge => '收款';

  @override
  String get homeGetTestnetTokens => '获取测试网代币 ↗';

  @override
  String get homeErrorLoadingBalance => '加载余额出错';

  @override
  String get homeBackupReminder => '请备份您的助记词';

  @override
  String get homeReceive => '接收';

  @override
  String get homeSend => '发送';

  @override
  String get homeSwap => '兑换';

  @override
  String get homeActivityTitle => '活动';

  @override
  String get homeActivityViewAll => '查看全部';

  @override
  String get homeActivityErrorLoading => '加载交易出错';

  @override
  String get homeActivityRetry => '重试';

  @override
  String get homeActivityEmptyTitle => '暂无交易';

  @override
  String get homeActivityEmptyMessage => '当您发送或接收 QUAN 后，您的活动将显示在此处。';

  @override
  String get accountsSheetTitle => '账户';

  @override
  String get accountsSheetFailedLoadAccounts => '加载账户失败。';

  @override
  String get accountsSheetFailedLoadActiveAccount => '加载活动账户失败。';

  @override
  String get accountsSheetNoAccountsFound => '未找到账户。';

  @override
  String get accountsSheetAddAccount => '添加账户';

  @override
  String get accountsSheetBalanceUnavailable => '余额不可用';

  @override
  String accountsSheetBalance(String balance, String symbol) {
    return '$balance $symbol';
  }

  @override
  String get addAccountMenuTitle => '添加账户';

  @override
  String get addAccountMenuCreateTitle => '创建新账户';

  @override
  String get addAccountMenuCreateSubtitle => '生成一个新的钱包地址';

  @override
  String get addAccountMenuImportTitle => '导入钱包';

  @override
  String get addAccountMenuImportSubtitle => '使用助记词导入';

  @override
  String get addAccountMenuMultisigTitle => '创建多签';

  @override
  String get addAccountMenuMultisigSubtitle => '设置由多个签名者共享的地址';

  @override
  String get addAccountMenuDiscoverMultisigTitle => '发现多签';

  @override
  String get addAccountMenuDiscoverMultisigSubtitle => '查找您的账户作为签名者的多签';

  @override
  String get multisigTag => '多签';

  @override
  String get multisigProposeTitle => '提议';

  @override
  String get multisigAddTitle => '创建多签';

  @override
  String get multisigDiscoverTitle => '发现多签';

  @override
  String get multisigCreateSubtitle => '为此多签起一个您能识别的名称，您可以随时更改。';

  @override
  String get multisigCreateButton => '创建';

  @override
  String get multisigCreateCreatingButton => '创建中';

  @override
  String multisigCreateDefaultName(int number) {
    return '多签 $number';
  }

  @override
  String get multisigCreateErrorCouldNotCreate => '无法创建多签。';

  @override
  String get multisigCreateReadyToast => '多签已添加到您的账户。';

  @override
  String get multisigCreateAlreadyExists => '此地址的多签已存在于链上。';

  @override
  String get multisigCreateInsufficientBalance => '余额不足以支付多签创建费用。';

  @override
  String get multisigCreateTimeoutToast => '多签创建耗时超出预期，请检查链或重试。';

  @override
  String get multisigCreateAuthReason => '验证以创建此多签';

  @override
  String get multisigCreateSignersLabel => '签名者';

  @override
  String get multisigCreateSignersSubtitle => '除您自己外，至少添加一位其他签名者。';

  @override
  String get multisigCreateAddSignerHint => '签名者 SS58 地址';

  @override
  String get multisigCreateAddSignerButton => '添加签名者';

  @override
  String get multisigCreateDuplicateSigner => '此签名者已在列表中。';

  @override
  String get multisigCreateInvalidSigner => '请输入有效的 SS58 地址。';

  @override
  String get multisigCreateThresholdLabel => '阈值';

  @override
  String multisigCreateThresholdValue(int count, int total) {
    return '$total 中的 $count';
  }

  @override
  String get multisigCreatePredictedAddressLabel => '多签地址';

  @override
  String get multisigCreatePredictedAddressPlaceholder => '添加签名者以预览地址';

  @override
  String get multisigDone => '完成';

  @override
  String get multisigAddDiscoveredTitle => '为您发现';

  @override
  String get multisigAddDiscoveredSubtitle => '链上您的某个账户作为签名者的多签';

  @override
  String get multisigAddButton => '添加';

  @override
  String get multisigAddedButton => '已添加';

  @override
  String get multisigAddNoneFound => '未找到多签。';

  @override
  String multisigAddDiscoverFailed(String error) {
    return '无法发现多签：$error';
  }

  @override
  String multisigAddFailed(String error) {
    return '无法添加多签：$error';
  }

  @override
  String get multisigOpenProposals => '进行中的提议';

  @override
  String get multisigPastProposals => '历史提议';

  @override
  String get multisigNoOpenProposals => '没有进行中的提议。';

  @override
  String get multisigNoPastProposals => '没有历史提议。';

  @override
  String multisigLoadFailed(String error) {
    return '加载失败：$error';
  }

  @override
  String multisigProposalToAddress(String address) {
    return '至 $address';
  }

  @override
  String get multisigStatusApproved => '已批准';

  @override
  String get multisigStatusProposed => '已提议';

  @override
  String get multisigStatusExpired => '已过期';

  @override
  String get multisigStatusCancelled => '已取消';

  @override
  String get multisigProposeSelectRecipientTo => '转账至';

  @override
  String multisigProposeSearchHint(String symbol) {
    return '输入 $symbol 地址';
  }

  @override
  String get multisigProposeAmountToLabel => '转账至';

  @override
  String get multisigProposeDepositLabel => '押金：';

  @override
  String get multisigProposeCreationFeeLabel => '提议费用：';

  @override
  String get multisigProposeDepositRefundableNote => '可退还';

  @override
  String get multisigProposeMemberTotalLabel => '从您账户支出的总额';

  @override
  String get multisigProposeFeeLabel => '提议费用：';

  @override
  String get multisigProposeFeeFetchFailed => '无法估算费用';

  @override
  String get multisigProposeReviewButton => '审核转账';

  @override
  String get multisigProposeReviewProposing => '提议的转账';

  @override
  String multisigProposeReviewFromName(String name) {
    return '来自 $name';
  }

  @override
  String get multisigProposeThresholdLabel => '阈值';

  @override
  String get multisigProposeExpiresLabel => '过期时间';

  @override
  String multisigExpiresBlockOnly(int block) {
    return '区块 $block';
  }

  @override
  String get multisigProposeFeeRowLabel => '提议费用';

  @override
  String get multisigProposeCreateButton => '提交提议';

  @override
  String get multisigProposeAuthReason => '验证以提议交易';

  @override
  String get multisigProposeAuthRequired => '需要验证';

  @override
  String get multisigProposeSubmitFailed => '创建提议失败';

  @override
  String get multisigProposeTimeoutToast => '提议确认耗时超出预期，请检查链或重试。';

  @override
  String get multisigProposeDoneHeadline => '转账提议已提交';

  @override
  String get multisigProposeDoneSubline => '共同签名者必须批准后转账才能执行。';

  @override
  String multisigProposeDoneToChecksum(String checksum) {
    return '至 $checksum';
  }

  @override
  String multisigSignaturesCount(int current, int threshold) {
    return '签名：$current/$threshold';
  }

  @override
  String get multisigProposalTitle => '提议';

  @override
  String multisigProposalLoadFailed(String error) {
    return '失败：$error';
  }

  @override
  String get multisigProposalNotFound => '未找到提议。';

  @override
  String get multisigProposalSignButton => '签名';

  @override
  String get multisigProposalSigningSoonNote => '签名功能即将推出。';

  @override
  String get multisigProposalApprovingLabel => '批准中…';

  @override
  String get multisigProposalApprovingNote => '您的批准正在链上确认。';

  @override
  String get multisigApproveUnavailableNote => '此提议无法再被批准。';

  @override
  String get activityTxApproving => '批准中…';

  @override
  String get activityTxCancelling => '取消中…';

  @override
  String get multisigApprovalTimeoutToast => '批准确认耗时超出预期，请检查链或重试。';

  @override
  String get multisigProposalAlreadySignedNote => '您已批准此提议。';

  @override
  String get multisigProposalAlreadyExecutedNote => '此提议已执行。';

  @override
  String get multisigProposalAlreadyCancelledNote => '此提议已取消。';

  @override
  String get multisigProposalProposerLabel => '提议者';

  @override
  String get multisigProposalStatusLabel => '状态';

  @override
  String get multisigProposalDepositLabel => '押金';

  @override
  String get multisigStatusActive => '进行中';

  @override
  String get multisigStatusExecuted => '已执行';

  @override
  String get multisigStatusRemoved => '已移除';

  @override
  String get multisigStatusUnknown => '未知';

  @override
  String get activityTxProposal => '提议';

  @override
  String get activityTxProposing => '提议中';

  @override
  String get activityTxProposalCreated => '提议已创建';

  @override
  String get activityTxProposalApproved => '提议已批准';

  @override
  String get activityTxProposalExecuted => '提议已执行';

  @override
  String get activityTxProposalCancelled => '提议已取消';

  @override
  String get multisigApproveButton => '批准';

  @override
  String get multisigAlreadyApproved => '已批准';

  @override
  String get multisigCancelProposalButton => '取消提议';

  @override
  String get multisigProposalExpiresLabel => '过期时间';

  @override
  String get multisigProposalAtLabel => '时间';

  @override
  String get multisigProposalThresholdLabel => '阈值';

  @override
  String get multisigProposalApprovalsLabel => '批准数';

  @override
  String get multisigProposalFeeRowLabel => '提议费用';

  @override
  String get multisigProposalSignersLabel => '签名者';

  @override
  String get multisigYouLabel => '您';

  @override
  String get multisigSignerCreatorLabel => '创建者';

  @override
  String get multisigAccountMenuDetails => '多签详情';

  @override
  String get multisigAccountMenuDetailsTitle => '多签详情';

  @override
  String get multisigAccountMenuDetailsThresholdHint => '执行提议需要的签名者批准数量。';

  @override
  String multisigThresholdOf(int count, int total) {
    return '$total 中的 $count';
  }

  @override
  String multisigApprovalsOf(int count, int threshold) {
    return '$threshold 中的 $count';
  }

  @override
  String get multisigApproveConfirmTitle => '您确定吗？';

  @override
  String get multisigApproveConfirmBody => '您即将批准一笔转账';

  @override
  String multisigApproveConfirmTo(String address) {
    return '至 $address';
  }

  @override
  String get multisigApproveConfirmYes => '是，批准';

  @override
  String get multisigApproveConfirmNo => '否，返回';

  @override
  String get multisigApproveAuthReason => '验证以批准';

  @override
  String get multisigAuthRequired => '需要验证';

  @override
  String get multisigApproveFailed => '批准失败';

  @override
  String get multisigExecuteButton => '执行';

  @override
  String get multisigExecuteConfirmTitle => '您确定吗？';

  @override
  String get multisigExecuteConfirmBody => '您即将执行一笔转账';

  @override
  String get multisigExecuteConfirmYes => '是，执行';

  @override
  String get multisigExecuteAuthReason => '验证以执行';

  @override
  String get multisigExecuteFailed => '执行失败';

  @override
  String get multisigExecuteUnavailableNote => '此提议无法再被执行。';

  @override
  String get multisigProposalExecutingLabel => '执行中…';

  @override
  String get multisigProposalExecutingNote => '您的执行正在链上确认。';

  @override
  String get activityTxExecuting => '执行中…';

  @override
  String get multisigExecutionTimeoutToast => '执行确认耗时超出预期，请检查链或重试。';

  @override
  String get multisigExecutedByOtherToast => '提议已由另一位签名者执行。';

  @override
  String get multisigFeeEstimateUnavailable => '网络费用估算不可用。';

  @override
  String get multisigCancelConfirmTitle => '取消提议？';

  @override
  String get multisigCancelConfirmBody => '取消将退还您的提议押金，其他签名者将无法再批准。';

  @override
  String get multisigCancelConfirmYes => '是，取消提议';

  @override
  String get multisigCancelConfirmKeep => '保留提议';

  @override
  String get multisigCancelAuthReason => '验证以取消';

  @override
  String get multisigCancelFailed => '取消失败';

  @override
  String get multisigProposalCancellingLabel => '取消中…';

  @override
  String get multisigProposalCancellingNote => '您的取消正在链上确认。';

  @override
  String get multisigCancelTimeoutToast => '取消确认耗时超出预期，请检查链或重试。';

  @override
  String get multisigApproveTitle => '批准';

  @override
  String get multisigApproveDoneExecuted => '提议已执行';

  @override
  String get multisigApproveDoneRecorded => '批准已记录';

  @override
  String get multisigApproveDoneExecutedSubline => '已达到阈值——转账已发出。';

  @override
  String get multisigApproveDoneRecordedSubline => '等待更多共同签名者。';

  @override
  String get createAccountAppBarTitle => '账户名称';

  @override
  String get createAccountSubtitle => '为此账户起一个您能识别的名称，您可以随时更改。';

  @override
  String get createAccountButton => '创建';

  @override
  String get createAccountErrorCouldNotAdd => '无法添加账户。';

  @override
  String createAccountDefaultName(int number) {
    return '账户 $number';
  }

  @override
  String get editAccountAppBarTitle => '账户名称';

  @override
  String get editAccountDone => '完成';

  @override
  String get editAccountNameEmpty => '账户名称不能为空';

  @override
  String get editAccountRenameFailed => '重命名账户失败。';

  @override
  String get accountMenuTitle => '账户';

  @override
  String get accountMenuAccountName => '账户名称';

  @override
  String get accountMenuAddressDetails => '地址详情';

  @override
  String get accountMenuShowRecoveryPhrase => '显示助记词';

  @override
  String get accountMenuNotFound => '未找到账户';

  @override
  String get accountDetailsTitle => '地址详情';

  @override
  String get addHardwareAccountAddWallet => '添加硬件钱包';

  @override
  String get addHardwareAccountAddAccount => '添加硬件账户';

  @override
  String get addHardwareAccountNameLabel => '名称';

  @override
  String get addHardwareAccountNameHintWallet => '硬件钱包';

  @override
  String get addHardwareAccountNameHintAccount => '账户';

  @override
  String get addHardwareAccountAddressLabel => '地址';

  @override
  String get addHardwareAccountAddressHint => 'SS58 地址';

  @override
  String get addHardwareAccountDebugFill => '调试填充';

  @override
  String get addHardwareAccountNameRequired => '名称为必填项';

  @override
  String get addHardwareAccountInvalidAddress => '地址无效';

  @override
  String get sendTitle => '发送';

  @override
  String get sendPayTitle => '支付';

  @override
  String get sendEnterAddress => '输入地址';

  @override
  String get sendSelectRecipientSendTo => '发送至';

  @override
  String sendSelectRecipientSearchHint(String symbol) {
    return '输入 $symbol 地址';
  }

  @override
  String get sendSelectRecipientScanTitle => '扫描二维码';

  @override
  String sendSelectRecipientScanSubtitle(String symbol) {
    return '点击扫描 $symbol 地址';
  }

  @override
  String get sendSelectRecipientRecents => '最近';

  @override
  String get sendSelectRecipientContinue => '继续';

  @override
  String get sendInputAmountSendTo => '发送至';

  @override
  String get sendInputAmountAvailableBalance => '可用余额：';

  @override
  String get sendInputAmountNetworkFee => '网络费用：';

  @override
  String get sendInputAmountMax => '最大';

  @override
  String get sendInputAmountInvalidAmount => '请输入有效的金额';

  @override
  String get sendInputAmountChecksumRequired => '需要收款人校验短语';

  @override
  String get sendReviewSending => '发送中';

  @override
  String get sendReviewTo => '至';

  @override
  String get sendReviewAmount => '金额';

  @override
  String get sendReviewNetworkFee => '网络费用';

  @override
  String get sendReviewYouPay => '您支付';

  @override
  String get sendReviewConfirm => '确认';

  @override
  String get sendReviewAuthReason => '验证以确认交易';

  @override
  String get sendReviewAuthRequired => '发送需要验证';

  @override
  String get sendReviewSubmitFailed => '提交交易失败';

  @override
  String sendTxSubmittedHeadlinePaid(String amount, String symbol) {
    return '已支付 $amount $symbol';
  }

  @override
  String sendTxSubmittedHeadlineSent(String amount, String symbol) {
    return '已发送 $amount $symbol';
  }

  @override
  String get sendTxSubmittedOnItsWay => '正在处理中';

  @override
  String get sendTxSubmittedToLabel => '至';

  @override
  String get sendTxSubmittedDone => '完成';

  @override
  String get sendLogicCantSelfTransfer => '无法转账给自己';

  @override
  String get sendLogicEnterAmount => '输入金额';

  @override
  String get sendLogicInvalidAmount => '金额无效';

  @override
  String get sendLogicBelowExistentialDeposit => '低于存在性押金';

  @override
  String get sendLogicInsufficientBalance => '余额不足';

  @override
  String get sendLogicReviewSend => '审核发送';

  @override
  String get activityTitle => '活动';

  @override
  String activityError(String error) {
    return '错误：$error';
  }

  @override
  String get activityNoAccount => '没有账户';

  @override
  String get activityEmpty => '暂无交易';

  @override
  String get activityFilterAll => '全部';

  @override
  String get activityFilterSend => '发送';

  @override
  String get activityFilterReceive => '接收';

  @override
  String get activityDateToday => '今天';

  @override
  String get activityDateYesterday => '昨天';

  @override
  String get activityTxSending => '发送中';

  @override
  String get activityTxReceiving => '接收中';

  @override
  String get activityTxPending => '待处理';

  @override
  String get activityTxSent => '已发送';

  @override
  String get activityTxReceived => '已接收';

  @override
  String get activityTxMultisigCreated => '多签已创建';

  @override
  String get activityTxMultisigCreating => '创建多签中';

  @override
  String get activityTxMultisigLabel => '多签';

  @override
  String get activityTxTo => '至';

  @override
  String get activityTxFrom => '来自';

  @override
  String get activityTxTimeNow => '刚刚';

  @override
  String activityTxTimeMinutesAgo(int minutes) {
    return '$minutes 分钟前';
  }

  @override
  String activityTxTimeHoursAgo(int hours) {
    return '$hours 小时前';
  }

  @override
  String activityTxTimeDaysAgo(int days) {
    return '$days 天前';
  }

  @override
  String activityTxTimeRemaining(String days, String hours, String minutes) {
    return '$days天:$hours时:$minutes分';
  }

  @override
  String get activityDetailTitleSending => '发送中';

  @override
  String get activityDetailTitleScheduled => '已计划';

  @override
  String get activityDetailTitleReceiving => '接收中';

  @override
  String get activityDetailTitleSent => '已发送';

  @override
  String get activityDetailTitleReceived => '已接收';

  @override
  String get activityDetailTitleMultisigCreated => '多签已创建';

  @override
  String get activityDetailTitleMultisigCreating => '创建多签中';

  @override
  String get activityDetailTitleProposalCreated => '提议已创建';

  @override
  String get activityDetailTitleProposalApproved => '提议已批准';

  @override
  String get activityDetailTitleProposalExecuted => '提议已执行';

  @override
  String get activityDetailTitleProposalCancelled => '提议已取消';

  @override
  String get activityDetailTitleCancelling => '取消提议中';

  @override
  String get activityDetailTitleExecuting => '执行提议中';

  @override
  String get activityDetailTitleProposing => '提议中';

  @override
  String get activityDetailProposalTransferAmount => '转账金额';

  @override
  String get activityDetailStatusInProcess => '处理中';

  @override
  String get activityDetailStatusScheduled => '已计划';

  @override
  String get activityDetailStatusCompleted => '已完成';

  @override
  String get activityDetailStatus => '状态';

  @override
  String get activityDetailTo => '至';

  @override
  String get activityDetailFrom => '来自';

  @override
  String get activityDetailDate => '日期';

  @override
  String get activityDetailNetworkFee => '网络费用';

  @override
  String get activityDetailTxHash => '交易哈希';

  @override
  String get activityDetailViewExplorer => '在区块浏览器中查看 ↗';

  @override
  String get activityDetailMultisigAddress => '多签地址';

  @override
  String get activityDetailMultisigThreshold => '阈值';

  @override
  String activityDetailMultisigThresholdValue(int threshold, int total) {
    return '$total 中的 $threshold';
  }

  @override
  String get activityDetailMultisigSignerCount => '签名者';

  @override
  String get activityDetailMultisigCreator => '创建者';

  @override
  String get activityDetailMultisigCreationFee => 'Pallet 费用';

  @override
  String get activityDetailMultisigDeposit => '预留押金';

  @override
  String get activityDetailMultisigFeePaidByCreator => '由创建者支付';

  @override
  String get receiveTitle => '接收';

  @override
  String get receiveTabQrCode => '二维码';

  @override
  String get receiveTabAddress => '地址';

  @override
  String get receiveCopy => '复制';

  @override
  String receiveErrorLoadingAccount(String error) {
    return '加载账户数据出错：$error';
  }

  @override
  String receiveClipboardContent(String accountId, String checksum) {
    return '账户 ID：\n$accountId\n\n校验短语：\n$checksum';
  }

  @override
  String get receiveCopiedMessage => '账户详情已复制到剪贴板';

  @override
  String get posAmountTitle => '新收款';

  @override
  String posAmountCharge(String amount) {
    return '收款 $amount';
  }

  @override
  String get posAmountEnterAmount => '输入金额';

  @override
  String get posQrTitleScanToPay => '扫码支付';

  @override
  String get posQrTitlePaymentReceived => '已收到付款';

  @override
  String posQrError(String error) {
    return '错误：$error';
  }

  @override
  String get posQrNoActiveAccount => '没有活动账户';

  @override
  String get posQrInvalidAmount => '金额无效，点击重试。';

  @override
  String get posQrConnectionLost => '连接丢失，点击重试。';

  @override
  String get posQrTimedOut => '已超时，点击重试。';

  @override
  String get posQrNewCharge => '新收款';

  @override
  String get posQrDone => '完成';

  @override
  String posQrAmountReceived(String amount) {
    return '已收到 $amount';
  }

  @override
  String get posQrFrom => '来自：';

  @override
  String get posQrWaitingForPayment => '等待付款';

  @override
  String get posQrNetworkError => '网络错误';

  @override
  String get posQrTryAgain => '重试';

  @override
  String posQrPaidAt(String time) {
    return '于 $time';
  }

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsWalletTitle => '钱包';

  @override
  String get settingsWalletSubtitle => '助记词，重置钱包';

  @override
  String get settingsPreferencesTitle => '偏好设置';

  @override
  String get settingsPreferencesSubtitle => '语言、货币、POS 模式、通知';

  @override
  String get settingsMiningRewards => '挖矿奖励';

  @override
  String settingsMiningRewardsSubtitle(int count) {
    return '已挖出 $count 个区块';
  }

  @override
  String get settingsMiningRewardsError => '获取挖矿奖励出错';

  @override
  String get settingsAccountTypeTitle => '账户类型';

  @override
  String get settingsAccountTypeSubtitle => '高级账户功能';

  @override
  String get settingsHelpTitle => '帮助与支持';

  @override
  String get settingsHelpSubtitle => '常见问题，联系团队';

  @override
  String get settingsAboutTitle => '关于 Quantus';

  @override
  String settingsAboutHubSubtitle(String version, String build) {
    return '版本 $version ($build)';
  }

  @override
  String get settingsWalletRecoveryPhrase => '助记词';

  @override
  String get settingsWalletRecoveryPhraseSubtitle => '查看您的 24 个单词备份密码';

  @override
  String get settingsWalletReset => '重置钱包';

  @override
  String get settingsWalletResetSubtitle => '从此设备删除所有数据';

  @override
  String get settingsWalletNoWalletsFound => '未找到钱包';

  @override
  String get settingsWalletFailedToLoad => '加载钱包失败';

  @override
  String get settingsSelectWalletTitle => '选择钱包';

  @override
  String get settingsSelectWalletNoWallets => '未找到钱包';

  @override
  String settingsSelectWalletItem(int number) {
    return '钱包 $number';
  }

  @override
  String get settingsRecoveryConfirmAuthReason => '验证以查看助记词';

  @override
  String get settingsRecoveryConfirmAuthRequired => '查看助记词需要验证';

  @override
  String get settingsRecoveryPhraseTitle => '助记词';

  @override
  String get settingsRecoveryPhraseDone => '完成';

  @override
  String get settingsResetTitle => '重置钱包';

  @override
  String get settingsResetAuthReason => '验证以重置钱包';

  @override
  String settingsResetFailed(String error) {
    return '重置钱包失败：$error';
  }

  @override
  String get settingsResetAuthRequired => '重置钱包需要验证';

  @override
  String get settingsResetCautionHeadline => '这将清除\n您的钱包';

  @override
  String get settingsResetCautionBullet1 => '所有钱包数据将从此设备永久删除';

  @override
  String get settingsResetCautionBullet2 => '您的资金仍在区块链上，但只有助记词才能恢复访问';

  @override
  String get settingsResetCautionBullet3 => '没有它，您的资金将永远丢失';

  @override
  String get settingsResetCautionCheckbox => '我已备份我的助记词';

  @override
  String get settingsPreferencesCurrency => '货币';

  @override
  String get settingsPreferencesCurrencySubtitle => '法币显示偏好';

  @override
  String get settingsPreferencesLanguage => '语言';

  @override
  String get settingsPreferencesLanguageSubtitle => '应用显示语言';

  @override
  String get settingsPreferencesPosMode => 'POS 模式';

  @override
  String get settingsPreferencesPosModeSubtitle => '销售点功能';

  @override
  String get settingsPreferencesNotifications => '通知';

  @override
  String get settingsPreferencesNotificationsSubtitle => '交易和钱包提醒';

  @override
  String get settingsCurrencyTitle => '货币';

  @override
  String get settingsCurrencySearchHint => '搜索';

  @override
  String get settingsCurrencyNoMatch => '没有匹配您搜索的货币';

  @override
  String settingsCurrencyError(String error) {
    return '选择货币出错：$error';
  }

  @override
  String get settingsLanguageTitle => '语言';

  @override
  String get settingsLanguageSearchHint => '搜索';

  @override
  String get settingsLanguageNoMatch => '没有匹配您搜索的语言';

  @override
  String settingsLanguageError(String error) {
    return '选择语言出错：$error';
  }

  @override
  String get settingsMiningTitle => '挖矿奖励';

  @override
  String get settingsMiningRedeem => '兑换';

  @override
  String get settingsMiningStatusMining => '挖矿中';

  @override
  String get settingsMiningStatusPending => '待处理';

  @override
  String get settingsMiningBlocksMined => '已挖区块';

  @override
  String get settingsMiningBlocksAcrossTestnets => '个区块（所有测试网）';

  @override
  String get settingsMiningStatTestnetBlocks => '测试网区块';

  @override
  String get settingsMiningStatTestnetRewards => '测试网奖励';

  @override
  String get settingsMiningStatRedeemed => '已兑换';

  @override
  String get settingsMiningStatRedeemable => '可兑换';

  @override
  String get settingsMiningQuanEarned => '已赚取 QUAN';

  @override
  String get settingsMiningViewTelemetry => '查看遥测数据 ↗';

  @override
  String get settingsMiningNoDataTitle => '暂无挖矿数据';

  @override
  String get settingsMiningNoDataBody => '设置一个 Quantus 挖矿节点以开始赚取奖励。';

  @override
  String get settingsMiningSetupGuide => '挖矿设置指南 ↗';

  @override
  String get settingsMiningLoadError => '加载挖矿奖励失败';

  @override
  String get settingsMiningCheckConnection => '请检查您的网络连接';

  @override
  String get settingsMiningTestnetBlocks => '区块';

  @override
  String get settingsMiningDiracSince => '2025 年 11 月';

  @override
  String get settingsMiningSchrodingerSince => '2025 年 10 月';

  @override
  String get settingsMiningResonanceSince => '2025 年 7 月';

  @override
  String get settingsTestnetTitle => '测试网奖励';

  @override
  String get settingsTestnetLoadError => '加载测试网奖励失败';

  @override
  String settingsTestnetTotalBlocks(int count) {
    return '$count 个区块';
  }

  @override
  String get settingsTestnetTotalDescription => '所有测试网挖出的区块总数';

  @override
  String get settingsTestnetBreakdown => '明细';

  @override
  String settingsTestnetRowBlocks(int count) {
    return '$count 个区块';
  }

  @override
  String get settingsHelpScreenTitle => '帮助与支持';

  @override
  String get settingsHelpEmail => '邮件支持';

  @override
  String get settingsHelpTelegram => 'Telegram';

  @override
  String get settingsAboutScreenTitle => '关于';

  @override
  String get settingsAboutIntro =>
      'Quantus 是一个由 ML-DSA Dilithium-5 保护的 Layer 1 区块链，这是抗量子加密的黄金标准。专为经典密码学不再足够的未来而构建。让人人都能享有后量子密码学。';

  @override
  String get settingsAboutTerms => '服务条款';

  @override
  String get settingsAboutTermsSubtitle => 'quantus.com/terms/';

  @override
  String get settingsAboutPrivacy => '隐私政策';

  @override
  String get settingsAboutPrivacySubtitle => 'quantus.com/privacy-policy/';

  @override
  String get settingsAboutWebsite => '访问网站';

  @override
  String get settingsAboutWebsiteSubtitle => 'quantus.com';

  @override
  String settingsAboutVersion(String version, String build) {
    return '版本 $version ($build)';
  }

  @override
  String get settingsAccountTypeScreenTitle => '账户类型';

  @override
  String get settingsAccountTypeIntro => '高级账户功能即将推出。它们将让您更好地控制交易的授权和保护方式。';

  @override
  String get settingsAccountTypeReversibleTitle => '可撤销交易';

  @override
  String get settingsAccountTypeReversibleSubtitle => '在时间窗口内撤销您的发送';

  @override
  String get settingsAccountTypeHighSecurityTitle => '高安全性账户';

  @override
  String get settingsAccountTypeHighSecuritySubtitle => '需要监护人批准';

  @override
  String get settingsAccountTypeMultiSigTitle => '多重签名';

  @override
  String get settingsAccountTypeMultiSigSubtitle => '需要多方批准';

  @override
  String get settingsAccountTypeHardwareTitle => '硬件钱包';

  @override
  String get settingsAccountTypeHardwareSubtitle => '配对硬件设备';

  @override
  String get settingsAccountTypeComingSoon => '即将推出';

  @override
  String get swapTitle => '兑换';

  @override
  String get swapFrom => '从';

  @override
  String get swapTo => '到';

  @override
  String get swapRefundAddress => '退款地址';

  @override
  String swapRefundAddressHint(String network) {
    return '$network 地址';
  }

  @override
  String get swapSlippageTolerance => '滑点容差';

  @override
  String get swapRate => '汇率';

  @override
  String get swapGetQuote => '获取报价';

  @override
  String swapRateLabel(String amount, String symbol) {
    return '1 QUAN = $amount $symbol';
  }

  @override
  String swapRateZero(String symbol) {
    return '1 QUAN = 0 $symbol';
  }

  @override
  String get swapTokenPickerTitle => '选择代币';

  @override
  String get swapTokenPickerLoadError => '加载代币失败';

  @override
  String get swapReviewTitle => '审核报价';

  @override
  String get swapReviewTotalFees => '总费用';

  @override
  String get swapReviewTotalAmount => '总金额';

  @override
  String swapReviewSlippageWarning(String amount, String percent) {
    return '根据您设置的 $percent% 滑点，您可能最多少收到 \$$amount';
  }

  @override
  String get swapReviewConfirm => '确认';

  @override
  String get swapDepositAmount => '存入金额';

  @override
  String get swapDepositAmountCopied => '存入金额已复制到剪贴板';

  @override
  String get swapDepositDemoWarning => '仅供演示——请勿发送资金！';

  @override
  String get swapDepositShareQr => '分享二维码';

  @override
  String swapDepositShareContent(String network, String token, String address) {
    return '网络：$network\n代币：$token\n地址：$address';
  }

  @override
  String swapDepositNotice(String symbol, String network) {
    return '请使用您的 $symbol 或 $network 钱包存入资金。存入其他资产可能导致资金损失。';
  }

  @override
  String get swapDepositProcessingTitle => '处理兑换中';

  @override
  String get swapDepositProcessingBody => '这可能需要几分钟…';

  @override
  String get swapDepositCompleteTitle => '兑换完成';

  @override
  String swapDepositCompleteBody(String amount) {
    return '您兑换的 $amount QUAN 已完成。';
  }

  @override
  String get swapDepositTestnetBanner => '仅供演示——我们仍在测试网';

  @override
  String get swapDepositSentFunds => '我已发送资金';

  @override
  String get swapDepositDone => '完成';

  @override
  String get swapRefundPickerTitle => '退款地址';

  @override
  String get swapRefundPickerEmpty => '没有最近的退款地址';

  @override
  String get componentQrScannerTitle => '扫描二维码';

  @override
  String get componentQrScannerNoCode => '图像中未找到二维码';

  @override
  String get componentShare => '分享';

  @override
  String get componentAddressLabel => '地址';

  @override
  String get componentCheckphraseLabel => '校验短语';

  @override
  String get componentCheckphraseCopied => '校验短语已复制';

  @override
  String get componentNameFieldHint => '为您的账户输入名称';

  @override
  String get commonLoading => '加载中…';

  @override
  String commonAmountBalance(String balance, String symbol) {
    return '$balance $symbol';
  }

  @override
  String get commonContinue => '继续';

  @override
  String get redeemToLabel => '兑换至';

  @override
  String redeemAddressHint(String symbol) {
    return '粘贴 $symbol 地址';
  }

  @override
  String redeemAmountCta(String amount) {
    return '兑换 $amount';
  }

  @override
  String get redeemConfirmTitle => '确认兑换';

  @override
  String get redeemConfirmAmount => '金额';

  @override
  String get redeemConfirmTo => '至';

  @override
  String get redeemConfirmFee => '费用';

  @override
  String get redeemFeeValue => '0.1% 交易量费用';

  @override
  String get redeemProgressTitle => '兑换中…';

  @override
  String get redeemCompleteTitle => '兑换完成';

  @override
  String get redeemFailedTitle => '兑换失败';

  @override
  String get redeemingLabel => '兑换中';

  @override
  String get redeemStepCircuits => '准备电路';

  @override
  String get redeemStepTransfers => '获取转账';

  @override
  String get redeemStepNullifiers => '计算 nullifier';

  @override
  String get redeemStepCheckNullifiers => '检查 nullifier';

  @override
  String get redeemStepProofs => '生成 ZK 证明';

  @override
  String get redeemStepAggregate => '聚合并提交';

  @override
  String redeemFetchedCount(int count) {
    return '已获取 $count';
  }

  @override
  String get redeemCancel => '取消';

  @override
  String get redeemRetry => '重试';

  @override
  String get redeemClose => '关闭';

  @override
  String get redeemDone => '完成';

  @override
  String redeemSuccessBanner(String amount, int count) {
    return '已分 $count 批兑换 $amount';
  }
}
