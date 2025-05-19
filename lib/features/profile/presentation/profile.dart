import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:privy_flutter/privy_flutter.dart';
import 'package:wagus/features/bank/data/bank_repository.dart';
import 'package:wagus/features/portal/bloc/portal_bloc.dart';
import 'package:wagus/router.dart';
import 'package:wagus/services/privy_service.dart';
import 'package:wagus/services/user_service.dart';
import 'package:wagus/theme/app_palette.dart';

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
                            child: const Hero(
                              tag: 'profile',
                              child: CircleAvatar(
                                radius: 32,
                                backgroundImage:
                                    AssetImage('assets/icons/avatar.png'),
                                backgroundColor: Colors.transparent,
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
                                          final trimmed = value.trim();
                                          if (trimmed.length > 8 ||
                                              trimmed.isEmpty) return;

                                          try {
                                            await UserService()
                                                .setUsername(address, trimmed);
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
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: AssetImage(
                                    'assets/icons/early.png'), // Replace this path
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isCurrentUser)
                  _buildAllocationBar(context, isCurrentUser: isCurrentUser),
                const SizedBox(height: 32),
                if (isCurrentUser) ...[
                  _buildSectionTitle('Account'),
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
        return const Color.fromARGB(255, 126, 129, 130); // Light blue
      case 'SOL':
        return const Color(0xFFFFA726); // Orange
      case 'LUX':
        return const Color.fromARGB(255, 155, 50, 50); // Teal
      case 'BONK':
        return const Color.fromARGB(255, 184, 195, 28); // Pink
      case 'BUCKAZOIDS':
        return const Color.fromARGB(255, 241, 176, 24); // Purple
      case 'PAWS':
        return const Color.fromARGB(255, 241, 248, 241); // Green
      default:
        return const Color(0xFF757575); // Grey for unknowns
    }
  }
}
