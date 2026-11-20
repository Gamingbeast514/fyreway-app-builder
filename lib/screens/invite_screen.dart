import 'package:flutter/material.dart';

import '../config.dart';
import '../services/share_helper.dart';
import '../theme.dart';
import '../widgets/logo.dart';

/// Viral loop: easy invite with a ready-made message.
class InviteScreen extends StatelessWidget {
  const InviteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.kc;
    return Scaffold(
      appBar: AppBar(title: const Text('Invite friends', style: TextStyle(fontWeight: FontWeight.w700))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          const SizedBox(height: 8),
          const Center(child: KovraLogo(size: 110)),
          const SizedBox(height: 20),
          Text('Share privacy with your friends',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: c.text)),
          const SizedBox(height: 8),
          Text('Free to use. No ads, ever. One tap to connect.',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 15, height: 1.5, color: c.muted)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.border),
            ),
            child: Text(AppConfig.inviteText, style: TextStyle(fontSize: 14, height: 1.5, color: c.text)),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 54,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: c.accent,
                foregroundColor: c.onAccent,
                shape: const StadiumBorder(),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              onPressed: () => ShareHelper.copyInvite(context),
              icon: const Icon(Icons.copy_rounded),
              label: const Text('Copy invite'),
            ),
          ),
          const SizedBox(height: 12),
          Text('Paste it in WhatsApp, Instagram or any group chat.',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: c.hint)),
        ],
      ),
    );
  }
}
