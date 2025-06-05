import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:privy_flutter/privy_flutter.dart';
import 'package:wagus/features/bank/data/bank_repository.dart';
import 'package:wagus/features/portal/bloc/portal_bloc.dart';
import 'package:wagus/features/profile/presentation/badge_modal.dart';
import 'package:wagus/routing/router.dart';
import 'package:wagus/services/privy_service.dart';
import 'package:wagus/services/user_service.dart';
import 'package:wagus/core/theme/app_palette.dart';

class ProfileScreen extends HookWidget {
  final String address;
  const ProfileScreen({super.key, required this.address});

  @override
  Widget build(BuildContext context) {
    final usernameController = useTextEditingController();

    return BlocSelector<PortalBloc, PortalState, PrivyUser?>(
      selector: (state) {
        return state.user;
      },
      builder: (context, user) {
        final isCurrentUser =
            user?.embeddedSolanaWallets.first.address == address;

        void showFaqBottomSheet(BuildContext context) {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.black,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (context) {
              final faqItems = <Map<String, String>>[
                {
                  'title': 'Can’t send tokens?',
                  'content': '- Session expired: log out and back in\n'
                      '- Not enough SOL for fees\n'
                      '- Need extra rent to create token account',
                },
                {
                  'title': 'Daily Claim Issues',
                  'content': '- Hold at least 1 WAGUS (subject to change)\n'
                      '- Claiming from same IP twice causes issues\n'
                      '- Must wait 24 hours between claims\n'
                      '- If you got free rent before, no more free rent again',
                },
                {
                  'title': 'Withdraw issues?',
                  'content':
                      'Same reasons as sending errors (session, sol, rent)',
                },
                {
                  'title': 'How to become red (Adventurer)?',
                  'content':
                      'Pay \$3.50 worth of any token of your choice — select it in the Bank screen.',
                },
                {
                  'title': 'What are the benefits of Adventurer Tier?',
                  'content':
                      'Adventurers get a red name, themed UI, meme coin analysis, better \$SOL/\$WAGUS rewards, early feature access, can host giveaways, create rooms, and gain more visibility. Basic users miss out.',
                },
                {
                  'title': 'Why doesn’t the price change constantly?',
                  'content':
                      'To keep things simple and stable, we manually set token prices for upgrades. This removes volatility and shows how stablecoin-like systems can work in a real app without needing constant price updates.',
                },
                {
                  'title': 'Can I export my keys?',
                  'content':
                      'Not yet. I need to upgrade to the Privy Pro plan for that. I’m on the Starter plan.',
                },
                {
                  'title': 'Is there a website?',
                  'content':
                      'Yes — it’s in development. It’ll offer similar features, even more that didn’t pass mobile app compliance.',
                },
                {
                  'title': 'Other Tips',
                  'content': 'Ensure your internet is stable.',
                },
              ];

              return DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.75,
                maxChildSize: 0.95,
                minChildSize: 0.3,
                builder: (context, scrollController) => ListView.builder(
                  controller: scrollController,
                  itemCount: faqItems.length + 1,
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      );
                    }

                    final faq = faqItems[index - 1];

                    return Theme(
                      data: ThemeData()
                          .copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        collapsedIconColor: Colors.white54,
                        iconColor: Colors.white,
                        title: Text(
                          faq['title']!,
                          style: const TextStyle(color: Colors.white),
                        ),
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            alignment: Alignment.centerLeft,
                            child: Text(
                              faq['content']!,
                              style: const TextStyle(color: Colors.white70),
                            ),
                          )
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          );
        }

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            title: const Text('Profile', style: TextStyle(color: Colors.white)),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            behavior: HitTestBehavior.opaque,
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 32),
              children: [
                Center(
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
                              child: FutureBuilder<
                                  DocumentSnapshot<Map<String, dynamic>>>(
                                future: FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(address)
                                    .get(),
                                builder: (context, initialSnapshot) {
                                  final initialData =
                                      initialSnapshot.data?.data();

                                  return StreamBuilder<
                                      DocumentSnapshot<Map<String, dynamic>>>(
                                    stream: UserService.getUserStream(address),
                                    builder: (context, liveSnapshot) {
                                      final liveData =
                                          liveSnapshot.data?.data();
                                      final imageUrl = liveData?['image_url'] ??
                                          initialData?['image_url'];

                                      final avatar = CachedNetworkImage(
                                        key: ValueKey(
                                            imageUrl), // forces image refresh when changed
                                        imageUrl: imageUrl ?? '',
                                        imageBuilder: (context, provider) =>
                                            CircleAvatar(
                                          radius: 32,
                                          backgroundImage: provider,
                                          backgroundColor: Colors.transparent,
                                        ),
                                        placeholder: (context, url) =>
                                            const CircleAvatar(
                                          radius: 32,
                                          backgroundImage: AssetImage(
                                              'assets/icons/avatar.png'),
                                          backgroundColor: Colors.transparent,
                                        ),
                                        errorWidget: (context, url, error) =>
                                            const CircleAvatar(
                                          radius: 32,
                                          backgroundImage: AssetImage(
                                              'assets/icons/avatar.png'),
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
                                              final ref = FirebaseStorage
                                                  .instance
                                                  .ref()
                                                  .child('user_images')
                                                  .child('$address.jpg');

                                              await ref.putData(
                                                  await picked.readAsBytes());

                                              final url =
                                                  await ref.getDownloadURL();

                                              await FirebaseFirestore.instance
                                                  .collection('users')
                                                  .doc(address)
                                                  .update({'image_url': url});
                                            } catch (e) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                    content: Text(
                                                        'Failed to upload image')),
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
                              usernameController.selection =
                                  TextSelection.fromPosition(
                                TextPosition(offset: currentUsername.length),
                              );
                            }

                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 32.0),
                              child: Column(
                                children: [
                                  Center(
                                    child: SizedBox(
                                      width: 220, // adjust as needed
                                      child: TextField(
                                        controller: usernameController,
                                        maxLength: 8,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            color: Colors.white),
                                        decoration: InputDecoration(
                                          labelText: '[ USERNAME ]',
                                          labelStyle: const TextStyle(
                                              color: Colors.white70),
                                          counterStyle: const TextStyle(
                                              color: Colors.white30),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                                color: Colors.white24),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                                color: Colors.white70),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                        onSubmitted: (value) async {
                                          final trimmed =
                                              value.trim().toLowerCase();

                                          if (trimmed.isEmpty) {
                                            await FirebaseFirestore.instance
                                                .collection('users')
                                                .doc(address)
                                                .update({
                                              'username': FieldValue.delete(),
                                            });
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                  content:
                                                      Text("Username cleared")),
                                            );
                                            return;
                                          }

                                          final isValid =
                                              RegExp(r'^[a-z0-9_]{3,8}$')
                                                  .hasMatch(trimmed);
                                          if (!isValid) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                  content: Text(
                                                      "Invalid username format")),
                                            );
                                            return;
                                          }

                                          // Check if username is already taken
                                          final existing =
                                              await FirebaseFirestore.instance
                                                  .collection('users')
                                                  .where('username',
                                                      isEqualTo: trimmed)
                                                  .limit(1)
                                                  .get();

                                          if (existing.docs.isNotEmpty &&
                                              existing.docs.first.id !=
                                                  address) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                  content: Text(
                                                      "Username already taken")),
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

                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                  content:
                                                      Text("Username updated")),
                                            );
                                          } catch (_) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                  content: Text(
                                                      "Failed to update username")),
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
                            final username =
                                snapshot.data?.data()?['username'] ?? '';
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
                            const SnackBar(
                                content: Text('Wallet address copied')),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 32),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
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
                            FutureBuilder<
                                DocumentSnapshot<Map<String, dynamic>>>(
                              future: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(address)
                                  .get(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) return const SizedBox();

                                final data = snapshot.data!.data();
                                final badgeIds =
                                    (data?['badges'] ?? []) as List<dynamic>;
                                if (badgeIds.isEmpty) return const SizedBox();

                                return FutureBuilder<
                                    List<
                                        DocumentSnapshot<
                                            Map<String, dynamic>>>>(
                                  future: Future.wait(
                                    badgeIds.map((id) => FirebaseFirestore
                                        .instance
                                        .collection('badges')
                                        .doc(id)
                                        .get()),
                                  ),
                                  builder: (context, badgeSnapshot) {
                                    if (!badgeSnapshot.hasData)
                                      return const SizedBox();

                                    final badgeDocs = badgeSnapshot.data!;
                                    final badgeImages = badgeDocs
                                        .map((doc) =>
                                            doc.data()?['imageUrl'] as String?)
                                        .where((url) =>
                                            url != null && url.isNotEmpty)
                                        .toList();

                                    return Row(
                                      children: badgeImages.map((imageUrl) {
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(left: 8),
                                          child: Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              image: DecorationImage(
                                                image:
                                                    CachedNetworkImageProvider(
                                                        imageUrl!),
                                                fit: BoxFit.cover,
                                              ),
                                              border: Border.all(
                                                color: const Color.fromARGB(
                                                    255, 56, 10, 10),
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
                                      borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(24)),
                                    ),
                                    builder: (_) {
                                      final portalState =
                                          context.read<PortalBloc>().state;

                                      return BadgeModal(
                                        wallet: portalState
                                            .user!.embeddedSolanaWallets.first,
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
                                child:
                                    const Icon(Icons.add, color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isCurrentUser)
                  _buildAllocationBar(context, isCurrentUser: isCurrentUser),
                const SizedBox(height: 32),
                if (isCurrentUser) ...[
                  _buildSectionTitle('Account'),
                  _buildTile(
                    icon: FontAwesomeIcons.question,
                    label: 'FAQ',
                    onTap: () => showFaqBottomSheet(context),
                  ),
                  BlocSelector<PortalBloc, PortalState, String>(
                    selector: (state) {
                      return state.user?.embeddedSolanaWallets.first.address ??
                          '';
                    },
                    builder: (context, address) {
                      return _buildTile(
                        icon: Icons.logout,
                        label: 'Logout',
                        onTap: () async {
                          final result = await PrivyService().logout(context);

                          if (result && context.mounted) {
                            await UserService().setUserOffline(address);
                            context.go(login);
                          }
                        },
                      );
                    },
                  ),
                  _buildTile(
                    icon: Icons.delete_forever,
                    label: 'Delete Account',
                    onTap: () {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (dialogContext) {
                          return AlertDialog(
                            title: const Text(
                              'Delete Account',
                              style: TextStyle(
                                color: AppPalette.contrastDark,
                                fontSize: 12,
                              ),
                            ),
                            content: const Text(
                              'Are you sure you want to delete your account?',
                              style: TextStyle(
                                color: AppPalette.contrastDark,
                                fontSize: 12,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  context.pop();
                                },
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  // Workaround solution:
                                  // I will check the balance of SOL and WAGUS

                                  // they should be both 0 because we dont want loss of funds
                                  final holder = context
                                          .read<PortalBloc>()
                                          .state
                                          .holdersMap?[
                                      context
                                          .read<PortalBloc>()
                                          .state
                                          .selectedToken
                                          .ticker];

                                  if (holder != null &&
                                      (holder.solanaAmount > 0 ||
                                          holder.tokenAmount > 0)) {
                                    // small alert dialog to warn them to withdraw funds before deleting

                                    showDialog(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          title: const Text(
                                            'Warning',
                                            style: TextStyle(
                                              color: AppPalette.contrastDark,
                                              fontSize: 12,
                                            ),
                                          ),
                                          content: const Text(
                                            'You have funds in your account. Please withdraw them before deleting your account.',
                                            style: TextStyle(
                                              color: AppPalette.contrastDark,
                                              fontSize: 12,
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () async {
                                                final userId = context
                                                    .read<PortalBloc>()
                                                    .state
                                                    .user
                                                    ?.id;

                                                if (userId == null) {
                                                  context.pop();
                                                  return;
                                                }

                                                try {
                                                  await context
                                                      .read<BankRepository>()
                                                      .deleteUser(userId);

                                                  if (context.mounted) {
                                                    context
                                                        .read<PortalBloc>()
                                                        .add(
                                                            PortalClearEvent());
                                                    context
                                                        .pushReplacement(login);
                                                  }
                                                } on Exception catch (e, _) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                          'Error deleting account. Please try again.'),
                                                      behavior: SnackBarBehavior
                                                          .floating,
                                                    ),
                                                  );
                                                  if (context.mounted &&
                                                      context.canPop()) {
                                                    context.pop();
                                                  }

                                                  return;
                                                }

                                                context.pop();
                                              },
                                              child: const Text('Proceed'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  } else {
                                    final userId = context
                                        .read<PortalBloc>()
                                        .state
                                        .user
                                        ?.id;

                                    if (userId == null) {
                                      context.pop();
                                      return;
                                    }

                                    try {
                                      await context
                                          .read<BankRepository>()
                                          .deleteUser(userId);

                                      if (context.mounted) {
                                        context
                                            .read<PortalBloc>()
                                            .add(PortalClearEvent());

                                        context.pushReplacement(login);
                                      }
                                    } on Exception catch (e, _) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Error deleting account. Please try again.'),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                      if (context.mounted && context.canPop()) {
                                        context.pop();
                                      }

                                      return;
                                    }

                                    context.pop();
                                  }
                                },
                                child: const Text('Delete'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    color: Colors.redAccent,
                  ),
                ]
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String text) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          text,
          style: const TextStyle(
              color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      );

  Widget _buildTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.white),
      title: Text(label, style: TextStyle(color: color ?? Colors.white)),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Widget _buildAllocationBar(BuildContext context,
      {required bool isCurrentUser}) {
    final holdersMap = context.read<PortalBloc>().state.holdersMap ?? {};

    if (isCurrentUser &&
        (context.read<PortalBloc>().state.holdersMap?.isEmpty ?? true)) {
      context.read<PortalBloc>().add(PortalListenSupportedTokensEvent());
    }

    if (holdersMap.isEmpty) return const SizedBox();

    print('the holders map is $holdersMap');

    final allocations = holdersMap.entries.map((e) {
      final token = e.key;
      final holder = e.value;
      return {
        'label': token,
        'value': holder.tokenAmount + holder.solanaAmount,
        'color': _colorForToken(token),
      };
    }).toList();

    final total =
        allocations.fold(0.0, (sum, item) => sum + (item['value'] as double));

    if (total == 0) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Wallet Allocation',
            style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 13),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: List.generate(allocations.length, (index) {
                final entry = allocations[index];
                final widthFactor = (entry['value'] as double) / total;

                return Expanded(
                  flex: (widthFactor * 1000).round(),
                  child: Container(
                    height: 16,
                    decoration: BoxDecoration(
                      color: entry['color'] as Color,
                      gradient: LinearGradient(
                        colors: [
                          (entry['color'] as Color).withOpacity(0.8),
                          (entry['color'] as Color).withOpacity(1.0),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: allocations.map((entry) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: entry['color'] as Color,
                      borderRadius: BorderRadius.circular(3), // Rounded corners
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "${entry['label']} ${(entry['value'] as double).toStringAsFixed(2)}",
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Color _colorForToken(String ticker) {
    switch (ticker.toUpperCase()) {
      case 'WAGUS':
        return const Color.fromARGB(255, 106, 185, 212); // Light blue
      case 'SUGAW':
        return const Color.fromARGB(255, 255, 0, 0); // Yellow
      case 'SOL':
        return const Color(0xFFFFA726); // Orange
      case 'LUX':
        return const Color.fromARGB(255, 154, 61, 61); // Teal
      case 'BONK':
        return const Color.fromARGB(255, 247, 255, 129); // Pink
      case 'BUCKAZOIDS':
        return const Color.fromARGB(255, 241, 176, 24); // Purple
      case 'PAWS':
        return const Color.fromARGB(255, 44, 44, 44); // Green
      case 'SAMU':
        return const Color.fromARGB(255, 243, 214, 171); // Red
      default:
        return const Color(0xFF757575); // Grey for unknowns
    }
  }
}
