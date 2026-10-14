import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:ufuq_imperium/core/localization/locale_controller.dart';
import 'package:ufuq_imperium/core/network/api_exception.dart';
import 'package:ufuq_imperium/core/theme/tokens.dart';
import 'package:ufuq_imperium/core/theme/type.dart';
import 'package:ufuq_imperium/core/utils/links.dart';
import 'package:ufuq_imperium/core/widgets/brand.dart';
import 'package:ufuq_imperium/core/widgets/fields.dart';
import 'package:ufuq_imperium/core/widgets/page_blocks.dart';
import 'package:ufuq_imperium/core/widgets/path_icon.dart';
import 'package:ufuq_imperium/core/widgets/reveal.dart';
import 'package:ufuq_imperium/features/contact/data/contact_repository.dart';
import 'package:ufuq_imperium/features/settings/presentation/widgets/social_links.dart';
import 'package:ufuq_imperium/features/settings/state/settings_controller.dart';
import 'package:ufuq_imperium/features/shell/presentation/tab_page.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _subject = TextEditingController();
  final _message = TextEditingController();
  String _error = '';
  bool _sent = false;
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _subject, _message]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final c = context.read<LocaleController>().c;
    final repository = context.read<ContactRepository>();
    final name = _name.text.trim();
    final email = _email.text.trim();
    final subject = _subject.text.trim();
    final message = _message.text.trim();
    final phone = _phone.text.trim();
    if (name.isEmpty ||
        email.isEmpty ||
        subject.isEmpty ||
        message.isEmpty ||
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      HapticFeedback.mediumImpact();
      setState(() {
        _error = c.invalid;
        _sent = false;
      });
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = '';
    });
    try {
      await repository.sendMessage(
        name: name,
        email: email,
        phone: phone.isEmpty ? null : phone,
        subject: subject,
        message: message,
      );
      if (!mounted) return;
      HapticFeedback.lightImpact();
      for (final field in [_name, _email, _phone, _subject, _message]) {
        field.clear();
      }
      setState(() {
        _sent = true;
        _busy = false;
      });
    } on ApiException {
      if (!mounted) return;
      setState(() {
        _error = c.failed;
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final locale = context.watch<LocaleController>();
    final settings = context.watch<SettingsController>();
    final c = locale.c;
    final type = context.type;

    return TabPage(
      slivers: [
        SliverToBoxAdapter(
          child: PageIntro(kicker: c.contactEyebrow, title: c.contactTitle),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(kGutter, 8, kGutter, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (settings.phone.isNotEmpty)
                  Reveal(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => openExternal(telUri(settings.phone)),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 22),
                        child: Text(
                          settings.phone,
                          textDirection: TextDirection.ltr,
                          style: type.latin(
                            size: 34,
                            color: pal.accentSoft,
                            spacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (settings.phone.isNotEmpty)
                  Reveal(
                    delay: const Duration(milliseconds: 60),
                    child: Row(
                      children: [
                        Expanded(
                          child: _Action(
                            glyph: Glyphs.phone,
                            label: c.call,
                            onTap: () => openExternal(telUri(settings.phone)),
                          ),
                        ),
                        if (settings.whatsapp.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: _Action(
                              glyph: Glyphs.whatsapp,
                              label: c.whatsapp,
                              onTap: () =>
                                  openExternal(whatsappUri(settings.whatsapp)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                const SizedBox(height: 34),
                if (settings.email.isNotEmpty)
                  _Way(
                    glyph: Glyphs.mail,
                    text: settings.email,
                    ltr: true,
                    onTap: () => openExternal(mailUri(settings.email)),
                  ),
                if (settings.address.isNotEmpty)
                  _Way(glyph: Glyphs.pin, text: settings.address),
                if (settings.hours.isNotEmpty)
                  _Way(glyph: Glyphs.clock, text: settings.hours),
                if (settings.social.isNotEmpty) ...[
                  const SizedBox(height: 26),
                  Reveal(
                    child: Text(
                      tracked(context, c.socialLabel),
                      style: type.kicker(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Reveal(child: SocialLinks(labelled: true)),
                ],
                const SizedBox(height: 44),
                const Hairline(),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.fromLTRB(kGutter, 44, kGutter, 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Reveal(
                  child: Text(
                    c.contactNote,
                    style: type.body(color: pal.faint, size: 12.5),
                  ),
                ),
                const SizedBox(height: 18),
                Reveal(
                  child: LuxField(
                    label: c.fieldName,
                    controller: _name,
                    autofillHints: const [AutofillHints.name],
                    onChanged: _clearError,
                  ),
                ),
                const SizedBox(height: 22),
                Reveal(
                  child: LuxField(
                    label: c.fieldEmail,
                    controller: _email,
                    ltr: true,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    onChanged: _clearError,
                  ),
                ),
                const SizedBox(height: 22),
                Reveal(
                  child: LuxField(
                    label: c.fieldPhone,
                    controller: _phone,
                    ltr: true,
                    keyboardType: TextInputType.phone,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    onChanged: _clearError,
                  ),
                ),
                const SizedBox(height: 22),
                Reveal(
                  child: LuxField(
                    label: c.fieldSubject,
                    controller: _subject,
                    onChanged: _clearError,
                  ),
                ),
                const SizedBox(height: 22),
                Reveal(
                  child: LuxField(
                    label: c.fieldMessage,
                    controller: _message,
                    maxLines: 6,
                    onChanged: _clearError,
                  ),
                ),
                const SizedBox(height: 30),
                if (_error.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _error,
                      style: type
                          .body(color: pal.error, size: 14.5)
                          .copyWith(fontWeight: FontWeight.w400),
                    ),
                  ),
                if (_sent)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        const PathIcon(
                          Glyphs.check,
                          size: 20,
                          strokeWidth: 1.8,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            c.sent,
                            style: type
                                .body(color: pal.accentSoft, size: 15.5)
                                .copyWith(fontWeight: FontWeight.w400),
                          ),
                        ),
                      ],
                    ),
                  ),
                GoldButton(
                  label: c.send,
                  busy: _busy,
                  onTap: _busy ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _clearError() {
    if (_error.isNotEmpty || _sent) {
      setState(() {
        _error = '';
        _sent = false;
      });
    }
  }
}

class _Action extends StatefulWidget {
  const _Action({
    required this.glyph,
    required this.label,
    required this.onTap,
  });
  final String glyph;
  final String label;
  final VoidCallback onTap;

  @override
  State<_Action> createState() => _ActionState();
}

class _ActionState extends State<_Action> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final type = context.type;
    final ink = _down ? pal.onAccent : pal.accentSoft;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Brand.ease,
        height: 58,
        decoration: BoxDecoration(
          color: _down ? pal.accentSoft : Colors.transparent,
          border: Border.all(color: pal.accent),
        ),
        // Scales the icon + label down together instead of overflowing on narrow screens.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                PathIcon(widget.glyph, size: 20, color: ink, strokeWidth: 1.5),
                const SizedBox(width: 12),
                Text(
                  tracked(context, widget.label),
                  style: type
                      .label(color: ink, size: type.ar ? 16 : 11.5)
                      .copyWith(letterSpacing: type.ar ? 0 : 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Way extends StatelessWidget {
  const _Way({
    required this.glyph,
    required this.text,
    this.ltr = false,
    this.onTap,
  });
  final String glyph;
  final String text;
  final bool ltr;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final type = context.type;
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: pal.accentSoft.withValues(alpha: 0.4)),
            ),
            child: PathIcon(glyph, size: 19, strokeWidth: 1.4),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 9),
              child: Text(
                text,
                textDirection: ltr ? TextDirection.ltr : null,
                textAlign: ltr ? TextAlign.left : TextAlign.start,
                style: type
                    .body(color: onTap == null ? pal.muted : pal.text, size: 16)
                    .copyWith(fontWeight: FontWeight.w400),
              ),
            ),
          ),
        ],
      ),
    );
    final wrapped = onTap == null
        ? row
        : GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: row,
          );
    return Reveal(child: wrapped);
  }
}
