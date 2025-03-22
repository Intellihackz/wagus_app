import 'package:flutter/material.dart';
import 'package:wagus/theme/app_palette.dart';

class Incubator extends StatelessWidget {
  Incubator({super.key});

  final List<Project> _projects = [
    Project(
        name: 'PROJECT IDX',
        description: 'A decentralized domain name service'),
    Project(
        name: 'DEFI FLOW',
        description: 'A DeFi automation tool for yield farming'),
    Project(
        name: 'NFT HUB', description: 'A curated NFT marketplace for artists'),
    Project(
        name: 'CHAIN VOTE',
        description: 'Decentralized on-chain governance platform'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: Padding(
          padding: const EdgeInsets.only(top: 128.0),
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
              SizedBox(height: 16.0),
              Expanded(
                child: ListView.builder(
                  physics: ClampingScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: _projects.length,
                  itemBuilder: (context, index) {
                    final project = _projects[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: ExpansionTile(
                        textColor: context.appColors.contrastLight,
                        tilePadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        shape: Border(
                          top: BorderSide(
                              color: context.appColors.contrastLight, width: 1),
                          bottom: BorderSide(
                              color: context.appColors.contrastLight, width: 1),
                        ),
                        collapsedShape: Border(
                          top: BorderSide(
                              color: context.appColors.contrastLight, width: 1),
                          bottom: BorderSide(
                              color: context.appColors.contrastLight, width: 1),
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
                              LinkTile(title: 'Website', icon: Icons.public),
                              LinkTile(
                                  title: 'White Paper',
                                  icon: Icons.description),
                              LinkTile(title: 'Roadmap', icon: Icons.map),
                              LinkTile(title: 'Socials', icon: Icons.people),
                              LinkTile(title: 'Telegram', icon: Icons.telegram),
                            ],
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

  Project({required this.name, required this.description});
}
