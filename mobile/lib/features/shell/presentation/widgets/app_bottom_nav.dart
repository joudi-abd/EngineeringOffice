import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:ufuq_imperium/core/theme/tokens.dart';
import 'package:ufuq_imperium/core/theme/type.dart';
import 'package:ufuq_imperium/core/widgets/path_icon.dart';

class NavTab {
  const NavTab(this.glyph);
  final String glyph;
}

/// Five-tab bottom bar: square-edged, hairline top, with a gold tick over the active tab.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.index,
    required this.labels,
    required this.onSelect,
  });

  final int index;
  final List<String> labels;
  final ValueChanged<int> onSelect;

  static const tabs = [
    NavTab(Glyphs.home),
    NavTab(Glyphs.about),
    NavTab(Glyphs.services),
    NavTab(Glyphs.projects),
    NavTab(Glyphs.contact),
  ];

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final type = context.type;
    final pal = context.pal;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          height: kNavHeight + bottom,
          padding: EdgeInsets.only(bottom: bottom),
          decoration: BoxDecoration(
            color: pal.bar,
            border: Border(
              top: BorderSide(color: pal.accentSoft.withValues(alpha: 0.22)),
            ),
          ),
          child: Row(
            children: [
              for (var i = 0; i < tabs.length; i++)
                Expanded(
                  child: _NavItem(
                    glyph: tabs[i].glyph,
                    label: labels[i],
                    active: i == index,
                    type: type,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onSelect(i);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.glyph,
    required this.label,
    required this.active,
    required this.type,
    required this.onTap,
  });

  final String glyph;
  final String label;
  final bool active;
  final AppType type;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final color = active ? pal.accentSoft : pal.text.withValues(alpha: 0.46);
    return Semantics(
      button: true,
      selected: active,
      excludeSemantics: true,
      label: label,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 380),
              curve: Brand.ease,
              width: active ? 30 : 0,
              height: 2,
              decoration: BoxDecoration(gradient: pal.goldGradient),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<Color?>(
                    tween: ColorTween(end: color),
                    duration: const Duration(milliseconds: 300),
                    builder: (_, value, _) => PathIcon(
                      glyph,
                      size: 23,
                      color: value ?? color,
                      strokeWidth: 1.4,
                    ),
                  ),
                  const SizedBox(height: 5),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: type
                        .latin(
                          size: type.ar ? 11.5 : 9.5,
                          weight: active ? FontWeight.w500 : FontWeight.w400,
                          color: color,
                          spacing: type.ar ? 0 : 1.2,
                        )
                        .copyWith(
                          fontFamily: type.family,
                          fontFamilyFallback: [type.fallback],
                        ),
                    child: Text(
                      tracked(context, label),
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
