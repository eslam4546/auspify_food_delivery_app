import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:food_delivery_application/core/theme/app_colors.dart';
import 'package:shimmer/shimmer.dart';

/// Resilient network image widget pairing [CachedNetworkImage] with a
/// Shimmer loading placeholder and a Warm Courier branded fallback widget.
class ResilientNetworkImage extends StatelessWidget {
  const ResilientNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.fallbackIcon = Icons.restaurant_menu_rounded,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trimmed = imageUrl.trim();

    Widget child;
    if (trimmed.isEmpty) {
      child = _buildFallback(isDark);
    } else {
      child = CachedNetworkImage(
        imageUrl: trimmed,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => Shimmer.fromColors(
          baseColor: isDark
              ? AppColors.darkShimmerBase
              : AppColors.lightShimmerBase,
          highlightColor: isDark
              ? AppColors.darkShimmerHighlight
              : AppColors.lightShimmerHighlight,
          child: Container(
            width: width,
            height: height,
            color: isDark
                ? AppColors.darkShimmerBase
                : AppColors.lightShimmerBase,
          ),
        ),
        errorWidget: (context, url, error) => _buildFallback(isDark),
      );
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: child);
    }
    return child;
  }

  Widget _buildFallback(bool isDark) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF283548), Color(0xFF1E293B)]
              : const [Color(0xFFFFEFEA), Color(0xFFFFDAD3)],
        ),
      ),
      child: Center(
        child: Icon(
          fallbackIcon,
          size: (height != null && height! < 70) ? 24 : 34,
          color: AppColors.primary.withValues(alpha: isDark ? 0.85 : 0.75),
        ),
      ),
    );
  }
}
