import 'package:wagus/features/rpg/domain/skill.dart';

const Map<String, Skill> supportedSkills = {
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
  'ran': Skill(
    id: 'ran',
    name: 'Ranged',
    category: 'combat',
    description: 'Improves ranged weapon efficiency.',
  ),
  'mag': Skill(
    id: 'mag',
    name: 'Magic',
    category: 'combat',
    description: 'Improves spell power and casting.',
  ),
  'hp': Skill(
    id: 'hp',
    name: 'Hitpoints',
    category: 'combat',
    description: 'Determines total health.',
  ),
  'hack': Skill(
    id: 'hack',
    name: 'Hacking',
    category: 'utility',
    description: 'Access and override systems.',
  ),
  'forge': Skill(
    id: 'forge',
    name: 'Forging',
    category: 'utility',
    description: 'Craft weapons and gear.',
  ),
  'tech': Skill(
    id: 'tech',
    name: 'Tech',
    category: 'utility',
    description: 'Use and install advanced equipment.',
  ),
  'stealth': Skill(
    id: 'stealth',
    name: 'Stealth',
    category: 'utility',
    description: 'Move undetected.',
  ),
  'scan': Skill(
    id: 'scan',
    name: 'Scan',
    category: 'utility',
    description: 'Detect enemies and hidden items.',
  ),
  'net': Skill(
    id: 'net',
    name: 'Netrunning',
    category: 'utility',
    description: 'Cyber warfare and system infiltration.',
  ),
};
