import 'package:flutter/material.dart';

import '../config.dart';
import '../services/share_helper.dart';
import '../services/vpn_controller.dart';
import '../theme.dart';
import 'ui.dart';
import 'kovra_icons.dart';

/// Shown after disconnecting: what happened + a share nudge.
Future<void> showSessionSummary(BuildContext context, SessionSummary s) {
  return showOverlaySheet<void>(
    context,
    builder: (context) {
      final c = context.kc;
      final time = fmtDuration(s.duration);
      final inB = s.bytesIn, outB = s.bytesOut;
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SizedBox(height: 4),
        Text('Session ended', style: KovraText.title.copyWith(color: c.text)),
        const SizedBox(height: 4),
        Text('You were protected for $time.', style: KovraText.body.copyWith(color: c.muted)),
        const SizedBox(height: 18),
        GroupCard(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: LocationRow(
              code: s.server.code,
              title: s.server.displayName,
              subtitle: s.server.isLive ? s.server.ip : s.server.rowSubtitle,
              trailing: Text(time,
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700, color: c.primary, fontFeatures: KovraText.tabular)),
            ),
          ),
          if (inB != null && outB != null) ...[
            KvRow(icon: PhosphorIconsRegular.arrowDown, label: 'Downloaded', value: fmtBytes(inB)),
            KvRow(icon: PhosphorIconsRegular.arrowUp, label: 'Uploaded', value: fmtBytes(outB)),
          ],
        ]),
        const SizedBox(height: 20),
        KovraButton.primary(
          label: 'Tell a friend',
          icon: PhosphorIconsRegular.shareNetwork,
          onPressed: () => ShareHelper.copyInvite(
            context,
            text:
                'I just stayed private for $time with ${AppConfig.appName}. Free to use${AppConfig.adsEnabled ? '' : ', no ads'}: ${AppConfig.playStoreUrl}',
          ),
        ),
        const SizedBox(height: 10),
        KovraButton.light(label: 'Done', onPressed: () => Navigator.pop(context)),
      ]);
    },
  );
}
