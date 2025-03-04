import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wagus/features/portal/bloc/portal_bloc.dart';
import 'package:wagus/features/portal/data/portal_repository.dart';
import 'package:wagus/router.dart';
import 'package:wagus/services/privy_service.dart';
import 'package:wagus/theme/app_palette.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class Portal extends HookWidget {
  const Portal({super.key});

  @override
  Widget build(BuildContext context) {
    final isLoading = useState(false);
    final errorMessage = useState<String?>(null);

    // Check if user is authenticated
    if (!PrivyService().isAuthenticated() && context.mounted) {
      context.go(login);
    }

    return RepositoryProvider(
      create: (context) => PortalRepository(),
      child: BlocBuilder<PortalBloc, PortalState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: context.appColors.contrastDark,
            body: Stack(
              children: [
                Image.asset(
                  'assets/background/logo.png',
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
                          child: isLoading.value
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: context.appColors.contrastLight,
                                  ),
                                )
                              : Text(
                                  '[ Connect Wallet ]',
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
                    ],
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
