import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
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
    ),
    Project(
      name: 'DEFI FLOW',
      description: 'A DeFi automation tool for yield farming',
      fundingProgress: 0.6,
      likes: 104,
      launchDate: DateTime(2025, 6, 11),
    ),
    Project(
      name: 'NFT HUB',
      description: 'A curated NFT marketplace for artists',
      fundingProgress: 0.4,
      likes: 98,
      launchDate: DateTime(2025, 6, 14),
    ),
    Project(
      name: 'CHAIN VOTE',
      description: 'Decentralized on-chain governance platform',
      fundingProgress: 0.1,
      likes: 75,
      launchDate: DateTime(2025, 6, 16),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: context.appColors.contrastLight,
        onPressed: () {
          // Handle add project logic here
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('This feature is coming soon!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
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
                  itemCount: _projects.length,
                  itemBuilder: (context, index) {
                    final project = _projects[index];
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
                                      color: context.appColors.contrastLight,
                                      width: 1),
                              bottom: BorderSide(
                                  color: context.appColors.contrastLight,
                                  width: 1),
                            ),
                            collapsedShape: Border(
                              top: index == _projects.length - 1
                                  ? BorderSide.none
                                  : BorderSide(
                                      color: context.appColors.contrastLight,
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
                            collapsedIconColor: context.appColors.contrastLight,
                            childrenPadding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 16),
                            children: [
                              Wrap(
                                alignment: WrapAlignment.spaceEvenly,
                                spacing: 16.0,
                                runSpacing: 16.0,
                                children: const [
                                  LinkTile(title: 'GitHub', icon: Icons.code),
                                  LinkTile(
                                      title: 'Website', icon: Icons.public),
                                  LinkTile(
                                      title: 'White Paper',
                                      icon: Icons.description),
                                  LinkTile(title: 'Roadmap', icon: Icons.map),
                                  LinkTile(
                                      title: 'Socials', icon: Icons.people),
                                  LinkTile(
                                      title: 'Telegram', icon: Icons.telegram),
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
                                      borderRadius: BorderRadius.circular(8),
                                      color: context.appColors.contrastLight,
                                    ),
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '100',
                                          style: TextStyle(
                                            color:
                                                context.appColors.contrastDark,
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
                                      borderRadius: BorderRadius.circular(8),
                                      color: context.appColors.contrastLight,
                                    ),
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '250',
                                          style: TextStyle(
                                            color:
                                                context.appColors.contrastDark,
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
                                      borderRadius: BorderRadius.circular(8),
                                      color: context.appColors.contrastLight,
                                    ),
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '500',
                                          style: TextStyle(
                                            color:
                                                context.appColors.contrastDark,
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
                                      borderRadius: BorderRadius.circular(8),
                                      color: context.appColors.contrastLight,
                                    ),
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '1000',
                                          style: TextStyle(
                                            color:
                                                context.appColors.contrastDark,
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
                                            color:
                                                context.appColors.contrastLight,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Row(
                                    children: [
                                      Icon(Icons.favorite_border,
                                          color:
                                              context.appColors.contrastLight),
                                      SizedBox(width: 4),
                                      Text(
                                        '${project.likes}',
                                        style: TextStyle(
                                          color:
                                              context.appColors.contrastLight,
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
  }
}

class LinkTile extends StatelessWidget {
  const LinkTile({required this.title, required this.icon, super.key});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('This feature is coming soon!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
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

  Project({
    required this.name,
    required this.description,
    required this.fundingProgress,
    required this.likes,
    required this.launchDate,
  });
}
