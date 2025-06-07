import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wagus/features/portal/bloc/portal_bloc.dart';
import 'package:wagus/features/profile/presentation/badge_modal.dart';
import 'package:wagus/services/user_service.dart';

class ProfileHeader extends HookWidget {
  const ProfileHeader(
      {super.key, required this.address, required this.isCurrentUser});

  final String address;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    final usernameController = useTextEditingController();

    return Center(
      child: Column(
        children: [
          BlocSelector<PortalBloc, PortalState, TierStatus>(
            selector: (state) {
              return state.tierStatus;
            },
            builder: (context, tierStatus) {
              return Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: tierStatus == TierStatus.adventurer
                          ? TierStatus.adventurer.color
                          : TierStatus.basic.color,
                      width: 3),
                ),
                child: Hero(
                  tag: 'profile',
                  child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(address)
                        .get(),
                    builder: (context, initialSnapshot) {
                      final initialData = initialSnapshot.data?.data();

                      return StreamBuilder<
                          DocumentSnapshot<Map<String, dynamic>>>(
                        stream: UserService.getUserStream(address),
                        builder: (context, liveSnapshot) {
                          final liveData = liveSnapshot.data?.data();
                          final imageUrl = liveData?['image_url'] ??
                              initialData?['image_url'];

                          final avatar = CachedNetworkImage(
                            key: ValueKey(
                                imageUrl), // forces image refresh when changed
                            imageUrl: imageUrl ?? '',
                            imageBuilder: (context, provider) => CircleAvatar(
                              radius: 32,
                              backgroundImage: provider,
                              backgroundColor: Colors.transparent,
                            ),
                            placeholder: (context, url) => const CircleAvatar(
                              radius: 32,
                              backgroundImage:
                                  AssetImage('assets/icons/avatar.png'),
                              backgroundColor: Colors.transparent,
                            ),
                            errorWidget: (context, url, error) =>
                                const CircleAvatar(
                              radius: 32,
                              backgroundImage:
                                  AssetImage('assets/icons/avatar.png'),
                              backgroundColor: Colors.transparent,
                            ),
                          );

                          if (!isCurrentUser) return avatar;

                          return GestureDetector(
                            onTap: () async {
                              final picker = ImagePicker();
                              final picked = await picker.pickImage(
                                  source: ImageSource.gallery,
                                  imageQuality: 75);

                              if (picked != null) {
                                try {
                                  final ref = FirebaseStorage.instance
                                      .ref()
                                      .child('user_images')
                                      .child('$address.jpg');

                                  await ref.putData(await picked.readAsBytes());

                                  final url = await ref.getDownloadURL();

                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(address)
                                      .update({'image_url': url});
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('Failed to upload image')),
                                  );
                                }
                              }
                            },
                            child: avatar,
                          );
                        },
                      );
                    },
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          if (isCurrentUser)
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: UserService.getUserStream(address),
              builder: (context, snapshot) {
                final doc = snapshot.data?.data();
                final currentUsername = doc?['username'] ?? '';

                // Only set the controller text if it's different
                if (usernameController.text != currentUsername) {
                  usernameController.text = currentUsername;
                  usernameController.selection = TextSelection.fromPosition(
                    TextPosition(offset: currentUsername.length),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    children: [
                      Center(
                        child: SizedBox(
                          width: 220, // adjust as needed
                          child: TextField(
                            controller: usernameController,
                            maxLength: 8,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: '[ USERNAME ]',
                              labelStyle:
                                  const TextStyle(color: Colors.white70),
                              counterStyle:
                                  const TextStyle(color: Colors.white30),
                              enabledBorder: OutlineInputBorder(
                                borderSide:
                                    const BorderSide(color: Colors.white24),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide:
                                    const BorderSide(color: Colors.white70),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onSubmitted: (value) async {
                              final trimmed = value.trim().toLowerCase();

                              if (trimmed.isEmpty) {
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(address)
                                    .update({
                                  'username': FieldValue.delete(),
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text("Username cleared")),
                                );
                                return;
                              }

                              final isValid =
                                  RegExp(r'^[a-z0-9_]{3,8}$').hasMatch(trimmed);
                              if (!isValid) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text("Invalid username format")),
                                );
                                return;
                              }

                              // Check if username is already taken
                              final existing = await FirebaseFirestore.instance
                                  .collection('users')
                                  .where('username', isEqualTo: trimmed)
                                  .limit(1)
                                  .get();

                              if (existing.docs.isNotEmpty &&
                                  existing.docs.first.id != address) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text("Username already taken")),
                                );
                                return;
                              }

                              try {
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(address)
                                    .update({
                                  'username': trimmed,
                                });

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text("Username updated")),
                                );
                              } catch (_) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text("Failed to update username")),
                                );
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                );
              },
            )
          else
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: UserService.getUserStream(address),
              builder: (context, snapshot) {
                final username = snapshot.data?.data()?['username'] ?? '';
                if (username.isEmpty) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  child: Text(
                    username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              Clipboard.setData(ClipboardData(text: address));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Wallet address copied')),
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white12),
              ),
              child: SelectableText(
                address,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontFamily: 'Courier',
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text(
                'Badges',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (isCurrentUser)
                FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(address)
                      .get(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox();

                    final data = snapshot.data!.data();
                    final badgeIds = (data?['badges'] ?? []) as List<dynamic>;
                    if (badgeIds.isEmpty) return const SizedBox();

                    return FutureBuilder<
                        List<DocumentSnapshot<Map<String, dynamic>>>>(
                      future: Future.wait(
                        badgeIds.map((id) => FirebaseFirestore.instance
                            .collection('badges')
                            .doc(id)
                            .get()),
                      ),
                      builder: (context, badgeSnapshot) {
                        if (!badgeSnapshot.hasData) return const SizedBox();

                        final badgeDocs = badgeSnapshot.data!;
                        final badgeImages = badgeDocs
                            .map((doc) => doc.data()?['imageUrl'] as String?)
                            .where((url) => url != null && url.isNotEmpty)
                            .toList();

                        return Row(
                          children: badgeImages.map((imageUrl) {
                            return Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  image: DecorationImage(
                                    image:
                                        CachedNetworkImageProvider(imageUrl!),
                                    fit: BoxFit.cover,
                                  ),
                                  border: Border.all(
                                    color:
                                        const Color.fromARGB(255, 56, 10, 10),
                                    width: 2,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    );
                  },
                ),
              const SizedBox(width: 12),
              if (isCurrentUser)
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        builder: (_) {
                          final portalState = context.read<PortalBloc>().state;

                          return BadgeModal(
                            wallet:
                                portalState.user!.embeddedSolanaWallets.first,
                            mint: portalState.selectedToken.address,
                          );
                        });
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.deepPurpleAccent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
