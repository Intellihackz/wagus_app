import 'package:cryptofont/cryptofont.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:wagus/features/ai/bloc/ai_bloc.dart';
import 'package:wagus/features/ai/data/ai_repository.dart';
import 'package:wagus/theme/app_palette.dart';

class AIAnalysisPrediction extends HookWidget {
  const AIAnalysisPrediction({super.key});

  @override
  Widget build(BuildContext context) {
    final selectedPrediction = useState<SupportedCryptoPredictions>(
      SupportedCryptoPredictions.none,
    );

    return BlocBuilder<AiBloc, AiState>(
      builder: (context, state) {
        return Scaffold(
          body: SizedBox.expand(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 100.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 24.0,
                      children: [
                        Text('Choose a prediction'),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: [
                            _AIPredictionButton(
                              label: 'Bitcoin',
                              icon: CryptoFontIcons.btc,
                              color: SupportedCryptoPredictions.bitcoin.color,
                              onPressed: () {
                                selectedPrediction.value =
                                    SupportedCryptoPredictions.bitcoin;

                                context.read<AiBloc>().add(
                                      AIGeneratePredictionEvent(
                                        selectedPrediction.value,
                                      ),
                                    );
                              },
                              isSelected: selectedPrediction.value ==
                                  SupportedCryptoPredictions.bitcoin,
                            ),
                            _AIPredictionButton(
                              label: 'Ethereum',
                              icon: CryptoFontIcons.eth,
                              color: SupportedCryptoPredictions.ethereum.color,
                              onPressed: () {
                                selectedPrediction.value =
                                    SupportedCryptoPredictions.ethereum;

                                context.read<AiBloc>().add(
                                      AIGeneratePredictionEvent(
                                        selectedPrediction.value,
                                      ),
                                    );
                              },
                              isSelected: selectedPrediction.value ==
                                  SupportedCryptoPredictions.ethereum,
                            ),
                            _AIPredictionButton(
                              label: 'XRP',
                              icon: CryptoFontIcons.xrp,
                              color: SupportedCryptoPredictions.xrp.color,
                              onPressed: () {
                                selectedPrediction.value =
                                    SupportedCryptoPredictions.xrp;

                                context.read<AiBloc>().add(
                                      AIGeneratePredictionEvent(
                                        selectedPrediction.value,
                                      ),
                                    );
                              },
                              isSelected: selectedPrediction.value ==
                                  SupportedCryptoPredictions.xrp,
                            ),
                            _AIPredictionButton(
                              label: 'Solana',
                              icon: CryptoFontIcons.sol,
                              color: SupportedCryptoPredictions.solana.color,
                              onPressed: () {
                                selectedPrediction.value =
                                    SupportedCryptoPredictions.solana;

                                context.read<AiBloc>().add(
                                      AIGeneratePredictionEvent(
                                        selectedPrediction.value,
                                      ),
                                    );
                              },
                              isSelected: selectedPrediction.value ==
                                  SupportedCryptoPredictions.solana,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Visibility(
                    visible: state.predictionState !=
                        AIAnalysisPredictionState.initial,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 32.0, right: 32.0),
                      child: Column(
                        spacing: 12.0,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: state.predictionState ==
                                AIAnalysisPredictionState.loading
                            ? [CircularProgressIndicator()]
                            : [
                                Text(state.response),
                              ],
                      ),
                    ),
                  ),
                ),
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
  final IconData icon;
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
            Icon(icon, color: color),
            Text(label, style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
