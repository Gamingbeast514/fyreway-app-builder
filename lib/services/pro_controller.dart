import 'package:flutter/foundation.dart';

import '../config.dart';

/// Kovra Pro subscription state.
///
/// Day 1: purchases are SIMULATED in debug builds so the flow can be tested.
/// Next step: connect the `in_app_purchase` library + Play Console products
/// (IDs in ProPlan.all) and replace [buy] / [restore].
class ProController extends ChangeNotifier {
  bool isPro = false;
  String? activePlanId;

  /// Returns true if the purchase went through.
  Future<bool> buy(ProPlan plan) async {
    if (!kDebugMode) return false; // real billing not connected yet
    await Future.delayed(const Duration(milliseconds: 600));
    isPro = true;
    activePlanId = plan.id;
    notifyListeners();
    return true;
  }

  /// Returns true if an active subscription was found.
  Future<bool> restore() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return isPro;
  }
}

final pro = ProController();
