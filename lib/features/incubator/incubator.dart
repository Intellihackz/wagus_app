import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cached_pdfview/flutter_cached_pdfview.dart';
import 'package:go_router/go_router.dart';
import 'package:wagus/features/incubator/bloc/incubator_bloc.dart';
import 'package:wagus/router.dart';
import 'package:wagus/theme/app_palette.dart';

class Incubator extends StatelessWidget {
  Incubator({super.key});

  final List<Project> _projects = [
    Project(
      name: 'PROJECT IDX',
      description: 'A decentralized domain name service',
      fundingProgress: 0.2,
      likes: 120,
      launchDate: DateTime(2025, 6, 19),
      walletAddress: '0x1234567890abcdef',
      gitHubLink: '',
      websiteLink: '',
      whitePaperLink: '',
      roadmapLink: '',
      socialsLink: '',
      telegramLink: '',
    ),
    Project(
      name: 'DEFI FLOW',
      description: 'A DeFi automation tool for yield farming',
      fundingProgress: 0.6,
      likes: 104,
      launchDate: DateTime(2025, 6, 11),
      walletAddress: '0x1234567890abcdef',
      gitHubLink: '',
      websiteLink: '',
      whitePaperLink: '',
      roadmapLink: '',
      socialsLink: '',
      telegramLink: '',
    ),
    Project(
      name: 'NFT HUB',
      description: 'A curated NFT marketplace for artists',
      fundingProgress: 0.4,
      likes: 98,
      launchDate: DateTime(2025, 6, 14),
      walletAddress: '0x1234567890abcdef',
      gitHubLink: '',
      websiteLink: '',
      whitePaperLink: '',
      roadmapLink: '',
      socialsLink: '',
      telegramLink: '',
    ),
    Project(
      name: 'CHAIN VOTE',
      description: 'Decentralized on-chain governance platform',
      fundingProgress: 0.1,
      likes: 75,
      launchDate: DateTime(2025, 6, 16),
      walletAddress: '0x1234567890abcdef',
      gitHubLink: '',
      websiteLink: '',
      whitePaperLink: '',
      roadmapLink: '',
      socialsLink: '',
      telegramLink: '',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<IncubatorBloc, IncubatorState>(
      builder: (context, state) {
        return Scaffold(
          floatingActionButton: FloatingActionButton(
            heroTag: 'addProject',
            backgroundColor: context.appColors.contrastLight,
            onPressed: () {
              context.push(projectInterface);
            },
            child: Icon(Icons.playlist_add_rounded),
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
                  SizedBox(height: 32.0),
                  Expanded(
                    child: ListView.builder(
                      physics: ClampingScrollPhysics(),
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
                                  top: index == _projects.length - 1
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
                                  top: index == _projects.length - 1
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
                                          onTap: () {}),
                                      LinkTile(
                                        title: 'Website',
                                        icon: Icons.public,
                                        onTap: () {},
                                      ),
                                      LinkTile(
                                        title: 'White Paper',
                                        icon: Icons.description,
                                        onTap: () async {
                                          await showDialog(
                                              context: context,
                                              builder: (_) => Dialog(
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                    child: SizedBox(
                                                      width: double.infinity,
                                                      child: Column(
                                                        children: [
                                                          SizedBox(
                                                            height: 16,
                                                          ),
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
                                                          SizedBox(
                                                            height: 16,
                                                          ),
                                                          Expanded(
                                                            child: PDF(
                                                                    backgroundColor:
                                                                        Colors
                                                                            .transparent)
                                                                .cachedFromUrl(
                                                              project
                                                                  .whitePaperLink,
                                                              placeholder:
                                                                  (progress) =>
                                                                      Center(
                                                                child: Text(
                                                                    '$progress%'),
                                                              ),
                                                              errorWidget: (error) =>
                                                                  const Center(
                                                                      child: Icon(
                                                                          Icons
                                                                              .error)),
                                                            ),
                                                          )
                                                        ],
                                                      ),
                                                    ),
                                                  ));
                                        },
                                      ),
                                      LinkTile(
                                        title: 'Roadmap',
                                        icon: Icons.map,
                                        onTap: () async {
                                          await showDialog(
                                              context: context,
                                              builder: (_) => Dialog(
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                    child: SizedBox(
                                                      width: double.infinity,
                                                      child: Column(
                                                        children: [
                                                          SizedBox(
                                                            height: 16,
                                                          ),
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
                                                          SizedBox(
                                                            height: 16,
                                                          ),
                                                          Expanded(
                                                            child: PDF(
                                                                    backgroundColor:
                                                                        Colors
                                                                            .transparent)
                                                                .cachedFromUrl(
                                                              project
                                                                  .roadmapLink,
                                                              placeholder:
                                                                  (progress) =>
                                                                      Center(
                                                                child: Text(
                                                                    '$progress%'),
                                                              ),
                                                              errorWidget: (error) =>
                                                                  const Center(
                                                                      child: Icon(
                                                                          Icons
                                                                              .error)),
                                                            ),
                                                          )
                                                        ],
                                                      ),
                                                    ),
                                                  ));
                                        },
                                      ),
                                      LinkTile(
                                        title: 'Socials',
                                        icon: Icons.people,
                                        onTap: () {},
                                      ),
                                      LinkTile(
                                        title: 'Telegram',
                                        icon: Icons.telegram,
                                        onTap: () {},
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16.0),
                                  Wrap(
                                    alignment: WrapAlignment.spaceEvenly,
                                    spacing: 16.0,
                                    runSpacing: 16.0,
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          color:
                                              context.appColors.contrastLight,
                                        ),
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              '100',
                                              style: TextStyle(
                                                color: context
                                                    .appColors.contrastDark,
                                                fontSize: 12,
                                              ),
                                            ),
                                            Image.asset('assets/icons/logo.png',
                                                height: 32, width: 32)
                                          ],
                                        ),
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          color:
                                              context.appColors.contrastLight,
                                        ),
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              '250',
                                              style: TextStyle(
                                                color: context
                                                    .appColors.contrastDark,
                                                fontSize: 12,
                                              ),
                                            ),
                                            Image.asset('assets/icons/logo.png',
                                                height: 32, width: 32)
                                          ],
                                        ),
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          color:
                                              context.appColors.contrastLight,
                                        ),
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              '500',
                                              style: TextStyle(
                                                color: context
                                                    .appColors.contrastDark,
                                                fontSize: 12,
                                              ),
                                            ),
                                            Image.asset('assets/icons/logo.png',
                                                height: 32, width: 32)
                                          ],
                                        ),
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          color:
                                              context.appColors.contrastLight,
                                        ),
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              '1000',
                                              style: TextStyle(
                                                color: context
                                                    .appColors.contrastDark,
                                                fontSize: 12,
                                              ),
                                            ),
                                            Image.asset('assets/icons/logo.png',
                                                height: 32, width: 32)
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16.0),
                                  Text(
                                    'Launch date: ${formatDate(
                                      project.launchDate,
                                      [M, ' ', d, ', ', yyyy],
                                    )}',
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
                                    width: 1,
                                  ),
                                )),
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
                                              '${(project.fundingProgress * 100).toInt()}%',
                                              style: TextStyle(
                                                color: context
                                                    .appColors.contrastLight,
                                              ),
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
                                          Icon(Icons.favorite_border,
                                              color: context
                                                  .appColors.contrastLight),
                                          SizedBox(width: 4),
                                          Text(
                                            '${project.likes}',
                                            style: TextStyle(
                                              color: context
                                                  .appColors.contrastLight,
                                            ),
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
          Icon(
            icon,
            size: 16,
            color: context.appColors.contrastLight,
          ),
          SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: context.appColors.contrastLight,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class Project {
  final String name;
  final String description;
  final double fundingProgress;
  final int likes;
  final DateTime launchDate;

  final String walletAddress;
  final String gitHubLink;
  final String websiteLink;
  final String whitePaperLink;
  final String roadmapLink;
  final String socialsLink;
  final String telegramLink;

  Project({
    required this.name,
    required this.description,
    required this.fundingProgress,
    required this.likes,
    required this.launchDate,
    required this.walletAddress,
    required this.gitHubLink,
    required this.websiteLink,
    required this.whitePaperLink,
    required this.roadmapLink,
    required this.socialsLink,
    required this.telegramLink,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      name: json['name'],
      description: json['description'],
      fundingProgress: json['fundingProgress'],
      likes: json['likes'],
      launchDate: DateTime.parse(json['launchDate']),
      walletAddress: json['walletAddress'],
      gitHubLink: json['gitHubLink'],
      websiteLink: json['websiteLink'],
      whitePaperLink: json['whitePaperLink'],
      roadmapLink: json['roadmapLink'],
      socialsLink: json['socialsLink'],
      telegramLink: json['telegramLink'],
    );
  }
}
