import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wagus/core/theme/app_palette.dart';
import 'package:wagus/features/bank/data/bank_repository.dart';
import 'package:wagus/features/portal/bloc/portal_bloc.dart';
import 'package:wagus/routing/router.dart';

class WarningModal extends StatelessWidget {
  const WarningModal({super.key});

  @override
  Widget build(BuildContext context) {
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
            final userId = context.read<PortalBloc>().state.user?.id;

            if (userId == null) {
              context.pop();
              return;
            }

            try {
              await context.read<BankRepository>().deleteUser(userId);

              if (context.mounted) {
                context.read<PortalBloc>().add(PortalClearEvent());
                context.pushReplacement(login);
              }
            } on Exception catch (e, _) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Error deleting account. Please try again.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              if (context.mounted && context.canPop()) {
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
  }
}
