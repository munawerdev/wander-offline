import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

/// A small rounded label, used for pack state ("Offline ready", "Locked"),
/// landmark categories and other inline metadata.
class StatusPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  final bool filled;

  const StatusPill({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    final base = color ?? Theme.of(context).colorScheme.primary;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: filled ? base.withValues(alpha: 0.14) : null,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: base.withValues(alpha: 0.45), width: 1.w),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 11.sp, color: base),
            SizedBox(width: 4.w),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5.sp,
              fontWeight: FontWeight.w700,
              color: base,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
