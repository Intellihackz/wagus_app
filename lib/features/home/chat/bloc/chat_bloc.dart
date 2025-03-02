import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:wagus/features/home/chat/data/chat_repository.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository chatRepository;
  ChatBloc({required this.chatRepository})
      : super(
          ChatState(
            messages: [],
          ),
        ) {
    on<ChatInitialEvent>((event, emit) async {
      await emit.forEach(chatRepository.getMessages(), onData: (data) {
        final messages = data.docs
            .map((doc) => doc.data())
            .toList()
            .cast<Map<String, dynamic>>();

        return state.copyWith(
          messages: messages.map((e) => e['message'] as String).toList(),
        );
      });
    });

    on<ChatSendMessageEvent>((event, emit) async {
      await chatRepository.sendMessage(event.message);
    });
  }
}
