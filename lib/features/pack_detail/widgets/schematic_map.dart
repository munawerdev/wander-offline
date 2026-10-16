import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '/config/theme/app_colors.dart';
import '/core/utils/extensions.dart';
import '/core/utils/geo_utils.dart';
import '/data/models/pack/landmark_model.dart';

/// A tile-free map of a pack's landmarks.
///
/// This is the guaranteed-offline half of the places tab. Real coordinates are
/// projected into the pack's bounding box with an equirectangular projection
/// (see [projectToUnitSquare]) and drawn over a graticule, so there is no
/// network call, no tile cache to warm and nothing to pre-download: it works the
/// moment a pack is installed and keeps working in airplane mode.
///
/// It answers the question a traveller actually has offline - "how do these
/// places sit relative to each other, and which city am I closest to" - without
/// pretending to be street-level cartography.
class SchematicMap extends StatelessWidget {
  final List<LandmarkModel> landmarks;
  final String? selectedLandmarkId;
  final ValueChanged<String> onSelectLandmark;

  const SchematicMap({
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
      return ColoredBox(
        color: scheme.surfaceContainerHighest,
        child: Center(
          child: Text(
            'No coordinates saved for these places',
            style: context.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final bounds = GeoBounds.fromPoints(
      points.map(_geoPoint).toList(),
    );
    final pinSize = 26.w;
    final selected = _selectedLandmark(points);

    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: LayoutBuilder(
        builder: (context, constraints) => Stack(
          children: <Widget>[
            Positioned.fill(
              child: CustomPaint(
                painter: _GraticulePainter(
                  lineColor: scheme.outlineVariant.withValues(alpha: 0.7),
                  fillColor: scheme.surfaceContainerHighest,
                ),
              ),
            ),
            for (final landmark in points)
              _positionedPin(
                context: context,
                landmark: landmark,
                bounds: bounds,
                size: Size(constraints.maxWidth, constraints.maxHeight),
                pinSize: pinSize,
              ),
            if (selected != null)
              Positioned(
                top: 6.h,
                left: 10.w,
                right: 10.w,
                child: _SelectedLabel(landmark: selected),
              ),
            Positioned(
              right: 6.w,
              bottom: 4.h,
              child: Text(
                'Offline diagram · ${bounds.minLatitude.toStringAsFixed(2)}° to '
                '${bounds.maxLatitude.toStringAsFixed(2)}° N',
                style: context.textTheme.bodySmall?.copyWith(
                  fontSize: 8.5.sp,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  LandmarkModel? _selectedLandmark(List<LandmarkModel> points) {
    final id = selectedLandmarkId;
    if (id == null) return null;
    for (final landmark in points) {
      if (landmark.mapKey == id) return landmark;
    }
    return null;
  }

  Widget _positionedPin({
    required BuildContext context,
    required LandmarkModel landmark,
    required GeoBounds bounds,
    required Size size,
    required double pinSize,
  }) {
    final unit = projectToUnitSquare(_geoPoint(landmark), bounds);
    final isSelected = landmark.mapKey == selectedLandmarkId;
    final accent = isSelected ? AppColors.warning : context.colorScheme.primary;

    final left = (unit.dx * size.width - pinSize / 2).clamp(
      0.0,
      (size.width - pinSize).clamp(0.0, double.infinity),
    );
    final top = (unit.dy * size.height - pinSize / 2).clamp(
      0.0,
      (size.height - pinSize).clamp(0.0, double.infinity),
    );

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: () => onSelectLandmark(landmark.mapKey),
        child: Tooltip(
          message: '${landmark.name} · ${landmark.city}',
          child: Container(
            width: pinSize,
            height: pinSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.4.w),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 3,
                ),
              ],
            ),
            child: Icon(
              Icons.place_rounded,
              size: (isSelected ? 15 : 12).sp,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  static GeoPoint _geoPoint(LandmarkModel landmark) => GeoPoint(
    latitude: landmark.latitude,
    longitude: landmark.longitude,
  );
}

class _SelectedLabel extends StatelessWidget {
  final LandmarkModel landmark;

  const _SelectedLabel({required this.landmark});

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
    decoration: BoxDecoration(
      color: context.colorScheme.surface.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(9.r),
      border: Border.all(
        color: AppColors.warning.withValues(alpha: 0.6),
        width: 1.w,
      ),
    ),
    child: Text(
      '${landmark.name} · ${landmark.city}',
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: context.textTheme.bodySmall?.copyWith(
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

/// Draws the background graticule so the diagram reads as a map rather than a
/// scatter plot.
class _GraticulePainter extends CustomPainter {
  final Color lineColor;
  final Color fillColor;

  const _GraticulePainter({required this.lineColor, required this.fillColor});

  static const int _divisions = 4;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = fillColor);

    final line = Paint()
      ..color = lineColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (var index = 1; index < _divisions; index++) {
      final dx = size.width * index / _divisions;
      final dy = size.height * index / _divisions;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), line);
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), line);
    }

    // Frame the diagram a little heavier so the extents are obvious.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..color = lineColor
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_GraticulePainter oldDelegate) =>
      oldDelegate.lineColor != lineColor || oldDelegate.fillColor != fillColor;
}
