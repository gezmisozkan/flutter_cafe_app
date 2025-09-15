import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrBox extends StatelessWidget {
  const QrBox({super.key, required this.data, this.size = 180});

  final String data;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: QrImageView(data: data, version: QrVersions.auto, size: size),
      ),
    );
  }
}
