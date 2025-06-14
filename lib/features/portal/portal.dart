import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wagus/features/portal/bloc/portal_bloc.dart';
import 'package:wagus/routing/router.dart';
import 'package:wagus/services/user_service.dart';
import 'package:wagus/core/theme/app_palette.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class Portal extends HookWidget {
  const Portal({super.key});

  @override
  Widget build(BuildContext context) {
    final isLoading = useState(false);
    final errorMessage = useState<String?>(null);

    useEffect(() {
      final subscription = context.read<PortalBloc>().stream.listen((state) {
        final user = state.user;
        if (user != null || errorMessage.value != null) {
          isLoading.value = false;
        }
      });
      return subscription.cancel;
    }, []);

    return BlocListener<PortalBloc, PortalState>(
      listener: (context, state) async {
        final user = state.user;
        final hasWallets = user?.embeddedSolanaWallets.isNotEmpty ?? false;

        if (user != null && hasWallets) {
          await UserService()
              .setUserOnline(user.embeddedSolanaWallets.first.address);
          if (context.mounted) {
            context.go(home);
          }
        }
      },
      child: BlocBuilder<PortalBloc, PortalState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              children: [
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.1,
                    child: Image.asset(
                      'assets/icons/logo_text.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Welcome to WAGUS',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: context.appColors.contrastLight,
                          ),
                        ),
                        const SizedBox(height: 24),
                        GestureDetector(
                          onTap: isLoading.value
                              ? null
                              : () async {
                                  isLoading.value = true;
                                  errorMessage.value = null;

                                  context
                                      .read<PortalBloc>()
                                      .add(PortalAuthorizeEvent(context));
                                },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 14),
                            decoration: BoxDecoration(
                              color: state.tierStatus == TierStatus.adventurer
                                  ? TierStatus.adventurer.color
                                  : TierStatus.basic.color,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: isLoading.value
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.black,
                                    ),
                                  )
                                : Text(
                                    state.user?.embeddedSolanaWallets
                                                .isNotEmpty ??
                                            false
                                        ? '[ Enter WAGUS ]'
                                        : '[ Create Wallet ]',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                          ),
                        ),
                        if (errorMessage.value != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            errorMessage.value!,
                            style: const TextStyle(
                                color: Colors.redAccent, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 16),
                        Text(
                          'Current Tier: ${state.tierStatus.name}',
                          style: TextStyle(
                            fontSize: 14,
                            color: context.appColors.contrastLight,
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
