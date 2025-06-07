import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wagus/features/home/bloc/home_bloc.dart';
import 'package:wagus/features/home/widgets/chat_command_option.dart';

class CommandPopupView extends StatelessWidget {
  const CommandPopupView(
      {super.key, required this.homeState, required this.inputController});

  final HomeState homeState;
  final TextEditingController inputController;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 64,
      left: 16,
      child: Material(
        color: Colors.transparent,
        child: IntrinsicWidth(
          // ✅ This makes the width wrap content
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (homeState.recentCommand != null)
                  CommandOption(
                    label: homeState.recentCommand!,
                    onTap: () {
                      inputController.text = homeState.recentCommand!;
                      inputController.selection = TextSelection.fromPosition(
                        TextPosition(offset: inputController.text.length),
                      );
                      context
                          .read<HomeBloc>()
                          .add(HomeCommandPopupClosed()); // ✅ Close it
                    },
                  ),
                if (homeState.commandSearch != null &&
                    homeState.commandSearch != homeState.recentCommand)
                  CommandOption(
                    label: homeState.commandSearch!,
                    onTap: () {
                      inputController.text = homeState.commandSearch!;
                      inputController.selection = TextSelection.fromPosition(
                        TextPosition(offset: inputController.text.length),
                      );
                      context
                          .read<HomeBloc>()
                          .add(HomeCommandPopupClosed()); // ✅ Close it
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
