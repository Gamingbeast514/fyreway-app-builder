import 'package:flutter/material.dart';

import '../config.dart';
import '../services/share_helper.dart';
import '../theme.dart';
import '../widgets/logo.dart';
import '../widgets/ui.dart';
import '../widgets/kovra_icons.dart';

/// Viral loop: easy invite with a ready-made message.
class InviteScreen extends StatelessWidget {
  const InviteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.kc;
    return SheetPage(
      title: 'Invite friends',
      bottom: Column(mainAxisSize: MainAxisSize.min, children: [
        KovraButton.primary(
          label: 'Copy invite',
          icon: PhosphorIconsRegular.copy,
          onPressed: () => ShareHelper.copyInvite(context),
        ),
        const SizedBox(height: 10),
        Text('Paste it in WhatsApp, Instagram or any group chat.', style: KovraText.caption.copyWith(color: c.hint)),
      ]),
      children: [
        const SizedBox(height: 8),
        Center(
          child: Container(
            width: 96,
            height: 96,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: c.primarySoft, borderRadius: BorderRadius.circular(30)),
            child: const KovraLogo(size: 76),
          ),
        ),
        const SizedBox(height: 18),
        Text('Share privacy with your friends',
            textAlign: TextAlign.center, style: KovraText.headline.copyWith(color: c.text)),
        const SizedBox(height: 8),
        Text(
            AppConfig.adsEnabled
                ? 'Free to use. One tap to connect.'
                : 'Free to use. No ads, ever. One tap to connect.',
            textAlign: TextAlign.center,
            style: KovraText.body.copyWith(color: c.muted)),
        const SectionLabel('Your message'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: c.line),
          ),
          child: Text(AppConfig.inviteText, style: TextStyle(fontSize: 14, height: 1.5, color: c.text)),
        ),
      ],
    );
  }
}
