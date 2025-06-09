import '../domain/skill.dart';

class SkillRegistry {
  static final Map<String, Skill> _skills = {
    'str': Skill(
      id: 'str',
      name: 'Strength',
      category: 'combat',
      description: 'Increases melee damage.',
    ),
    'def': Skill(
      id: 'def',
      name: 'Defense',
      category: 'combat',
      description: 'Reduces incoming damage.',
    ),
    'mag': Skill(
      id: 'mag',
      name: 'Magic',
      category: 'combat',
      description: 'Spellcasting and mystic effects.',
    ),
    'hp': Skill(
      id: 'hp',
      name: 'Hitpoints',
      category: 'combat',
      description: 'Max health in chat-based battles.',
    ),
    'hack': Skill(
      id: 'hack',
      name: 'Hacking',
      category: 'tech',
      description: 'Bypass digital locks and vaults.',
    ),
    'forge': Skill(
      id: 'forge',
      name: 'Forging',
      category: 'tech',
      description: 'Craft tools, badges, keys.',
    ),
    'net': Skill(
      id: 'net',
      name: 'Netrunning',
      category: 'tech',
      description: 'Run cyberspace missions and dives.',
    ),
    'scan': Skill(
      id: 'scan',
      name: 'Scan',
      category: 'tech',
      description: 'Reveal hidden objects or threats.',
    ),
    'afk': Skill(
      id: 'afk',
      name: 'AFK Mode',
      category: 'meta',
      description: 'Train a skill passively over time.',
    ),
    'focus': Skill(
      id: 'focus',
      name: 'Focus',
      category: 'meta',
      description: 'Boost action success or shorten cooldowns.',
    ),
    'luck': Skill(
      id: 'luck',
      name: 'Luck',
      category: 'meta',
      description: 'Affects random rewards and rolls.',
    ),
  };

  static List<Skill> all() => _skills.values.toList();

  static Skill? getById(String id) => _skills[id];

  static List<Skill> byCategory(String category) =>
      _skills.values.where((s) => s.category == category).toList();

  static bool isValid(String id) => _skills.containsKey(id);

  static List<String> allIds() => _skills.keys.toList();
}
