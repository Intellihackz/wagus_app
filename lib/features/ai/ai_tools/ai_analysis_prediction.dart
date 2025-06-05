import 'package:cryptofont/cryptofont.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:wagus/features/ai/ai_tools/reporting_tool.dart';
import 'package:wagus/features/ai/bloc/ai_bloc.dart';
import 'package:wagus/features/ai/data/ai_repository.dart';
import 'package:wagus/features/portal/bloc/portal_bloc.dart';
import 'package:wagus/core/theme/app_palette.dart';

class AIAnalysisPrediction extends HookWidget {
  const AIAnalysisPrediction({super.key});

  @override
  Widget build(BuildContext context) {
    final selectedPrediction = useState<SupportedCryptoPredictions>(
      SupportedCryptoPredictions.none,
    );

    final pageController = usePageController();

    return BlocBuilder<AiBloc, AiState>(
      builder: (context, state) {
        return Scaffold(
          floatingActionButton: ReportFloatingButton(
            aiGeneratedText: state.response,
            aiState: state,
          ),
          resizeToAvoidBottomInset: false,
          body: SizedBox.expand(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 32.0),
                      child: BackButton(
                        color: context.appColors.contrastLight,
                      ),
                    ),
                  ),
                ),
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 64.0),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxHeight: 400,
                          ),
                          child:
                              BlocSelector<PortalBloc, PortalState, TierStatus>(
                            selector: (state) {
                              return state.tierStatus;
                            },
                            builder: (context, state) {
                              return PageView(
                                controller: pageController,
                                children: [
                                  _CryptoGrid(
                                    selectedPrediction: selectedPrediction,
                                    context: context,
                                    label: 'Main Cryptos',
                                    cryptos: [
                                      SupportedCryptoPredictions.bitcoin,
                                      SupportedCryptoPredictions.ethereum,
                                      SupportedCryptoPredictions.xrp,
                                      SupportedCryptoPredictions.solana,
                                    ],
                                  ),
                                  if (state == TierStatus.adventurer)
                                    _CryptoGrid(
                                      selectedPrediction: selectedPrediction,
                                      context: context,
                                      label: 'Meme Coins',
                                      cryptos: [
                                        SupportedCryptoPredictions.buckazoids,
                                        SupportedCryptoPredictions.lux,
                                        SupportedCryptoPredictions.snai,
                                        SupportedCryptoPredictions.collat,
                                        SupportedCryptoPredictions.gork,
                                        SupportedCryptoPredictions.pumpswap,
                                      ],
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Icon(Icons.swipe,
                        color: context.appColors.contrastLight,
                        size: 18), // subtle swipe indicator
                    const SizedBox(height: 12),
                    // prediction result
                    Visibility(
                      visible: state.predictionState !=
                          AIAnalysisPredictionState.initial,
                      child: Expanded(
                        child: SingleChildScrollView(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 32.0),
                            child: Column(
                              spacing: 12.0,
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: state.predictionState ==
                                      AIAnalysisPredictionState.loading
                                  ? [
                                      SizedBox(height: 100),
                                      CircularProgressIndicator(
                                          color: Colors.white),
                                    ]
                                  : [Text(state.response)],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AIPredictionButton extends StatelessWidget {
  const _AIPredictionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
    required this.isSelected,
  });

  final String label;
  final Widget icon;
  final Color color;
  final VoidCallback onPressed;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          color: context.appColors.deepMidnightBlue,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2.0,
          ),
        ),
        height: 125,
        width: 125,
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 12.0,
          children: [
            icon,
            Text(label, style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _CryptoGrid extends StatelessWidget {
  const _CryptoGrid({
    required this.selectedPrediction,
    required this.context,
    required this.cryptos,
    required this.label,
  });

  final ValueNotifier<SupportedCryptoPredictions> selectedPrediction;
  final BuildContext context;
  final List<SupportedCryptoPredictions> cryptos;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children: cryptos.map((crypto) {
          return _AIPredictionButton(
            label: crypto.name.toUpperCase(),
            icon: _getIcon(crypto),
            color: crypto.color,
            isSelected: selectedPrediction.value == crypto,
            onPressed: () {
              selectedPrediction.value = crypto;
              context.read<AiBloc>().add(AIGeneratePredictionEvent(crypto));
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _getIcon(SupportedCryptoPredictions crypto) {
    switch (crypto) {
      case SupportedCryptoPredictions.bitcoin:
        return Icon(CryptoFontIcons.btc, color: crypto.color);
      case SupportedCryptoPredictions.ethereum:
        return Icon(CryptoFontIcons.eth, color: crypto.color);
      case SupportedCryptoPredictions.xrp:
        return Icon(CryptoFontIcons.xrp, color: crypto.color);
      case SupportedCryptoPredictions.solana:
        return Icon(CryptoFontIcons.sol, color: crypto.color);
      default:
        return Image.asset(
          'assets/icons/${crypto.name.toLowerCase()}.png',
          width: 40,
          height: 40,
          fit: BoxFit.contain,
        );
    }
  }
}
