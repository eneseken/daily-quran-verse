import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// RevenueCat, wrapped so the rest of the app never imports the SDK directly.
///
/// RevenueCat is the source of truth for entitlement; Supabase holds a mirror
/// (see the `subscriptions` table) so the backend can gate premium content
/// without calling out. After every entitlement change we push the new state
/// through `sync_my_subscription`, and RevenueCat's webhook writes the same
/// row server-side as the trusted copy.
class SubscriptionService {
  SubscriptionService._();

  static final instance = SubscriptionService._();

  /// Entitlement identifier configured in the RevenueCat dashboard.
  static const entitlementId = 'premium';

  static const _appleApiKey = 'appl_KFdosNOFyhQjlgpfgxpdvfIlsMF';

  /// Set this once the Play Store product is live; until then Android simply
  /// runs without a configured store rather than crashing on a bad key.
  static const _googleApiKey = '';

  final _premiumController = StreamController<bool>.broadcast();

  bool _isPremium = false;
  bool _configured = false;

  /// Whether the current user holds the premium entitlement.
  bool get isPremium => _isPremium;

  /// Fires whenever entitlement changes — purchase, restore, expiry, or a
  /// login that swaps which customer we're looking at.
  Stream<bool> get premiumStream => _premiumController.stream;

  bool get isConfigured => _configured;

  /// Safe to call on every launch; does nothing if there's no key for the
  /// current platform.
  Future<void> init() async {
    if (_configured) return;

    final apiKey = defaultTargetPlatform == TargetPlatform.iOS
        ? _appleApiKey
        : _googleApiKey;
    if (apiKey.isEmpty) return;

    try {
      await Purchases.setLogLevel(LogLevel.warn);
      await Purchases.configure(PurchasesConfiguration(apiKey));
      _configured = true;

      Purchases.addCustomerInfoUpdateListener(_onCustomerInfo);

      // Tie the RevenueCat customer to the Supabase user when one is already
      // signed in, so the webhook can resolve app_user_id back to a row.
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) await login(userId);

      _onCustomerInfo(await Purchases.getCustomerInfo());
    } catch (e) {
      // A misconfigured dashboard or an offline first launch must not block
      // the app — the user simply sees the free experience.
      debugPrint('RevenueCat init failed: $e');
    }
  }

  /// Aligns the RevenueCat customer with the signed-in Supabase user.
  Future<void> login(String userId) async {
    if (!_configured) return;
    try {
      final result = await Purchases.logIn(userId);
      _onCustomerInfo(result.customerInfo);
    } catch (e) {
      debugPrint('RevenueCat login failed: $e');
    }
  }

  Future<void> logout() async {
    if (!_configured) return;
    try {
      // Throws when already anonymous — harmless, and not worth surfacing.
      await Purchases.logOut();
    } catch (_) {}
    _setPremium(false);
  }

  /// The packages to show on the paywall, or null if none are configured.
  Future<Offering?> currentOffering() async {
    if (!_configured) return null;
    try {
      return (await Purchases.getOfferings()).current;
    } catch (e) {
      debugPrint('RevenueCat offerings failed: $e');
      return null;
    }
  }

  /// Returns true when the purchase completed and granted the entitlement.
  /// A user-cancelled purchase returns false rather than throwing.
  Future<bool> purchase(Package package) async {
    if (!_configured) return false;
    try {
      final result = await Purchases.purchase(
        PurchaseParams.package(package),
      );
      _onCustomerInfo(result.customerInfo);
      return _entitledFrom(result.customerInfo);
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) return false;
      debugPrint('Purchase failed: $code');
      rethrow;
    }
  }

  Future<bool> restore() async {
    if (!_configured) return false;
    try {
      final info = await Purchases.restorePurchases();
      _onCustomerInfo(info);
      return _entitledFrom(info);
    } catch (e) {
      debugPrint('Restore failed: $e');
      return false;
    }
  }

  bool _entitledFrom(CustomerInfo info) =>
      info.entitlements.active.containsKey(entitlementId);

  void _onCustomerInfo(CustomerInfo info) {
    final entitlement = info.entitlements.active[entitlementId];
    _setPremium(entitlement != null);
    unawaited(_mirrorToSupabase(info, entitlement));
  }

  void _setPremium(bool value) {
    if (_isPremium == value) return;
    _isPremium = value;
    if (!_premiumController.isClosed) _premiumController.add(value);
  }

  /// Best-effort cache refresh. The webhook is what the backend actually
  /// trusts, so a failure here is not worth interrupting the user for.
  Future<void> _mirrorToSupabase(
    CustomerInfo info,
    EntitlementInfo? entitlement,
  ) async {
    final client = Supabase.instance.client;
    if (client.auth.currentUser == null) return;

    try {
      await client.rpc('sync_my_subscription', params: {
        'p_status': entitlement != null ? 'active' : 'none',
        'p_entitlement': entitlementId,
        'p_product_id': entitlement?.productIdentifier,
        'p_store': switch (entitlement?.store) {
          Store.appStore || Store.macAppStore => 'app_store',
          Store.playStore => 'play_store',
          null => null,
          _ => 'other',
        },
        'p_expires_at': entitlement?.expirationDate,
        'p_will_renew': entitlement?.willRenew ?? false,
        'p_revenuecat_app_user_id': info.originalAppUserId,
      });
    } catch (e) {
      debugPrint('Subscription mirror failed: $e');
    }
  }
}
