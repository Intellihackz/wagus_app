// Redesign of the Incubator widget to match sleek, mysterious chat UI
// Focuses on spacing, dark mode tones, smooth tiles, and subtle neon effects

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:wagus/features/incubator/bloc/incubator_bloc.dart';
import 'package:wagus/features/incubator/data/incubator_repository.dart';
import 'package:wagus/features/incubator/domain/project.dart';
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

    return BlocSelector<PortalBloc, PortalState, TierStatus>(
      selector: (state) {
        return state.tierStatus;
      },
      builder: (context, tierStatus) {
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
                        Visibility(
                          visible: false,
                          child: IconButton(
                            icon: Icon(Icons.add,
                                color: tierStatus == TierStatus.adventurer
                                    ? TierStatus.adventurer.color
                                    : TierStatus.basic.color),
                            onPressed: () {
                              context.push(projectInterface);
                            },
                          ),
                        )
                      ],
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.projects.length,
                        itemBuilder: (context, index) {
                          final project = state.projects[index];
                          final isLaunched =
                              DateTime.now().isAfter(project.launchDate);

                          final isLiked =
                              state.likedProjectsIds.contains(project.id);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey[900],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isLiked
                                    ? (tierStatus == TierStatus.adventurer
                                        ? TierStatus.adventurer.color
                                        : TierStatus.basic.color)
                                    : Colors.grey[800]!,
                                width: 1,
                              ),
                              boxShadow: [
                                if (isLiked)
                                  BoxShadow(
                                    color: tierStatus == TierStatus.adventurer
                                        ? TierStatus.adventurer.color
                                            .withOpacity(0.3)
                                        : TierStatus.basic.color
                                            .withOpacity(0.3),
                                    blurRadius: 12,
                                    spreadRadius: 1,
                                  ),
                              ],
                            ),
                            child: ExpansionTile(
                              collapsedIconColor: Colors.white,
                              iconColor: tierStatus == TierStatus.adventurer
                                  ? TierStatus.adventurer.color
                                  : TierStatus.basic.color,
                              shape: const RoundedRectangleBorder(
                                side: BorderSide.none,
                              ),
                              title: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    flex: 1,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            project.name,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        if (isLaunched)
                                          Container(
                                            margin:
                                                const EdgeInsets.only(left: 8),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.green[700],
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: const Text(
                                              'Launched',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Row(
                                    children: [
                                      Text(
                                        '${project.likesCount} Like'
                                            .pluralize(project.likesCount),
                                        style: TextStyle(
                                            color:
                                                context.appColors.contrastLight,
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
                                    style:
                                        const TextStyle(color: Colors.white70)),
                                const SizedBox(height: 12),
                                if (project.spendingPlan != null &&
                                    project.spendingPlan!.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Spending Plan:',
                                    style: TextStyle(
                                        color: Colors.white70,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    project.spendingPlan!,
                                    style:
                                        const TextStyle(color: Colors.white60),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: [
                                    LinkTile(
                                      title: 'Website',
                                      icon: Icons.web,
                                      onTap: () async {
                                        if (await canLaunchUrlString(
                                            project.websiteLink)) {
                                          await launchUrlString(
                                            project.websiteLink,
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Could not launch website'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      },
                                      tierStatus: tierStatus,
                                    ),
                                    LinkTile(
                                      title: 'Socials',
                                      icon: FontAwesomeIcons.solidCircleUser,
                                      onTap: () async {
                                        if (await canLaunchUrlString(
                                            project.socialsLink)) {
                                          await launchUrlString(
                                            project.socialsLink,
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Could not launch socials'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      },
                                      tierStatus: tierStatus,
                                    ),
                                    LinkTile(
                                      title: 'Telegram',
                                      icon: FontAwesomeIcons.telegram,
                                      onTap: () async {
                                        if (await canLaunchUrlString(
                                            project.telegramLink)) {
                                          await launchUrlString(
                                            project.telegramLink,
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Could not launch telegram'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      },
                                      tierStatus: tierStatus,
                                    ),
                                    LinkTile(
                                      title: 'GitHub',
                                      icon: FontAwesomeIcons.github,
                                      onTap: () async {
                                        if (await canLaunchUrlString(
                                            project.gitHubLink)) {
                                          await launchUrlString(
                                              project.gitHubLink);
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Could not launch GitHub'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      },
                                      tierStatus: tierStatus,
                                    ),
                                    LinkTile(
                                      title: 'Whitepaper',
                                      icon: FontAwesomeIcons.sheetPlastic,
                                      onTap: () async {
                                        if (await canLaunchUrlString(
                                            project.whitePaperLink)) {
                                          await launchUrlString(
                                            project.whitePaperLink,
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Could not launch whitepaper'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      },
                                      tierStatus: tierStatus,
                                    ),
                                    LinkTile(
                                      title: 'Roadmap',
                                      icon: FontAwesomeIcons.road,
                                      onTap: () async {
                                        if (await canLaunchUrlString(
                                            project.roadmapLink)) {
                                          await launchUrlString(
                                            project.roadmapLink,
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Could not launch roadmap'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      },
                                      tierStatus: tierStatus,
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
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
                                      '${((project.totalFunded ?? 0) / 60 * 100).clamp(0, 100).toInt()}% funded',
                                      style: TextStyle(
                                          color: tierStatus ==
                                                  TierStatus.adventurer
                                              ? TierStatus.adventurer.color
                                                  .withOpacity(0.8)
                                              : TierStatus.basic.color
                                                  .withOpacity(0.8),
                                          fontSize: 12),
                                    )
                                  ],
                                ),
                                const SizedBox(height: 12),
                                LinearProgressIndicator(
                                  value: (project.totalFunded ?? 0) /
                                      project.maxAllocation,
                                  backgroundColor: Colors.grey[800],
                                  color: tierStatus == TierStatus.adventurer
                                      ? TierStatus.adventurer.color
                                      : TierStatus.basic.color,
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: [
                                    _contributionChip(
                                        context,
                                        project,
                                        1,
                                        amountController,
                                        tierStatus,
                                        isLaunched),
                                    _contributionChip(
                                        context,
                                        project,
                                        5,
                                        amountController,
                                        tierStatus,
                                        isLaunched),
                                    _contributionChip(
                                        context,
                                        project,
                                        10,
                                        amountController,
                                        tierStatus,
                                        isLaunched),
                                    _contributionChip(
                                        context,
                                        project,
                                        25,
                                        amountController,
                                        tierStatus,
                                        isLaunched),
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
      },
    );
  }

  Widget _contributionChip(
      BuildContext context,
      Project project,
      int amount,
      TextEditingController controller,
      TierStatus tierStatus,
      bool isLaunched) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: isLaunched
          ? null
          : () {
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
                          Future.delayed(const Duration(milliseconds: 1500),
                              () {
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
                          Future.delayed(const Duration(milliseconds: 1500),
                              () {
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
                          content = SizedBox(
                            height: 80,
                            child: Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  tierStatus == TierStatus.adventurer
                                      ? TierStatus.adventurer.color
                                      : TierStatus.basic.color,
                                ),
                              ),
                            ),
                          );
                        } else if (state.transactionStatus ==
                            IncubatorTransactionStatus.success) {
                          content = SizedBox(
                            height: 80,
                            child: Center(
                              child: Icon(Icons.check_circle,
                                  color: tierStatus == TierStatus.adventurer
                                      ? TierStatus.adventurer.color
                                      : TierStatus.basic.color,
                                  size: 48),
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
                            readOnly: true,
                            controller: controller,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Amount',
                              hintStyle: TextStyle(color: Colors.grey[600]),
                              enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                      color: tierStatus == TierStatus.adventurer
                                          ? TierStatus.adventurer.color
                                          : TierStatus.basic.color)),
                              focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                      color: tierStatus == TierStatus.adventurer
                                          ? TierStatus.adventurer.color
                                          : TierStatus.basic.color)),
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
                                        style:
                                            TextStyle(color: Colors.redAccent)),
                                  ),
                                  GestureDetector(
                                    onTap: () async {
                                      if ((project.totalFunded ?? 0) >=
                                          project.maxAllocation) {
                                        return;
                                      }

                                      final int? parsedAmount =
                                          int.tryParse(controller.text);
                                      if (parsedAmount != null &&
                                          parsedAmount > 0) {
                                        final userId = context
                                            .read<PortalBloc>()
                                            .state
                                            .user!
                                            .id;

                                        final currentTotal =
                                            project.totalFunded ?? 0;
                                        final maxCap = project.maxAllocation;

                                        if (currentTotal + parsedAmount >
                                            maxCap) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'This contribution exceeds the max funding cap.'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                          return;
                                        }

                                        final targetUsd = parsedAmount
                                            .toDouble(); // e.g. 60.0
                                        final tokenTicker = project
                                            .preferredTokenTicker
                                            .toLowerCase();
                                        final usdPerToken = await context
                                            .read<IncubatorRepository>()
                                            .getUsdPerToken(tokenTicker);

                                        final adjustedAmountInTokens =
                                            (targetUsd / usdPerToken).ceil();

                                        context
                                            .read<IncubatorBloc>()
                                            .add(IncubatorWithdrawEvent(
                                              projectId: project.id,
                                              userId: userId,
                                              amount: adjustedAmountInTokens,
                                              wallet: context
                                                  .read<PortalBloc>()
                                                  .state
                                                  .user!
                                                  .embeddedSolanaWallets
                                                  .first,
                                              tokenAddress:
                                                  project.preferredTokenAddress,
                                              tokenTicker:
                                                  project.preferredTokenTicker,
                                            ));
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content:
                                                Text('Enter a valid amount'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    },
                                    child: Text('Contribute',
                                        style: TextStyle(
                                            color: tierStatus ==
                                                    TierStatus.adventurer
                                                ? TierStatus.adventurer.color
                                                : TierStatus.basic.color,
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
          color: isLaunched ? Colors.grey[700] : Colors.black,
          border: Border.all(
              color: tierStatus == TierStatus.adventurer
                  ? TierStatus.adventurer.color
                  : TierStatus.basic.color),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              FontAwesomeIcons.dollarSign,
              size: 16,
              color: tierStatus == TierStatus.adventurer
                  ? TierStatus.adventurer.color
                  : TierStatus.basic.color,
            ),
            const SizedBox(width: 4),
            Text('$amount',
                style: TextStyle(
                    color: tierStatus == TierStatus.adventurer
                        ? TierStatus.adventurer.color
                        : TierStatus.basic.color,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class LinkTile extends StatelessWidget {
  const LinkTile({
    required this.title,
    required this.icon,
    required this.onTap,
    required this.tierStatus,
    super.key,
  });

  final String title;
  final IconData icon;
  final VoidCallback? onTap;
  final TierStatus tierStatus;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      splashColor: tierStatus == TierStatus.adventurer
          ? TierStatus.adventurer.color.withOpacity(0.2)
          : TierStatus.basic.color.withOpacity(0.2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
