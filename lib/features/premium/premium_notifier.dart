import 'package:flutter/services.dart';

import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'premium_notifier.g.dart';

/// Owns the premium entitlement state backed by RevenueCat.
///
/// Generated provider name: [premiumProvider]
/// Usage pattern everywhere:
///   final isPremium = ref.watch(premiumProvider).maybeWhen(data: (v) => v, orElse: () => false);
@Riverpod(keepAlive: true)
class PremiumNotifier extends _$PremiumNotifier {
  static const _entitlementId = 'cluster_premium_lifetime';
  static const _productId = 'cluster_premium_lifetime';

  @override
  Future<bool> build() async {
    try {
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.active.containsKey(_entitlementId);
    } catch (_) {
      return false;
    }
  }

  /// Initiates the RevenueCat purchase flow via offerings (v9 API).
  ///
  /// On success: sets state to [AsyncData(true)].
  /// On user cancellation: silently does nothing.
  /// On any other error: rethrows so the UI can show a SnackBar.
  Future<void> purchase() async {
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;
      if (current == null) {
        throw Exception('No offerings available from RevenueCat');
      }

      // Find the matching package by product identifier
      Package? pkg;
      for (final p in current.availablePackages) {
        if (p.storeProduct.identifier == _productId) {
          pkg = p;
          break;
        }
      }

      // Fall back to first available package if no exact match
      pkg ??= current.availablePackages.isNotEmpty
          ? current.availablePackages.first
          : null;

      if (pkg == null) {
        throw Exception('No packages found in current offering');
      }

      final result = await Purchases.purchasePackage(pkg);
      final isActive = result.customerInfo.entitlements.active.containsKey(
        _entitlementId,
      );
      state = AsyncData(isActive);
    } on PurchasesErrorCode catch (e) {
      if (e == PurchasesErrorCode.purchaseCancelledError) {
        // User cancelled — do nothing
        return;
      }
      rethrow;
    } on PlatformException catch (e) {
      if (e.details?['userCancelled'] == true) return;
      rethrow;
    }
  }

  /// Restores previous purchases and updates premium state accordingly.
  Future<void> restore() async {
    try {
      final info = await Purchases.restorePurchases();
      final isActive = info.entitlements.active.containsKey(_entitlementId);
      state = AsyncData(isActive);
    } catch (_) {
      state = const AsyncData(false);
    }
  }
}
