import 'package:map_launcher/map_launcher.dart';
import 'package:screenshot_inbox/domain/actions/action_gateways.dart';

final class MapLauncherGateway implements MapsGateway {
  const MapLauncherGateway();

  @override
  Future<void> openPlace({
    String? query,
    double? latitude,
    double? longitude,
    String? title,
  }) async {
    final hasCoordinates = latitude != null && longitude != null;
    if (!hasCoordinates && (query == null || query.trim().isEmpty)) {
      throw ArgumentError('A place query or coordinates are required.');
    }
    final location = hasCoordinates
        ? LocationCoords(latitude, longitude, title: title)
        : LocationSearch(query!.trim());
    await MapLauncher.marker(location).show();
  }
}
