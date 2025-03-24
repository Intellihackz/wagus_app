class Project {
  final String id;
  final String name;
  final String description;
  final double fundingProgress;
  final int likesCount;
  final DateTime launchDate;

  final String walletAddress;
  final String gitHubLink;
  final String websiteLink;
  final String whitePaperLink;
  final String roadmapLink;
  final String socialsLink;
  final String telegramLink;

  Project({
    required this.id,
    required this.name,
    required this.description,
    required this.fundingProgress,
    required this.likesCount,
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
      id: json['id'],
      name: json['name'],
      description: json['description'],
      fundingProgress: json['fundingProgress'],
      likesCount: json['likesCount'],
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
