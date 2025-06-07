import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wagus/core/theme/app_palette.dart';
import 'package:wagus/features/bank/data/bank_repository.dart';
import 'package:wagus/features/portal/bloc/portal_bloc.dart';
import 'package:wagus/features/profile/presentation/warning_modal.dart';
import 'package:wagus/routing/router.dart';

Future<void> _deleteUser(context) async {
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
}

class DeleteModal extends StatelessWidget {
  const DeleteModal({super.key});

  @override
  Widget build(BuildContext context) {
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
            final holder = context.read<PortalBloc>().state.holdersMap?[
                context.read<PortalBloc>().state.selectedToken.ticker];

            if (holder != null &&
                (holder.solanaAmount > 0 || holder.tokenAmount > 0)) {
              showDialog(
                context: context,
                builder: (context) {
                  return const WarningModal();
                },
              );
            } else {
              _deleteUser(context);
            }
          },
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
