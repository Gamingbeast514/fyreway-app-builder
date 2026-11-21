import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config.dart';

/// Day 1 sharing: copies the invite to the clipboard (no extra libraries).
/// Later: swap for the share_plus library to open WhatsApp / Instagram directly.
class ShareHelper {
  static Future<void> copyInvite(BuildContext context, {String? text}) async {
    await Clipboard.setData(ClipboardData(text: text ?? AppConfig.inviteText));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Invite copied, paste it in WhatsApp or anywhere')));
  }

  static void comingSoon(BuildContext context, String what) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$what will open once ${AppConfig.brand} is live on the stores')));
  }
}
