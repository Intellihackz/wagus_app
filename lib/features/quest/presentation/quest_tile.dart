import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:wagus/features/portal/bloc/portal_bloc.dart';

class QuestTile extends StatelessWidget {
  const QuestTile({
    required this.title,
    required this.onTap,
    required this.tierStatus,
    this.backgroundImgUrl,
    super.key,
  });

  final String title;
  final VoidCallback onTap;
  final TierStatus tierStatus;
  final String? backgroundImgUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: backgroundImgUrl == null
            ? (tierStatus == TierStatus.adventurer
                ? TierStatus.adventurer.color.withOpacity(0.1)
                : TierStatus.basic.color.withOpacity(0.1))
            : null,
        image: backgroundImgUrl != null
            ? DecorationImage(
                image: CachedNetworkImageProvider(backgroundImgUrl!),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.5),
                  BlendMode.darken,
                ),
              )
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onTap: onTap,
        title: Text(
          title,
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white),
      ),
    );
  }
}
