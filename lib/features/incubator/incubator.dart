// Redesign of the Incubator widget to match sleek, mysterious chat UI
// Focuses on spacing, dark mode tones, smooth tiles, and subtle neon effects

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wagus/features/incubator/bloc/incubator_bloc.dart';
import 'package:wagus/features/incubator/data/incubator_repository.dart';
import 'package:wagus/features/portal/bloc/portal_bloc.dart';
import 'package:wagus/router.dart';
import 'package:date_format/date_format.dart';
import 'package:wagus/theme/app_palette.dart';
import 'package:wagus/utils.dart';

class Incubator extends HookWidget {
  const Incubator({super.key});

  @override
  Widget build(BuildContext context) {
    final amountController = useTextEditingController();

    useEffect(() {
      final userId = context.read<PortalBloc>().state.user!.id;
      context.read<IncubatorBloc>().add(IncubatorInitialEvent(userId: userId));
      context
          .read<IncubatorBloc>()
          .add(IncubatorFindLikedProjectsEvent(userId: userId));
      return null;
    }, []);

    return BlocConsumer<IncubatorBloc, IncubatorState>(
      listener: (context, state) async {
        if (state.transactionStatus == IncubatorTransactionStatus.failure) {
          await Future.delayed(Duration(milliseconds: 500));

          if (context.mounted) {
            context
                .read<IncubatorBloc>()
                .add(IncubatorResetTransactionStatusEvent());

            if (context.canPop()) {
              context.pop();
            }
          }
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: Padding(
            padding: const EdgeInsets.only(top: 64.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 16.0),
                      child: Text(
                        'Incubator',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, color: Colors.greenAccent),
                      onPressed: () {
                        context.push(projectInterface);
                      },
                    )
                  ],
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.projects.length,
                    itemBuilder: (context, index) {
                      final project = state.projects[index];
                      final isLiked =
                          state.likedProjectsIds.contains(project.id);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isLiked
                                ? Colors.greenAccent
                                : Colors.grey[800]!,
                            width: 1,
                          ),
                        ),
                        child: ExpansionTile(
                          collapsedIconColor: Colors.white,
                          iconColor: Colors.greenAccent,
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(project.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white)),
                              ),
                              Row(
                                children: [
                                  Text(
                                    '${project.likesCount} Like'
                                        .pluralize(project.likesCount),
                                    style: TextStyle(
                                        color: context.appColors.contrastLight,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () {
                                      final userId = context
                                          .read<PortalBloc>()
                                          .state
                                          .user!
                                          .id;
                                      if (isLiked) {
                                        context.read<IncubatorBloc>().add(
                                            IncubatorProjectUnlikeEvent(
                                                project.id, userId));
                                      } else {
                                        context.read<IncubatorBloc>().add(
                                            IncubatorProjectLikeEvent(
                                                project.id, userId));
                                      }
                                    },
                                    child: Icon(
                                      isLiked
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: isLiked
                                          ? Colors.redAccent
                                          : Colors.white,
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                          childrenPadding: const EdgeInsets.all(12),
                          children: [
                            Text(project.description,
                                style: const TextStyle(color: Colors.white70)),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Launch: ${formatDate(project.launchDate, [
                                        M,
                                        ' ',
                                        d,
                                        ', ',
                                        yyyy
                                      ])}',
                                  style: const TextStyle(
                                      color: Colors.white54, fontSize: 12),
                                ),
                                Text(
                                  '${(project.fundingProgress * 100).toInt()}% funded',
                                  style: const TextStyle(
                                      color: Colors.greenAccent, fontSize: 12),
                                )
                              ],
                            ),
                            const SizedBox(height: 12),
                            LinearProgressIndicator(
                              value: project.fundingProgress,
                              backgroundColor: Colors.grey[800],
                              color: Colors.greenAccent,
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                _contributionChip(
                                    context, project, 100, amountController),
                                _contributionChip(
                                    context, project, 250, amountController),
                                _contributionChip(
                                    context, project, 500, amountController),
                                _contributionChip(
                                    context, project, 1000, amountController),
                              ],
                            )
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _contributionChip(BuildContext context, project, int amount,
      TextEditingController controller) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        controller.text = amount.toString();
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            return BlocProvider.value(
              value: context.read<IncubatorBloc>(),
              child: BlocBuilder<IncubatorBloc, IncubatorState>(
                builder: (context, state) {
                  if (state.transactionStatus ==
                      IncubatorTransactionStatus.success) {
                    Future.delayed(const Duration(milliseconds: 1500), () {
                      if (context.mounted && Navigator.canPop(context)) {
                        Navigator.pop(context);
                        context
                            .read<IncubatorBloc>()
                            .add(IncubatorResetTransactionStatusEvent());
                      }
                    });
                  }

                  if (state.transactionStatus ==
                      IncubatorTransactionStatus.failure) {
                    Future.delayed(const Duration(milliseconds: 1500), () {
                      if (context.mounted && Navigator.canPop(context)) {
                        Navigator.pop(context);
                        context
                            .read<IncubatorBloc>()
                            .add(IncubatorResetTransactionStatusEvent());
                      }
                    });
                  }

                  Widget content;
                  if (state.transactionStatus ==
                      IncubatorTransactionStatus.submitting) {
                    content = const SizedBox(
                      height: 80,
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                        ),
                      ),
                    );
                  } else if (state.transactionStatus ==
                      IncubatorTransactionStatus.success) {
                    content = const SizedBox(
                      height: 80,
                      child: Center(
                        child: Icon(Icons.check_circle,
                            color: Colors.greenAccent, size: 48),
                      ),
                    );
                  } else if (state.transactionStatus ==
                      IncubatorTransactionStatus.failure) {
                    content = const SizedBox(
                      height: 80,
                      child: Center(
                        child: Icon(Icons.cancel,
                            color: Colors.redAccent, size: 48),
                      ),
                    );
                  } else {
                    content = TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Amount',
                        hintStyle: TextStyle(color: Colors.grey[600]),
                        enabledBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.greenAccent)),
                        focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.greenAccent)),
                      ),
                    );
                  }

                  return AlertDialog(
                    backgroundColor: context.appColors.contrastDark,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    title: Text('Contribute to ${project.name}',
                        style: const TextStyle(color: Colors.white)),
                    content: content,
                    actions: (state.transactionStatus ==
                            IncubatorTransactionStatus.initial)
                        ? [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel',
                                  style: TextStyle(color: Colors.redAccent)),
                            ),
                            GestureDetector(
                              onTap: () {
                                if ((project.totalFunded ?? 0) >=
                                    IncubatorRepository.totalTokenAllocation) {
                                  return;
                                }

                                final int? parsedAmount =
                                    int.tryParse(controller.text);
                                if (parsedAmount != null && parsedAmount > 0) {
                                  final userId =
                                      context.read<PortalBloc>().state.user!.id;

                                  final currentTotal = project.totalFunded ?? 0;
                                  final maxCap =
                                      IncubatorRepository.totalTokenAllocation;

                                  if (currentTotal + parsedAmount > maxCap) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'This contribution exceeds the max funding cap.'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }
                                  context
                                      .read<IncubatorBloc>()
                                      .add(IncubatorWithdrawEvent(
                                        projectId: project.id,
                                        userId: userId,
                                        amount: parsedAmount,
                                        wallet: context
                                            .read<PortalBloc>()
                                            .state
                                            .user!
                                            .embeddedSolanaWallets
                                            .first,
                                        wagusMint: context
                                            .read<PortalBloc>()
                                            .state
                                            .currentTokenAddress,
                                      ));
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Enter a valid amount'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                              child: const Text('Contribute',
                                  style: TextStyle(
                                      color: Colors.greenAccent,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ]
                        : [],
                  );
                },
              ),
            );
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(color: Colors.greenAccent),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$amount',
                style: const TextStyle(
                    color: Colors.greenAccent, fontWeight: FontWeight.bold)),
            const SizedBox(width: 4),
            Image.asset('assets/icons/logo.png',
                width: 16, height: 16, color: Colors.greenAccent),
          ],
        ),
      ),
    );
  }
}
