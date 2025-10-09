import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:play_install_referrer/play_install_referrer.dart';
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:resonance_network_wallet/features/components/submit_referral_action_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;

class ReferralService {
  final _referralEndpoint = Uri.parse(
    '${AppConstants.taskMasterEndpoint}/referrals',
  );
  final _addressEndpoint = Uri.parse(
    '${AppConstants.taskMasterEndpoint}/addresses',
  );
  final _mainAccountIndex = 1;
  final SettingsService _settingsService = SettingsService();

  Future<void> checkReferralOnInstall() async {
    final prefs = await SharedPreferences.getInstance();

    // Only check once - on first launch after install
    bool hasChecked = prefs.getBool(AppConstants.hasCheckReferralKey) ?? false;
    if (hasChecked) return;

    try {
      ReferrerDetails referrerDetails =
          await PlayInstallReferrer.installReferrer;
      String? referrerString = referrerDetails.installReferrer;

      print('Raw Install Referrer: $referrerString');

      if (referrerString != null && referrerString.isNotEmpty) {
        Map<String, String> params = _parseReferrer(referrerString);

        String? referralCode = params['referral_code'];

        if (referralCode != null && referralCode.isNotEmpty) {
          await prefs.setString(AppConstants.referralCodeKey, referralCode);
          await prefs.setBool(AppConstants.hasCheckReferralKey, true);

          print('Referral Code Found: $referralCode');
        }
      }

      print('No referral code found');
    } catch (e) {
      print('Error checking install referrer: $e');
    }
  }

  Future<void> setCheckReferralStatus(bool status) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(AppConstants.hasCheckReferralKey, status);
  }

  Map<String, String> _parseReferrer(String referrer) {
    Map<String, String> params = {};

    Uri uri = Uri.parse('?$referrer');
    params = Map.from(uri.queryParameters);

    return params;
  }

  Future<bool> checkHasReferral() async {
    final account = await _settingsService.getAccount(_mainAccountIndex);
    if (account == null) return false;

    final getReferralByRefereeUri = Uri.parse(
      '${AppConstants.taskMasterEndpoint}/referrals/${account.accountId}',
    );
    final http.Response response = await http.get(
      getReferralByRefereeUri,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Referral http request failed with status: ${response.statusCode}. Body: ${response.body}',
      );
    }

    return true;
  }

  Future<void> submitReferralToBackend({String? referral}) async {
    final prefs = await SharedPreferences.getInstance();

    bool hasSubmitRefferalCode = await checkHasReferral();
    if (hasSubmitRefferalCode) return;

    final referralCode =
        referral ?? prefs.getString(AppConstants.referralCodeKey);
    final activeAccount = await _settingsService.getActiveAccount();

    if (activeAccount == null) {
      throw Exception(
        'Failed sending referral to backend, no active account detected!',
      );
    }
    if (referralCode == null) {
      throw Exception(
        'Failed sending referral to backend, no referral code found!',
      );
    }

    final Map<String, dynamic> requestBody = {
      'referral_code': referralCode,
      'referee_address': activeAccount.accountId,
    };

    final http.Response response = await http.post(
      _referralEndpoint,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Referral http request failed with status: ${response.statusCode}. Body: ${response.body}',
      );
    }
  }

  Future<void> submitAddressToBackend(String address) async {
    final Map<String, dynamic> requestBody = {'quan_address': address};

    final http.Response response = await http.post(
      _addressEndpoint,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Address http request failed with status: ${response.statusCode}. Body: ${response.body}',
      );
    }
  }

  Future<void> promptOrSubmitReferral(
    BuildContext context,
    bool mounted,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    bool hasChecked = prefs.getBool(AppConstants.hasCheckReferralKey) ?? false;
    bool hasSubmit = await checkHasReferral();
    bool hasReferralCode =
        prefs.getString(AppConstants.referralCodeKey) != null;

    if (!hasChecked) {
      await prefs.setBool(AppConstants.hasCheckReferralKey, true);

      // ignore: use_build_context_synchronously
      if (mounted) showSubmitReferralActionSheet(context);
    } else if (Platform.isAndroid &&
        hasChecked &&
        hasReferralCode &&
        !hasSubmit) {
      await submitReferralToBackend();
    }
  }

  String generateReferralLink(String referralCode) {
    return '${AppConstants.websiteBaseUrl}/invite/$referralCode';
  }

  Future<void> shareReferralLink(String referralCode) async {
    String link = generateReferralLink(referralCode);
    String message =
        'Join me on Quantus Wallet! Use my referral code: $referralCode\n\n$link';

    await SharePlus.instance.share(
      ShareParams(text: message, subject: 'Invite Link', title: 'Invite Link'),
    );
  }
}
