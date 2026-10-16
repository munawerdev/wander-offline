import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';

/// OpenStreetMap tile provider that keeps every tile it fetches on disk.
///
/// `cached_network_image` already ships a disk cache, so tiles seen while online
/// survive into airplane mode and the map degrades gracefully instead of going
/// blank. Tiles that were never fetched obviously cannot be conjured up offline,
/// which is exactly why the pack also offers a schematic map that needs no tiles
/// at all.
///
/// Bulk pre-downloading OSM tiles is prohibited by the OSM tile usage policy, so
/// opportunistic caching is the correct trade-off for a shipping app rather than
/// a "download this region" button.
class CachedTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      CachedNetworkImageProvider(
        getTileUrl(coordinates, options),
        // Forwards the User-Agent that TileLayer injects, which OSM's usage
        // policy requires for identifiable traffic.
        headers: headers,
      );
}
