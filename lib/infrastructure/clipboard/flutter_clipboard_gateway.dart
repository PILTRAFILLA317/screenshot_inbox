import 'package:flutter/services.dart';
import 'package:screenshot_inbox/domain/actions/action_gateways.dart';

final class FlutterClipboardGateway implements ClipboardGateway {
  const FlutterClipboardGateway();

  @override
  Future<void> copyText(String text) =>
      Clipboard.setData(ClipboardData(text: text));
}
