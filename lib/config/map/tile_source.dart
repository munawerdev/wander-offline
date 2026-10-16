/// Where the street-map tiles come from, in one place.
///
/// This is a deliberate product decision rather than a detail, which is why it
/// lives on its own instead of inline in the map widget.
///
/// The default is OpenStreetMap's public tile servers. They are free and need no
/// key, but the OSM Foundation's Tile Usage Policy requires identifiable traffic
/// (hence [userAgentPackageName]) and visible attribution (hence
/// [attribution]), and it does not permit bulk downloading. So the app caches
/// tiles opportunistically as you browse and never offers a "download this
/// region" button - which is exactly why the Places tab also has a tile-free
/// schematic diagram.
///
/// `flutter_map` prints an advisory about this in debug builds. It is
/// unconditional for OSM URLs; the two follow-up blocks (missing User-Agent,
/// subdomain use) are what indicate a misconfiguration, and this configuration
/// avoids both.
///
/// Before shipping to a wide audience, swap [urlTemplate] and [attribution] for
/// a provider whose terms fit your traffic - a commercial tile host or your own
/// cache. Nothing else in the app needs to change.
class MapTileSource {
  MapTileSource._();

  static const String urlTemplate =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  static const String attribution = '© OpenStreetMap contributors';

  /// Sent as the User-Agent so tile traffic is identifiable, as the OSM policy
  /// requires.
  static const String userAgentPackageName = 'com.wanderoffline.app';
}
