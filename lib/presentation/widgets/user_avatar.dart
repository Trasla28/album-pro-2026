import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double size;

  const UserAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryLight,
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl != null
          ? CachedNetworkImage(
              imageUrl: imageUrl!,
              fit: BoxFit.cover,
              placeholder: (_, __) => _initials,
              errorWidget: (_, __, ___) => _initials,
            )
          : _initials,
    );
  }

  Widget get _initials => Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            color: AppColors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}
