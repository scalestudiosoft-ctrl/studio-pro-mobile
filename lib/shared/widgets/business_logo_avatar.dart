import 'dart:io';

import 'package:flutter/material.dart';

class BusinessLogoAvatar extends StatelessWidget {
  const BusinessLogoAvatar({
    super.key,
    this.logoPath,
    this.radius = 26,
    this.iconSize,
    this.backgroundColor,
  });

  final String? logoPath;
  final double radius;
  final double? iconSize;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final resolvedLogoPath = (logoPath ?? '').trim();
    final hasLogo = resolvedLogoPath.isNotEmpty && File(resolvedLogoPath).existsSync();

    if (hasLogo) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.white,
        backgroundImage: FileImage(File(resolvedLogoPath)),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.primaryContainer,
      child: Icon(
        Icons.content_cut_rounded,
        size: iconSize ?? radius,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
