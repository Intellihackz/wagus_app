import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:wagus/core/theme/app_palette.dart';
import 'package:wagus/features/home/domain/message.dart' show Message;
import 'package:wagus/features/portal/bloc/portal_bloc.dart';

class ProfilePopupView extends StatelessWidget {
  const ProfilePopupView(
      {super.key, required this.message, required this.portalState});

  final Message message;
  final PortalState portalState;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.black,
      title: Text('Wallet Address',
          style: TextStyle(color: context.appColors.contrastLight)),
      content: Row(
        children: [
          GestureDetector(
            onTap: () => context.push('/profile/${message.sender}'),
            child: Container(
              margin: const EdgeInsets.only(
                right: 16.0,
              ),
              padding: const EdgeInsets.all(2.5), // border thickness
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: portalState.tierStatus == TierStatus.adventurer
                      ? TierStatus.adventurer.color
                      : TierStatus.basic.color,
                  width: 3, // thick border
                ),
              ),
              child: Hero(
                tag: 'profile',
                child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(message.sender)
                      .get(),
                  builder: (context, initialSnapshot) {
                    final initialData = initialSnapshot.data?.data();

                    return StreamBuilder<
                        DocumentSnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(message.sender)
                          .snapshots(),
                      builder: (context, liveSnapshot) {
                        final liveData = liveSnapshot.data?.data();
                        final imageUrl =
                            liveData?['image_url'] ?? initialData?['image_url'];

                        return CircleAvatar(
                          key: ValueKey(imageUrl),
                          radius: 14,
                          backgroundImage: imageUrl != null
                              ? CachedNetworkImageProvider(imageUrl)
                              : const AssetImage('assets/icons/avatar.png')
                                  as ImageProvider,
                          backgroundColor: Colors.transparent,
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
          SelectableText(
            (message.username?.trim().isNotEmpty ?? false)
                ? message.username!
                : '${message.sender.substring(0, 4)}...${message.sender.substring(message.sender.length - 4)}',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: message.sender));
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Copied to clipboard')),
            );
          },
          child: Text('COPY',
              style: TextStyle(
                  color: portalState.tierStatus == TierStatus.adventurer
                      ? Colors.red
                      : Colors.white)),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('CLOSE', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
