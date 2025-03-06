import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIRepository {
  final Dio _dio = Dio();

  Future<(String, PredictionType)?> makeLongOrShortPrediction(
      {required SupportedCryptoPredictions selectedCrypto}) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) return null;

    try {
      final response = await _dio.post(
        'https://api.openai.com/v1/chat/completions',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey'
          },
        ),
        data: {
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'user',
              'content': _getCryptoPredictionPrompt(selectedCrypto)
            }
          ],
          'temperature': 0.7,
        },
      );

      final prediction = response.data?['choices']?[0]['message']['content'];
      return prediction != null
          ? (prediction.toString(), _parsePredictionType(prediction))
          : null;
    } catch (error) {
      print('Error: $error');
      return null;
    }
  }

  String _getCryptoPredictionPrompt(SupportedCryptoPredictions selectedCrypto) {
    switch (selectedCrypto) {
      case SupportedCryptoPredictions.bitcoin:
        return "In one sentence, based on current market trends and data, will Bitcoin go up or down in the next week? Give a clear and confident prediction, without disclaimers or hesitation.";
      case SupportedCryptoPredictions.ethereum:
        return "In one sentence, considering Ethereum’s recent market behavior and trends, predict whether Ethereum will rise or fall in the short-term. Provide a direct and confident answer.";
      case SupportedCryptoPredictions.xrp:
        return "In one sentence, based on XRP's current performance, will it go up or down? Offer a strong opinion on the short-term direction.";
      case SupportedCryptoPredictions.solana:
        return "In one sentence, evaluate Solana's market trend and predict whether it will rise or fall over the next month. Give a decisive, confident answer.";
      default:
        return "No prediction selected. Please specify a cryptocurrency.";
    }
  }

  PredictionType _parsePredictionType(String prediction) {
    if (prediction.toLowerCase().contains('long')) return PredictionType.long;
    if (prediction.toLowerCase().contains('short')) return PredictionType.short;
    return PredictionType.none;
  }
}

enum SupportedCryptoPredictions {
  bitcoin(color: Colors.yellow),
  ethereum(color: Colors.blue),
  xrp(color: Colors.white),
  solana(color: Color.fromARGB(255, 112, 96, 209)),
  none(color: Colors.grey);

  final Color color;

  const SupportedCryptoPredictions({required this.color});
}

enum PredictionType { long, short, none }
