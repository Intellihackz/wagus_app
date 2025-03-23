import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:wagus/features/home/bloc/home_bloc.dart';
import 'package:wagus/features/home/domain/message.dart';
import 'package:wagus/features/portal/bloc/portal_bloc.dart';
import 'package:wagus/theme/app_palette.dart';

class Home extends HookWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    final inputController = useTextEditingController();

    return BlocBuilder<PortalBloc, PortalState>(
      builder: (context, portalState) {
        return BlocBuilder<HomeBloc, HomeState>(
          builder: (context, homeState) {
            return Scaffold(
              body: Stack(
                children: [
                  GestureDetector(
                    child: Container(
                      alignment: Alignment.topCenter,
                      margin: EdgeInsets.only(top: 32),
                      width: double.infinity,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 100.0),
                        child: Column(
                          children: [
                            Center(
                              child: Text(
                                'You have ${portalState.holder?.tokenAmount.toStringAsFixed(2) ?? 0} \$WAGUS tokens',
                                style: TextStyle(
                                  color: AppPalette.contrastLight,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
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
                      child: Column(
                        children: [
                          Expanded(
                              child: ListView.builder(
                            reverse: true,
                            itemCount: homeState.messages.length,
                            itemBuilder: (context, index) {
                              return Row(
                                mainAxisAlignment:
                                    homeState.messages[index].sender ==
                                            portalState
                                                .user!
                                                .embeddedSolanaWallets
                                                .first
                                                .address
                                        ? MainAxisAlignment.end
                                        : MainAxisAlignment.start,
                                children: [
                                  Text(
                                    '[${homeState.messages[index].sender.substring(0, 3)}..${homeState.messages[index].sender.substring(homeState.messages[index].sender.length - 3)}]',
                                    style: TextStyle(
                                      color: AppPalette.contrastLight,
                                      fontSize: 12,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    homeState.messages[index].message,
                                    style: TextStyle(
                                      color: AppPalette.contrastLight,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              );
                            },
                          )),
                          TextField(
                            controller: inputController,
                            onTapOutside: (_) =>
                                FocusScope.of(context).unfocus(),
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
                                  context.read<HomeBloc>().add(
                                        HomeSendMessageEvent(
                                          message: Message(
                                            message: inputController.text,
                                            sender: portalState
                                                .user!
                                                .embeddedSolanaWallets
                                                .first
                                                .address,
                                          ),
                                        ),
                                      );

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
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
