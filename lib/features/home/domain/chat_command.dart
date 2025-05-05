class ChatCommand {
  final String action;
  final List<String> args;
  final Map<String, String> flags;

  ChatCommand({
    required this.action,
    required this.args,
    required this.flags,
  });

  @override
  String toString() {
    return 'Action: $action\nArgs: $args\nFlags: $flags';
  }
}
