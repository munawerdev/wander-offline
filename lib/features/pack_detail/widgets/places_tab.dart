import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '/core/utils/extensions.dart';
import '/core/widgets/section_card.dart';
import '/core/widgets/stat_tile.dart';
import '/core/widgets/status_pill.dart';
import '/data/models/pack/landmark_model.dart';
import '/features/pack_detail/pack_detail_state.dart';
import 'landmark_map.dart';
import 'schematic_map.dart';

/// The places tab: a map of the pack's landmarks plus the hand-written entries.
///
/// The map can be flipped between real OSM tiles and the tile-free schematic
/// diagram, which is what lets this screen stay useful when the traveller is
/// somewhere with no signal and no cached tiles.
class PackPlacesTab extends StatelessWidget {
  final PackDetailState state;
  final ValueChanged<String> onSelectLandmark;
  final VoidCallback onToggleMapMode;

  const PackPlacesTab({
    super.key,
    required this.state,
    required this.onSelectLandmark,
    required this.onToggleMapMode,
  });

  @override
  Widget build(BuildContext context) {
    final landmarks = state.landmarks;

    return ListView(
      padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 28.h),
      children: <Widget>[
        SizedBox(
          height: 250.h,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14.r),
            child: Stack(
              children: <Widget>[
                Positioned.fill(
                  child: state.showSchematicMap
                      ? SchematicMap(
                          landmarks: landmarks,
                          selectedLandmarkId: state.selectedLandmarkId,
                          onSelectLandmark: onSelectLandmark,
                        )
                      : LandmarkMap(
                          landmarks: landmarks,
                          selectedLandmarkId: state.selectedLandmarkId,
                          onSelectLandmark: onSelectLandmark,
                        ),
                ),
                Positioned(
                  top: 7.h,
                  right: 7.w,
                  child: _MapModeToggle(
                    showSchematic: state.showSchematicMap,
                    onPressed: onToggleMapMode,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 7.h),
        Text(
          state.showSchematicMap
              ? 'Offline diagram - always available, no tiles needed. '
                    'Switch to the street map when you have signal.'
              : 'Street map tiles are cached as you browse, so anywhere you '
                    'have already looked stays available offline.',
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 14.h),
        for (var index = 0; index < landmarks.length; index++)
          _LandmarkCard(
            index: index + 1,
            landmark: landmarks[index],
            isExpanded: state.selectedLandmarkId == landmarks[index].mapKey,
            onTap: () => onSelectLandmark(landmarks[index].mapKey),
          ),
      ],
    );
  }
}

class _MapModeToggle extends StatelessWidget {
  final bool showSchematic;
  final VoidCallback onPressed;

  const _MapModeToggle({required this.showSchematic, required this.onPressed});

  @override
  Widget build(BuildContext context) => Material(
    color: context.colorScheme.surface.withValues(alpha: 0.92),
    borderRadius: BorderRadius.circular(20.r),
    child: InkWell(
      borderRadius: BorderRadius.circular(20.r),
      onTap: onPressed,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              showSchematic
                  ? Icons.map_outlined
                  : Icons.grid_on_rounded,
              size: 13.sp,
            ),
            SizedBox(width: 5.w),
            Text(
              showSchematic ? 'Street map' : 'Offline diagram',
              style: context.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 10.sp,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _LandmarkCard extends StatelessWidget {
  final int index;
  final LandmarkModel landmark;
  final bool isExpanded;
  final VoidCallback onTap;

  const _LandmarkCard({
    required this.index,
    required this.landmark,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      margin: EdgeInsets.only(bottom: 11.h),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isExpanded
              ? scheme.primary.withValues(alpha: 0.55)
              : scheme.outlineVariant.withValues(alpha: 0.5),
          width: 1.w,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(14.r),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(13.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: 22.w,
                      height: 22.w,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(7.r),
                      ),
                      child: Text(
                        '$index',
                        style: context.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.primary,
                        ),
                      ),
                    ),
                    SizedBox(width: 9.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            landmark.name,
                            style: context.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 3.h),
                          Wrap(
                            spacing: 5.w,
                            runSpacing: 4.h,
                            children: <Widget>[
                              StatusPill(
                                label: landmark.city.toUpperCase(),
                                icon: Icons.location_on_outlined,
                                color: scheme.primary,
                              ),
                              StatusPill(
                                label: landmark.categoryLabel.toUpperCase(),
                                color: scheme.onSurfaceVariant,
                                filled: false,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isExpanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      size: 18.sp,
                      color: scheme.onSurfaceVariant,
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                Text(
                  landmark.whyVisit,
                  style: context.textTheme.bodyMedium?.copyWith(
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (isExpanded) ...<Widget>[
                  SizedBox(height: 11.h),
                  Divider(
                    height: 1,
                    color: scheme.outlineVariant.withValues(alpha: 0.6),
                  ),
                  SizedBox(height: 9.h),
                  Text(
                    landmark.description,
                    style: context.textTheme.bodyMedium?.copyWith(
                      height: 1.45,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  if (landmark.bestTime.isNotEmpty)
                    StatTile(
                      icon: Icons.schedule_rounded,
                      label: 'Best time',
                      value: landmark.bestTime,
                    ),
                  if (landmark.entryFee.isNotEmpty)
                    StatTile(
                      icon: Icons.confirmation_number_outlined,
                      label: 'Entry',
                      value: landmark.entryFee,
                    ),
                  StatTile(
                    icon: Icons.my_location_rounded,
                    label: 'Coordinates',
                    value:
                        '${landmark.latitude.toStringAsFixed(4)}, '
                        '${landmark.longitude.toStringAsFixed(4)}',
                  ),
                  if (landmark.tip.isNotEmpty) ...<Widget>[
                    SizedBox(height: 8.h),
                    SectionCard(
                      title: 'Insider tip',
                      icon: Icons.lightbulb_outline_rounded,
                      padding: EdgeInsets.all(10.w),
                      children: <Widget>[
                        Text(
                          landmark.tip,
                          style: context.textTheme.bodyMedium?.copyWith(
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
