import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cached_pdfview/flutter_cached_pdfview.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:wagus/features/incubator/bloc/incubator_bloc.dart';
import 'package:wagus/features/incubator/domain/project.dart';
import 'package:wagus/features/portal/bloc/portal_bloc.dart';
import 'package:wagus/router.dart';
import 'package:wagus/theme/app_palette.dart';

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
          floatingActionButton: FloatingActionButton(
            heroTag: 'addProject',
            backgroundColor: context.appColors.contrastLight,
            onPressed: () {
              context.push(projectInterface);
            },
            child: const Icon(Icons.playlist_add_rounded),
          ),
          body: SizedBox.expand(
            child: Padding(
              padding: const EdgeInsets.only(top: 100.0),
              child: Column(
                children: [
                  Text(
                    'Upcoming Projects',
                    style: TextStyle(
                      color: context.appColors.contrastLight,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32.0),
                  Expanded(
                    child: ListView.builder(
                      physics: const ClampingScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: state.projects.length,
                      itemBuilder: (context, index) {
                        final project = state.projects[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 0.0),
                          child: Column(
                            children: [
                              ExpansionTile(
                                textColor: context.appColors.contrastLight,
                                tilePadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                shape: Border(
                                  top: index == state.projects.length - 1
                                      ? BorderSide.none
                                      : BorderSide(
                                          color:
                                              context.appColors.contrastLight,
                                          width: 1),
                                  bottom: BorderSide(
                                      color: context.appColors.contrastLight,
                                      width: 1),
                                ),
                                collapsedShape: Border(
                                  top: index == state.projects.length - 1
                                      ? BorderSide.none
                                      : BorderSide(
                                          color:
                                              context.appColors.contrastLight,
                                          width: 1),
                                  bottom: BorderSide(
                                      color: context.appColors.contrastLight,
                                      width: 1),
                                ),
                                title: Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Text(
                                    project.name,
                                    style: TextStyle(
                                        color: context.appColors.contrastLight),
                                  ),
                                ),
                                subtitle: Text(
                                  project.description,
                                  style: TextStyle(
                                    color: context.appColors.contrastLight,
                                    fontSize: 12,
                                  ),
                                ),
                                iconColor: context.appColors.contrastLight,
                                collapsedIconColor:
                                    context.appColors.contrastLight,
                                childrenPadding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 16),
                                children: [
                                  Wrap(
                                    alignment: WrapAlignment.spaceEvenly,
                                    spacing: 16.0,
                                    runSpacing: 16.0,
                                    children: [
                                      LinkTile(
                                        title: 'GitHub',
                                        icon: Icons.code,
                                        onTap: () async =>
                                            await launchUrlString(
                                                project.gitHubLink),
                                      ),
                                      LinkTile(
                                        title: 'Website',
                                        icon: Icons.public,
                                        onTap: () => launchUrlString(
                                            project.websiteLink),
                                      ),
                                      LinkTile(
                                        title: 'White Paper',
                                        icon: Icons.description,
                                        onTap: () async {
                                          await showDialog(
                                            context: context,
                                            builder: (_) => Dialog(
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8)),
                                              child: SizedBox(
                                                width: double.infinity,
                                                child: Column(
                                                  children: [
                                                    const SizedBox(height: 16),
                                                    Text(
                                                      project.name,
                                                      style: TextStyle(
                                                          color: context
                                                              .appColors
                                                              .contrastDark),
                                                    ),
                                                    Text(
                                                      'White Paper',
                                                      style: TextStyle(
                                                          color: context
                                                              .appColors
                                                              .contrastDark),
                                                    ),
                                                    const SizedBox(height: 16),
                                                    Expanded(
                                                      child: PDF(
                                                              backgroundColor:
                                                                  Colors
                                                                      .transparent)
                                                          .cachedFromUrl(
                                                        project.whitePaperLink,
                                                        placeholder:
                                                            (progress) => Center(
                                                                child: Text(
                                                                    '$progress%')),
                                                        errorWidget: (error) =>
                                                            const Center(
                                                                child: Icon(Icons
                                                                    .error)),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      LinkTile(
                                        title: 'Roadmap',
                                        icon: Icons.map,
                                        onTap: () async {
                                          await showDialog(
                                            context: context,
                                            builder: (_) => Dialog(
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8)),
                                              child: SizedBox(
                                                width: double.infinity,
                                                child: Column(
                                                  children: [
                                                    const SizedBox(height: 16),
                                                    Text(
                                                      project.name,
                                                      style: TextStyle(
                                                          color: context
                                                              .appColors
                                                              .contrastDark),
                                                    ),
                                                    Text(
                                                      'Roadmap',
                                                      style: TextStyle(
                                                          color: context
                                                              .appColors
                                                              .contrastDark),
                                                    ),
                                                    const SizedBox(height: 16),
                                                    Expanded(
                                                      child: PDF(
                                                              backgroundColor:
                                                                  Colors
                                                                      .transparent)
                                                          .cachedFromUrl(
                                                        project.roadmapLink,
                                                        placeholder:
                                                            (progress) => Center(
                                                                child: Text(
                                                                    '$progress%')),
                                                        errorWidget: (error) =>
                                                            const Center(
                                                                child: Icon(Icons
                                                                    .error)),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      LinkTile(
                                        title: 'Socials',
                                        icon: Icons.people,
                                        onTap: () => launchUrlString(
                                            project.socialsLink),
                                      ),
                                      LinkTile(
                                        title: 'Telegram',
                                        icon: Icons.telegram,
                                        onTap: () => launchUrlString(
                                            project.telegramLink),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16.0),
                                  Wrap(
                                    alignment: WrapAlignment.spaceEvenly,
                                    spacing: 16.0,
                                    runSpacing: 16.0,
                                    children: [
                                      _buildContributionButton(context, project,
                                          100, amountController),
                                      _buildContributionButton(context, project,
                                          250, amountController),
                                      _buildContributionButton(context, project,
                                          500, amountController),
                                      _buildContributionButton(context, project,
                                          1000, amountController),
                                    ],
                                  ),
                                  const SizedBox(height: 16.0),
                                  Text(
                                    'Launch date: ${formatDate(project.launchDate, [
                                          M,
                                          ' ',
                                          d,
                                          ', ',
                                          yyyy
                                        ])}',
                                    style: TextStyle(
                                      color: context.appColors.contrastLight,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                height: 50,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                        color: context.appColors.contrastLight,
                                        width: 1),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Stack(
                                        children: [
                                          SizedBox.expand(
                                            child: LinearProgressIndicator(
                                              value: project.fundingProgress,
                                              backgroundColor: Colors.black,
                                              color: Colors.green,
                                            ),
                                          ),
                                          Center(
                                            child: Text(
                                              'Allocation Pool: ${(project.fundingProgress * 100).toInt()}%',
                                              style: TextStyle(
                                                  color: context
                                                      .appColors.contrastLight),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(right: 8.0),
                                      child: Row(
                                        children: [
                                          GestureDetector(
                                            onTap: () {
                                              final userId = context
                                                  .read<PortalBloc>()
                                                  .state
                                                  .user!
                                                  .id;
                                              if (state.likedProjectsIds
                                                  .contains(project.id)) {
                                                context.read<IncubatorBloc>().add(
                                                    IncubatorProjectUnlikeEvent(
                                                        project.id, userId));
                                              } else {
                                                context.read<IncubatorBloc>().add(
                                                    IncubatorProjectLikeEvent(
                                                        project.id, userId));
                                              }
                                            },
                                            child: state.likedProjectsIds.any(
                                                    (likedProject) =>
                                                        likedProject ==
                                                        project.id)
                                                ? const Icon(Icons.favorite,
                                                    color: Colors.red)
                                                : Icon(Icons.favorite_border,
                                                    color: context.appColors
                                                        .contrastLight),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${project.likesCount}',
                                            style: TextStyle(
                                                color: context
                                                    .appColors.contrastLight),
                                          ),
                                        ],
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContributionButton(
    BuildContext context,
    Project project,
    int amount,
    TextEditingController amountController,
  ) {
    return GestureDetector(
      onTap: () {
        amountController.text = amount.toString();
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            return BlocProvider.value(
              value: context.read<IncubatorBloc>(),
              child: BlocConsumer<IncubatorBloc, IncubatorState>(
                listener: (context, state) {
                  if (state.transactionStatus ==
                      IncubatorTransactionStatus.success) {
                    Future.delayed(const Duration(milliseconds: 1500), () {
                      if (context.mounted) {
                        if (context.canPop()) {
                          context.pop();
                        }
                        // Reset dialog status after closing
                        context
                            .read<IncubatorBloc>()
                            .add(IncubatorResetTransactionStatusEvent());
                      }
                    });
                  }
                },
                builder: (context, state) {
                  return AlertDialog(
                    scrollable: true,
                    title: Text(
                      'Contribute to ${project.name}',
                      style: const TextStyle(
                          color: AppPalette.contrastDark, fontSize: 12),
                    ),
                    content: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.8,
                      child:
                          _buildDialogContent(context, state, amountController),
                    ),
                    actions: _buildDialogActions(
                        context, state, project, amountController),
                  );
                },
              ),
            );
          },
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: context.appColors.contrastLight,
        ),
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$amount',
              style: TextStyle(
                  color: context.appColors.contrastDark, fontSize: 12),
            ),
            Image.asset('assets/icons/logo.png', height: 32, width: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogContent(
    BuildContext context,
    IncubatorState state,
    TextEditingController amountController,
  ) {
    switch (state.transactionStatus) {
      case IncubatorTransactionStatus.initial:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              style: TextStyle(color: context.appColors.contrastDark),
              readOnly: true,
              decoration: const InputDecoration(
                hintText: 'Enter contribution amount',
                hintStyle:
                    TextStyle(color: AppPalette.contrastDark, fontSize: 12),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        );
      case IncubatorTransactionStatus.submitting:
        return const SizedBox(
          height: 80,
          child: Center(
            child: CircularProgressIndicator(
              valueColor:
                  AlwaysStoppedAnimation<Color>(AppPalette.contrastDark),
            ),
          ),
        );
      case IncubatorTransactionStatus.success:
        return const SizedBox(
          height: 80,
          child: Center(
            child: Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 48,
            ),
          ),
        );
      default:
        return const SizedBox(
          height: 80,
          child: Center(
            child: Icon(
              Icons.error,
              color: Colors.red,
              size: 48,
            ),
          ),
        );
    }
  }
}

List<Widget> _buildDialogActions(
  BuildContext context,
  IncubatorState state,
  Project project,
  TextEditingController amountController,
) {
  if (state.transactionStatus != IncubatorTransactionStatus.initial) {
    return [];
  }

  return [
    TextButton(
      onPressed: () {
        if (context.canPop()) {
          context.pop();
        }
      },
      child: const Text('Cancel'),
    ),
    ElevatedButton(
      onPressed: () {
        final amount = int.tryParse(
            amountController.text.isEmpty ? '0' : amountController.text);
        if (amount == null || amount <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter a valid amount'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }

        final userId = context.read<PortalBloc>().state.user!.id;
        context.read<IncubatorBloc>().add(IncubatorWithdrawEvent(
              projectId: project.id,
              wallet: context
                  .read<PortalBloc>()
                  .state
                  .user!
                  .embeddedSolanaWallets
                  .first,
              amount: amount,
              userId: userId,
            ));
      },
      child: const Text('Contribute'),
    ),
  ];
}

class LinkTile extends StatelessWidget {
  const LinkTile(
      {required this.title,
      required this.icon,
      required this.onTap,
      super.key});

  final String title;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: context.appColors.contrastLight),
          const SizedBox(width: 8),
          Text(
            title,
            style:
                TextStyle(color: context.appColors.contrastLight, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
