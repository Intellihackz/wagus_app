import 'package:wagus/features/home/domain/chat_command.dart';

class ChatCommandParser {
  static ChatCommand? parse(String input) {
    if (!input.startsWith('/')) return null;

    final parts = _tokenize(input);
    if (parts.isEmpty) return null;

    final action = parts.first;
    final args = <String>[];
    final flags = <String, String>{};

    String? currentFlag;

    for (var i = 1; i < parts.length; i++) {
      final part = parts[i];

      if (part.startsWith('-')) {
        currentFlag = part.replaceFirst('-', '');
        flags[currentFlag] = '';
      } else if (currentFlag != null) {
        flags[currentFlag] = part;
        currentFlag = null;
      } else {
        args.add(part);
      }
    }

    return ChatCommand(action: action, args: args, flags: flags);
  }

  static List<String> _tokenize(String input) {
    final regex = RegExp(r'(".*?"|\S+)');
    return regex
        .allMatches(input)
        .map((m) => m.group(0)!.replaceAll('"', ''))
        .toList();
  }
}
