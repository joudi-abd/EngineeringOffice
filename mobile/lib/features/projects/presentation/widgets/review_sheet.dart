import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:ufuq_imperium/core/localization/locale_controller.dart';
import 'package:ufuq_imperium/core/network/api_exception.dart';
import 'package:ufuq_imperium/core/theme/tokens.dart';
import 'package:ufuq_imperium/core/theme/type.dart';
import 'package:ufuq_imperium/core/widgets/brand.dart';
import 'package:ufuq_imperium/core/widgets/fields.dart';
import 'package:ufuq_imperium/features/projects/data/projects_repository.dart';

/// Bottom sheet where a visitor writes a review for a project. Pops `true` once it is sent.
class ReviewSheet extends StatefulWidget {
  const ReviewSheet({
    super.key,
    required this.projectId,
    required this.initialRating,
  });
  final int projectId;
  final int initialRating;

  static Future<bool?> show(
    BuildContext context, {
    required int projectId,
    required int rating,
  }) {
    // No palette colours are read here: a route keeps what it is given when it opens, so the sheet's
    // background comes from the theme's BottomSheetThemeData and keeps following the phone's day/night
    // setting while the sheet is open. The barrier is a neutral dim that suits both looks.
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      barrierColor: const Color(0x8C000000),
      shape: const RoundedRectangleBorder(),
      builder: (_) => ReviewSheet(projectId: projectId, initialRating: rating),
    );
  }

  @override
  State<ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<ReviewSheet> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _text = TextEditingController();
  late int _rating = widget.initialRating;
  bool _consent = false;
  bool _busy = false;
  String _error = '';

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final c = context.read<LocaleController>().c;
    final repository = context.read<ProjectsRepository>();
    final name = _name.text.trim();
    final email = _email.text.trim();
    final text = _text.text.trim();
    if (name.isEmpty ||
        email.isEmpty ||
        text.isEmpty ||
        !_consent ||
        _rating < 1 ||
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      HapticFeedback.mediumImpact();
      setState(() => _error = c.reviewInvalid);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = '';
    });
    try {
      await repository.sendReview(
        widget.projectId,
        name: name,
        email: email,
        content: text,
        rating: _rating,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = error.isConflict ? c.emailTaken : c.reviewFailed;
      });
    }
  }

  void _clear() {
    if (_error.isNotEmpty) setState(() => _error = '');
  }

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final locale = context.watch<LocaleController>();
    final c = locale.c;
    final type = context.type;
    final inset = MediaQuery.viewInsetsOf(context).bottom;

    return Directionality(
      textDirection: locale.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 160),
        padding: EdgeInsets.only(bottom: inset),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(kGutter, 14, kGutter, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(child: Container(width: 44, height: 3, color: pal.line)),
              const SizedBox(height: 26),
              Text(c.dialogTitle, style: type.display(type.ar ? 27 : 30)),
              const SizedBox(height: 14),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Semantics(
                  label: c.rateLabel,
                  child: Stars(
                    value: _rating,
                    size: 28,
                    gap: 6,
                    onChanged: (v) => setState(() {
                      _rating = v;
                      _error = '';
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              LuxField(
                label: c.reviewName,
                controller: _name,
                autofillHints: const [AutofillHints.name],
                onChanged: _clear,
              ),
              const SizedBox(height: 20),
              LuxField(
                label: c.reviewEmail,
                controller: _email,
                ltr: true,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                onChanged: _clear,
              ),
              const SizedBox(height: 20),
              LuxField(
                label: c.reviewText,
                controller: _text,
                maxLines: 5,
                onChanged: _clear,
              ),
              const SizedBox(height: 22),
              LuxCheck(
                value: _consent,
                label: c.consent,
                onChanged: (v) => setState(() {
                  _consent = v;
                  _error = '';
                }),
              ),
              const SizedBox(height: 18),
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
              GoldButton(
                label: c.sendReview,
                busy: _busy,
                onTap: _busy ? null : _send,
              ),
              const SizedBox(height: 6),
              Center(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).pop(false),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 20,
                    ),
                    child: Text(
                      tracked(context, c.close),
                      style: type.label(
                        color: pal.muted,
                        size: type.ar ? 15 : 11,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
