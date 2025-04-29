import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wagus/features/portal/bloc/portal_bloc.dart';
import 'package:wagus/features/portal/data/portal_repository.dart';
import 'package:wagus/router.dart';
import 'package:wagus/theme/app_palette.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class Portal extends HookWidget {
  const Portal({super.key});

  @override
  Widget build(BuildContext context) {
    final isLoading = useState(false);
    final errorMessage = useState<String?>(null);

    return RepositoryProvider(
      create: (context) => PortalRepository(),
      child: BlocListener<PortalBloc, PortalState>(
        listener: (context, state) {},
        child: BlocBuilder<PortalBloc, PortalState>(
          builder: (context, state) {
            return Scaffold(
              backgroundColor: context.appColors.contrastDark,
              body: Stack(
                children: [
                  Image.asset(
                    'assets/icons/logo_text.png',
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: isLoading.value
                              ? null
                              : () async {
                                  try {
                                    isLoading.value = true;
                                    errorMessage.value = null;

                                    context
                                        .read<PortalBloc>()
                                        .add(PortalAuthorizeEvent(context));

                                    // Wait a moment to ensure state updates
                                    await Future.delayed(
                                        const Duration(milliseconds: 300));

                                    final portalBlocState =
                                        context.read<PortalBloc>().state;
                                    final user = portalBlocState.user;
                                    final hasWallets = user
                                            ?.embeddedSolanaWallets
                                            .isNotEmpty ??
                                        false;

                                    if (user != null && hasWallets) {
                                      if (context.mounted) {
                                        context.go(
                                            home); // ✅ Navigate only if wallet exists
                                      }
                                    } else {
                                      errorMessage.value =
                                          'Please create a wallet first.';
                                    }
                                  } finally {
                                    isLoading.value = false;
                                  }
                                },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: context.appColors.contrastLight,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: isLoading.value || state.user == null
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: context.appColors.contrastLight,
                                    ),
                                  )
                                : Text(
                                    state.user?.embeddedSolanaWallets
                                                .isNotEmpty ??
                                            false
                                        ? '[ Enter WAGUS ]'
                                        : '[ Create Wallet ]',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: context.appColors.contrastLight,
                                    ),
                                  ),
                          ),
                        ),
                        if (errorMessage.value != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            errorMessage.value!,
                            style: TextStyle(
                              color: Colors.red[300],
                              fontSize: 14,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Text(
                          'Current Tier: ${state.tierStatus.name}',
                          style: TextStyle(
                            color: context.appColors.contrastLight,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
