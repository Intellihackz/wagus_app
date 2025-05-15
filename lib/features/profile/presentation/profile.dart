import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:privy_flutter/privy_flutter.dart';
import 'package:wagus/features/bank/data/bank_repository.dart';
import 'package:wagus/features/portal/bloc/portal_bloc.dart';
import 'package:wagus/router.dart';
import 'package:wagus/services/privy_service.dart';
import 'package:wagus/services/user_service.dart';
import 'package:wagus/theme/app_palette.dart';

class ProfileScreen extends StatelessWidget {
  final String address;
  const ProfileScreen({super.key, required this.address});

  @override
  Widget build(BuildContext context) {
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
                                      .holdersMap?[context
                                          .read<PortalBloc>()
                                          .state
                                          .selectedToken
                                          ?.ticker ??
                                      'WAGUS'];

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
}
