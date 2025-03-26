class Project {
  final String id;
  final String contactEmail;
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
  final double? totalFunded;
  final List<String> addressesFunded;

  Project({
    required this.id,
    required this.contactEmail,
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
    this.totalFunded,
    required this.addressesFunded,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'],
      contactEmail: json['contactEmail'],
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
      totalFunded: json['totalFunded'],
      addressesFunded: List<String>.from(json['addressesFunded']),
    );
  }

  Project copyWithId(String newId) {
    return Project(
      id: newId,
      contactEmail: contactEmail,
      name: name,
      description: description,
      fundingProgress: fundingProgress,
      likesCount: likesCount,
      launchDate: launchDate,
      walletAddress: walletAddress,
      gitHubLink: gitHubLink,
      websiteLink: websiteLink,
      whitePaperLink: whitePaperLink,
      roadmapLink: roadmapLink,
      socialsLink: socialsLink,
      telegramLink: telegramLink,
      totalFunded: totalFunded,
      addressesFunded: addressesFunded,
    );
  }

  //copywith
  Project copyWith({
    String? id,
    String? contactEmail,
    String? name,
    String? description,
    double? fundingProgress,
    int? likesCount,
    DateTime? launchDate,
    String? walletAddress,
    String? gitHubLink,
    String? websiteLink,
    String? whitePaperLink,
    String? roadmapLink,
    String? socialsLink,
    String? telegramLink,
    double? Function()? totalFunded,
    List<String>? addressesFunded,
  }) {
    return Project(
      id: id ?? this.id,
      contactEmail: contactEmail ?? this.contactEmail,
      name: name ?? this.name,
      description: description ?? this.description,
      fundingProgress: fundingProgress ?? this.fundingProgress,
      likesCount: likesCount ?? this.likesCount,
      launchDate: launchDate ?? this.launchDate,
      walletAddress: walletAddress ?? this.walletAddress,
      gitHubLink: gitHubLink ?? this.gitHubLink,
      websiteLink: websiteLink ?? this.websiteLink,
      whitePaperLink: whitePaperLink ?? this.whitePaperLink,
      roadmapLink: roadmapLink ?? this.roadmapLink,
      socialsLink: socialsLink ?? this.socialsLink,
      telegramLink: telegramLink ?? this.telegramLink,
      totalFunded: totalFunded != null ? totalFunded() : this.totalFunded,
      addressesFunded: addressesFunded ?? this.addressesFunded,
    );
  }
}
