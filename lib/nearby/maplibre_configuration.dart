/// Public map style configuration only. Never use a server-side API key.
class MapLibreConfiguration {
  static const style = String.fromEnvironment('CARE360_MAP_STYLE_URL');
  static const attribution = String.fromEnvironment('CARE360_MAP_ATTRIBUTION');
  static bool get enabled => isValid(style, attribution);

  static bool isValid(String style, String attribution) {
    final uri = Uri.tryParse(style);
    return uri != null &&
        uri.scheme == 'https' &&
        uri.host.isNotEmpty &&
        uri.userInfo.isEmpty &&
        attribution.trim().isNotEmpty;
  }
}
