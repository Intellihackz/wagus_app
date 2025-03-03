import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:wagus/features/home/bloc/home_bloc.dart';
import 'package:wagus/features/home/chat/bloc/chat_bloc.dart';
import 'package:wagus/theme/app_palette.dart';

class Home extends HookWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    final inputController = useTextEditingController();
    final carouselController = CarouselSliderController();

    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        return Scaffold(
          body: Stack(
            children: [
              GestureDetector(
                child: Container(
                  alignment: Alignment.topCenter,
                  margin: EdgeInsets.only(top: 64),
                  width: double.infinity,
                  child: CarouselSlider(
                    carouselController: carouselController,
                    options: CarouselOptions(
                      autoPlay: true,
                      enableInfiniteScroll: true,
                      autoPlayInterval: Duration(milliseconds: 100),
                      autoPlayAnimationDuration: Duration(milliseconds: 1000),
                      viewportFraction: 1,
                    ),
                    items: state.groupedTransactions
                        .map((transactions) => Row(
                                children: transactions.map((transaction) {
                              return Expanded(
                                  child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(transaction.asset,
                                      height: 100, fit: BoxFit.cover),
                                  Text(
                                    transaction.amount.toStringAsFixed(2),
                                    style: TextStyle(
                                        color: AppPalette.contrastLight,
                                        fontSize: 12),
                                  ),
                                ],
                              ));
                            }).toList()))
                        .toList(),
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
                        child: BlocSelector<ChatBloc, ChatState, List<String>>(
                          selector: (state) {
                            return state.messages;
                          },
                          builder: (context, messages) {
                            return ListView.builder(
                              reverse: true,
                              itemCount: messages.length,
                              itemBuilder: (context, index) {
                                return Text(
                                  messages[index],
                                  style: TextStyle(
                                    color: AppPalette.contrastLight,
                                    fontSize: 12,
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      TextField(
                        controller: inputController,
                        onTapOutside: (_) => FocusScope.of(context).unfocus(),
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
                              // Handle message sending
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
  }
}
