import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

import '/config/map/tile_source.dart';
import '/config/theme/app_colors.dart';
import '/core/utils/extensions.dart';
import '/core/utils/geo_utils.dart';
import '/data/models/pack/landmark_model.dart';
import 'cached_tile_provider.dart';

/// Real OpenStreetMap view of a pack's landmarks.
///
/// Works online and reuses anything already in the tile cache offline. When the
/// device has never fetched the tiles it needs, the schematic map is the honest
/// fallback, so this widget is always offered alongside a way to switch.
class LandmarkMap extends StatelessWidget {
  final List<LandmarkModel> landmarks;
  final String? selectedLandmarkId;
  final ValueChanged<String> onSelectLandmark;

  const LandmarkMap({
    super.key,
    required this.landmarks,
    required this.onSelectLandmark,
    this.selectedLandmarkId,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final points = landmarks
        .where((LandmarkModel landmark) => landmark.hasCoordinates)
        .toList();

    if (points.isEmpty) {
      return const _MapPlaceholder(
        message: 'No coordinates saved for these places',
        icon: Icons.wrong_location_outlined,
      );
    }

    final bounds = GeoBounds.fromPoints(
      points
          .map(
            (LandmarkModel landmark) => GeoPoint(
              latitude: landmark.latitude,
              longitude: landmark.longitude,
            ),
          )
          .toList(),
    );

    return Container(
      color: scheme.surfaceContainerHighest,
      child: Stack(
        children: <Widget>[
          FlutterMap(
            options: MapOptions(
              initialCameraFit: CameraFit.bounds(
                bounds: LatLngBounds(
                  LatLng(bounds.minLatitude, bounds.minLongitude),
                  LatLng(bounds.maxLatitude, bounds.maxLongitude),
                ),
                padding: EdgeInsets.all(38.w),
                maxZoom: 12,
              ),
              minZoom: 1,
              maxZoom: 18,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: <Widget>[
              TileLayer(
                urlTemplate: MapTileSource.urlTemplate,
                userAgentPackageName: MapTileSource.userAgentPackageName,
                tileProvider: CachedTileProvider(),
              ),
              MarkerLayer(
                markers: points
                    .map((LandmarkModel landmark) => _pin(context, landmark))
                    .toList(),
              ),
            ],
          ),
          Positioned(left: 6.w, bottom: 5.h, child: const _OsmAttribution()),
        ],
      ),
    );
  }

  Marker _pin(BuildContext context, LandmarkModel landmark) {
    final isSelected = landmark.mapKey == selectedLandmarkId;
    final accent = isSelected ? AppColors.warning : context.colorScheme.primary;
    final size = isSelected ? 42.w : 32.w;

    return Marker(
      point: LatLng(landmark.latitude, landmark.longitude),
      width: size,
      height: size,
      child: GestureDetector(
        onTap: () => onSelectLandmark(landmark.mapKey),
        child: Tooltip(
          message: landmark.name,
          child: Container(
            decoration: BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5.w),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Icon(
              Icons.place_rounded,
              color: Colors.white,
              size: (isSelected ? 22 : 16).sp,
            ),
          ),
        ),
      ),
    );
  }
}

/// OSM's licence requires visible attribution wherever their tiles are drawn.
class _OsmAttribution extends StatelessWidget {
  const _OsmAttribution();

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
    decoration: BoxDecoration(
      color: context.colorScheme.surface.withValues(alpha: 0.82),
      borderRadius: BorderRadius.circular(4.r),
    ),
    child: Text(
      MapTileSource.attribution,
      style: context.textTheme.bodySmall?.copyWith(fontSize: 9.sp),
    ),
  );
}

class _MapPlaceholder extends StatelessWidget {
  final String message;
  final IconData icon;

  const _MapPlaceholder({required this.message, required this.icon});

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: context.colorScheme.surfaceContainerHighest,
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(icon, size: 28.sp, color: context.colorScheme.onSurfaceVariant),
          SizedBox(height: 6.h),
          Text(
            message,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ),
  );
}
