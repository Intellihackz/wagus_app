import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:wagus/features/home/chat/bloc/chat_bloc.dart';
import 'package:wagus/theme/app_palette.dart';

class Home extends HookWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    final inputController = useTextEditingController();

    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: Image.asset(
              'assets/background/home_logo.png',
              height: 200,
              fit: BoxFit.cover,
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: EdgeInsets.only(left: 16, right: 16, bottom: 16),
              height: MediaQuery.sizeOf(context).height * .3,
              width: double.infinity,
              child: BlocBuilder<ChatBloc, ChatState>(
                builder: (context, state) {
                  return Builder(builder: (context) {
                    return Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            reverse: true,
                            itemCount: state.messages.length,
                            itemBuilder: (context, index) {
                              return Text(
                                state.messages[index],
                                style: TextStyle(
                                  color: AppPalette.contrastLight,
                                  fontSize: 12,
                                ),
                              );
                            },
                          ),
                        ),
                        TextField(
                          controller: inputController,
                          style: TextStyle(
                            color: AppPalette.contrastLight,
                            fontSize: 12,
                          ),
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.zero,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            hintText: 'Type here',
                            hintStyle: TextStyle(
                              color: AppPalette.contrastLight,
                              fontSize: 12,
                            ),
                            suffixIcon: GestureDetector(
                              onTap: () {
                                context.read<ChatBloc>().add(
                                    ChatSendMessageEvent(
                                        message: inputController.text));

                                inputController.clear();
                                FocusScope.of(context).unfocus();
                              },
                              child: Icon(
                                Icons.send,
                                color: AppPalette.contrastLight,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
