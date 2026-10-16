import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '/core/utils/extensions.dart';

/// A titled, bordered card used to group content on the pack screens.
///
/// Keeping this in one place means every pack section - facts, weather,
/// converter, tips - shares the same radius, padding and heading treatment,
/// which is what stops a five-tab feature from looking hand-assembled.
class SectionCard extends StatelessWidget {
  final String? title;
  final IconData? icon;
  final Widget? trailing;
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  const SectionCard({
    super.key,
    this.title,
    this.icon,
    this.trailing,
    this.children = const <Widget>[],
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final heading = title;

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: SizedBox(
        width: double.infinity,
        // A Material root rather than a decorated Container: this is what lets
        // ink-based children - SwitchListTile, dropdowns, InkWells - paint their
        // splashes instead of warning that they would be invisible. `shape`
        // carries the radius and the hairline border.
        child: Material(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
            side: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.5),
              width: 1.w,
            ),
          ),
          child: Padding(
            padding: padding ?? EdgeInsets.all(14.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (heading != null) ...<Widget>[
                  Row(
                    children: <Widget>[
                      if (icon != null) ...<Widget>[
                        Icon(icon, size: 17.sp, color: scheme.primary),
                        SizedBox(width: 7.w),
                      ],
                      Expanded(
                        child: Text(
                          heading,
                          style: context.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      ?trailing,
                    ],
                  ),
                  SizedBox(height: 9.h),
                ],
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A bulleted line, used by the tips sections.
class BulletLine extends StatelessWidget {
  final String text;
  final Color? dotColor;

  const BulletLine({super.key, required this.text, this.dotColor});

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: 7.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(top: 6.h),
            child: Container(
              width: 5.w,
              height: 5.w,
              decoration: BoxDecoration(
                color: dotColor ?? scheme.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          SizedBox(width: 9.w),
          Expanded(
            child: Text(
              text,
              style: context.textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
