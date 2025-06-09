class Skill {
  final String id; // e.g. 'str'
  final String name;
  final String category; // 'combat', 'utility', 'survival'
  final String description;

  const Skill({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
  });
}
