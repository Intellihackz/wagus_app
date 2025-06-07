import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:privy_flutter/privy_flutter.dart';
import 'package:wagus/features/portal/bloc/portal_bloc.dart';
import 'package:wagus/features/profile/domain/faq_items.dart';
import 'package:wagus/features/profile/presentation/allocation_bar.dart';
import 'package:wagus/features/profile/presentation/delete_modal.dart';
import 'package:wagus/features/profile/presentation/profile_header.dart';
import 'package:wagus/routing/router.dart';
import 'package:wagus/services/privy_service.dart';
import 'package:wagus/services/user_service.dart';

class ProfileScreen extends HookWidget {
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
                ProfileHeader(address: address, isCurrentUser: isCurrentUser),
                if (isCurrentUser) AllocationBar(isCurrentUser: isCurrentUser),
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
                          return const DeleteModal();
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

  void showFaqBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          minChildSize: 0.3,
          builder: (context, scrollController) => ListView.builder(
            controller: scrollController,
            itemCount: faqItems.length + 1,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
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
                data: ThemeData().copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
