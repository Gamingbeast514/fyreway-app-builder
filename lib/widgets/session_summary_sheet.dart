import 'package:flutter/material.dart';

import '../config.dart';
import '../services/share_helper.dart';
import '../services/vpn_controller.dart';
import '../theme.dart';
import 'code_badge.dart';

/// Shown after disconnecting: what happened + a share nudge.
Future<void> showSessionSummary(BuildContext context, SessionSummary s) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: context.kc.card,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (context) {
      final c = context.kc;
      final d = s.duration;
      final time = d.inHours > 0
          ? '${d.inHours} h ${d.inMinutes % 60} min'
          : d.inMinutes > 0
              ? '${d.inMinutes} min ${d.inSeconds % 60} s'
              : '${d.inSeconds} s';
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Session ended', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: c.text)),
            const SizedBox(height: 4),
            Text('You were protected for $time.', style: TextStyle(fontSize: 15, color: c.muted)),
            const SizedBox(height: 18),
            Row(children: [
              CodeBadge(code: s.server.code),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s.server.country, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.text)),
                  Text(s.server.city, style: TextStyle(fontSize: 13, color: c.muted)),
                ]),
              ),
              Text(time, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.accent)),
            ]),
            const SizedBox(height: 22),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: c.accent,
                  foregroundColor: c.onAccent,
                  shape: const StadiumBorder(),
                ),
                onPressed: () => ShareHelper.copyInvite(
                  context,
                  text: 'I just stayed private for $time with ${AppConfig.appName}. Free for 3 months, no ads: ${AppConfig.playStoreUrl}',
                ),
                icon: const Icon(Icons.ios_share),
                label: const Text('Tell a friend', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
          ]),
        ),
      );
    },
  );
}
