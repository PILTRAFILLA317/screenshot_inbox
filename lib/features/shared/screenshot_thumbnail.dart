import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenshot_inbox/app/providers.dart';

final class ScreenshotThumbnail extends ConsumerWidget {
  const ScreenshotThumbnail({
    required this.assetId,
    required this.semanticLabel,
    this.width = 64,
    this.height = 76,
    this.borderRadius = 10,
    super.key,
  });

  final String assetId;
  final String semanticLabel;
  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thumbnail = ref.watch(thumbnailProvider(assetId));
    return Semantics(
      image: true,
      label: semanticLabel,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: SizedBox(
          width: width,
          height: height,
          child: thumbnail.when(
            data: (bytes) => _image(bytes),
            error: (_, _) => const _UnavailableThumbnail(),
            loading: () => const ColoredBox(color: Color(0xFFEDEDED)),
          ),
        ),
      ),
    );
  }

  Widget _image(Uint8List? bytes) => bytes == null || bytes.isEmpty
      ? const _UnavailableThumbnail()
      : Image.memory(
          bytes,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          excludeFromSemantics: true,
          cacheWidth: width.isFinite ? (width * 3).round() : null,
        );
}

final class _UnavailableThumbnail extends StatelessWidget {
  const _UnavailableThumbnail();

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: Color(0xFFEDEDED),
    child: Center(child: Icon(Icons.image_not_supported_outlined, size: 22)),
  );
}
