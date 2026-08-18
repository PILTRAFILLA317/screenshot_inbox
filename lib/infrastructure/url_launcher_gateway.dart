import 'package:screenshot_inbox/domain/actions/action_gateways.dart';
import 'package:url_launcher/url_launcher.dart';

final class UrlLauncherGateway implements UrlGateway {
  const UrlLauncherGateway();

  @override
  Future<bool> openExternal(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);
}
