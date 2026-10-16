import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '/config/theme/app_colors.dart';
import '/core/utils/color_utils.dart';
import '/core/utils/extensions.dart';
import '/core/widgets/app_button.dart';
import '/core/widgets/status_pill.dart';
import '/features/pack_browser/pack_browser_state.dart';

/// One catalogue row: the flag, the pitch, whether it is on the device, and the
/// single action that moves it forward.
class PackCard extends StatelessWidget {
  final PackCardState card;
  final bool isDownloading;
  final double downloadFraction;
  final String? downloadMessage;
  final VoidCallback onOpen;
  final VoidCallback onDownload;
  final VoidCallback onDelete;
  final VoidCallback onRefresh;

  const PackCard({
    super.key,
    required this.card,
    required this.onOpen,
    required this.onDownload,
    required this.onDelete,
    required this.onRefresh,
    this.isDownloading = false,
    this.downloadFraction = 0,
    this.downloadMessage,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final accent = colorFromHex(card.summary.accentColorHex);
    final isDark = context.isDarkMode;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: accent.withValues(alpha: isDark ? 0.5 : 0.28),
          width: 1.w,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            accent.withValues(alpha: isDark ? 0.24 : 0.13),
            scheme.surface,
          ],
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: onOpen,
          child: Padding(
            padding: EdgeInsets.all(14.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _Header(card: card, accent: accent),
                SizedBox(height: 9.h),
                Text(
                  card.summary.tagline,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.85),
                    height: 1.35,
                  ),
                ),
                SizedBox(height: 10.h),
                _Pills(card: card, accent: accent),
                if (isDownloading) ...<Widget>[
                  SizedBox(height: 12.h),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6.r),
                    child: LinearProgressIndicator(
                      value: downloadFraction <= 0 ? null : downloadFraction,
                      minHeight: 5.h,
                      backgroundColor: scheme.surfaceContainerHighest,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    downloadMessage ?? 'Working...',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
                SizedBox(height: 12.h),
                _actions(context, accent),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _actions(BuildContext context, Color accent) {
    if (isDownloading) {
      return AppButton(
        text: 'Downloading',
        onPressed: null,
        loading: true,
        height: 40.h,
      );
    }

    if (card.isInstalled) {
      return Row(
        children: <Widget>[
          Expanded(
            child: AppButton(
              text: 'Open offline',
              onPressed: onOpen,
              height: 40.h,
              backgroundColor: accent,
              foregroundColor: readableOn(accent),
            ),
          ),
          SizedBox(width: 6.w),
          _iconAction(
            icon: Icons.refresh_rounded,
            tooltip: 'Refresh weather and rates',
            onPressed: onRefresh,
          ),
          _iconAction(
            icon: Icons.delete_outline_rounded,
            tooltip: 'Remove from this device',
            onPressed: onDelete,
          ),
        ],
      );
    }

    return AppButton(
      text: 'Download pack',
      onPressed: onDownload,
      height: 40.h,
      icon: const Icon(Icons.download_rounded),
    );
  }

  Widget _iconAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) => IconButton(
    onPressed: onPressed,
    icon: Icon(icon, size: 18.sp),
    tooltip: tooltip,
    visualDensity: VisualDensity.compact,
  );
}

class _Header extends StatelessWidget {
  final PackCardState card;
  final Color accent;

  const _Header({required this.card, required this.accent});

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 46.w,
          height: 46.w,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Text(
            card.summary.flagEmoji,
            style: TextStyle(fontSize: 23.sp),
          ),
        ),
        SizedBox(width: 11.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                card.name,
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                '${card.summary.region} · ${card.summary.primaryCity}',
                style: context.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (card.isInstalled)
          const StatusPill(
            label: 'OFFLINE',
            icon: Icons.download_done_rounded,
            color: AppColors.success,
          ),
      ],
    );
  }
}

class _Pills extends StatelessWidget {
  final PackCardState card;
  final Color accent;

  const _Pills({required this.card, required this.accent});

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Wrap(
      spacing: 6.w,
      runSpacing: 6.h,
      children: <Widget>[
        StatusPill(
          label: '${card.summary.landmarkCount} places',
          icon: Icons.place_outlined,
          color: accent,
        ),
        StatusPill(
          label: '${card.summary.tipCount} local tips',
          icon: Icons.lightbulb_outline_rounded,
          color: scheme.onSurfaceVariant,
        ),
        const StatusPill(
          label: 'FREE',
          icon: Icons.volunteer_activism_outlined,
          color: AppColors.success,
        ),
      ],
    );
  }
}
