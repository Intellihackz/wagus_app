class SpygusGameData {
  final String imagePath;
  final List<int> target;

  SpygusGameData({
    required this.imagePath,
    required this.target,
  });

  factory SpygusGameData.fromFirestore(Map<String, dynamic> json) {
    return SpygusGameData(
      imagePath: json['image'] ?? '',
      target: List<int>.from(json['target'] ?? [0, 0]),
    );
  }
}
