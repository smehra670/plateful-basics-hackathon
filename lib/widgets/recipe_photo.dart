import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_colors.dart';

class RecipePhoto extends StatelessWidget {
  const RecipePhoto({
    super.key,
    required this.url,
    this.asset,
    this.fit = BoxFit.cover,
  });

  factory RecipePhoto.of(Recipe recipe, {Key? key, BoxFit fit = BoxFit.cover}) {
    return RecipePhoto(
      key: key,
      url: recipe.imageUrl,
      asset: recipe.assetImage,
      fit: fit,
    );
  }

  final String url;
  final String? asset;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final bundled = (asset ?? '').trim();
    if (bundled.isNotEmpty) {
      return Image.asset(
        bundled,
        fit: fit,
        errorBuilder: (_, _, _) => _fallback(),
      );
    }
    final value = url.trim();
    if (value.startsWith('assets/')) {
      return Image.asset(
        value,
        fit: fit,
        errorBuilder: (_, _, _) => _fallback(),
      );
    }
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: value,
        fit: fit,
        placeholder: (_, _) => Container(color: AppColors.creamDark),
        errorWidget: (_, _, _) => _fallback(),
      );
    }
    if (value.isNotEmpty) {
      final file = File(value);
      if (file.existsSync()) {
        return Image.file(file, fit: fit);
      }
    }
    return _fallback();
  }

  Widget _fallback() => const ColoredBox(color: AppColors.imageBg);
}
