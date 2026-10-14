import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ufuq_imperium/core/localization/locale_controller.dart';
import 'package:ufuq_imperium/core/theme/tokens.dart';
import 'package:ufuq_imperium/core/theme/type.dart';
import 'package:ufuq_imperium/core/utils/links.dart';
import 'package:ufuq_imperium/core/widgets/brand.dart';
import 'package:ufuq_imperium/features/settings/presentation/widgets/social_links.dart';
import 'package:ufuq_imperium/features/settings/state/settings_controller.dart';
import 'package:ufuq_imperium/features/shell/presentation/widgets/brand_logo.dart';

/// Logo, a line about the office, accounts and contact details, then the copyright.
class SiteFooter extends StatelessWidget {
  const SiteFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleController>();
    final settings = context.watch<SettingsController>();
    final c = locale.c;
    final type = context.type;
    final pal = context.pal;
    final year = DateTime.now().year;
    final bottom = MediaQuery.paddingOf(context).bottom + kNavHeight;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(kGutter, 54, kGutter, 26 + bottom),
      decoration: BoxDecoration(
        color: pal.dark ? Colors.black : pal.bg3,
        border: Border(top: BorderSide(color: pal.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BrandLogo(height: 34, compact: false),
          const SizedBox(height: 18),
          Text(c.footerBlurb, style: type.body()),
          if (settings.social.isNotEmpty) ...[
            const SizedBox(height: 26),
            Text(tracked(context, c.socialLabel), style: type.kicker()),
            const SizedBox(height: 14),
            const SocialLinks(),
          ],
          const SizedBox(height: 30),
          if (settings.phone.isNotEmpty)
            _Line(
              text: settings.phone,
              ltr: true,
              onTap: () => openExternal(telUri(settings.phone)),
            ),
          if (settings.email.isNotEmpty)
            _Line(
              text: settings.email,
              ltr: true,
              onTap: () => openExternal(mailUri(settings.email)),
            ),
          if (settings.address.isNotEmpty) _Line(text: settings.address),
          if (settings.hours.isNotEmpty) _Line(text: settings.hours),
          const SizedBox(height: 26),
          Hairline(fade: false, color: pal.line),
          const SizedBox(height: 18),
          Text(
            '© $year ${c.rights}',
            style: type.body(size: 12.5, color: pal.faint),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.text, this.ltr = false, this.onTap});
  final String text;
  final bool ltr;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final type = context.type;
    final pal = context.pal;
    final child = Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          text,
          textDirection: ltr ? TextDirection.ltr : null,
          style: type.body(
            color: onTap == null ? pal.muted : pal.accentSoft,
            size: 14.5,
          ),
        ),
      ),
    );
    return onTap == null
        ? child
        : GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: child,
          );
  }
}
