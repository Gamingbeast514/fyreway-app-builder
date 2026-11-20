import 'package:flutter/material.dart';

import '../theme.dart';

/// Reserved space for the AdMob banner (free users). Real ads come later.
class AdBannerPlaceholder extends StatelessWidget {
  const AdBannerPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.kc;
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: c.panel,
        border: Border(top: BorderSide(color: c.border)),
      ),
      alignment: Alignment.center,
      child: Text('AD BANNER · 320×50', style: TextStyle(fontSize: 12, color: c.hint, letterSpacing: 0.5)),
    );
  }
}
