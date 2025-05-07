import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';

class AIRepository {
  final Dio _dio = Dio();

  Future<String?> generateImage({required String prompt}) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) return null;

    try {
      final response = await _dio.post(
        'https://api.openai.com/v1/images/generations',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey'
          },
        ),
        data: {
          'prompt': prompt,
          'n': 1,
          'size': '1024x1024',
          'response_format': 'url',
          'model': 'dall-e-3',
        },
      );

      final imageUrl = response.data?['data']?[0]['url'];
      return imageUrl as String?;
    } catch (error) {
      print('Error in generateImage: $error');
      return null;
    }
  }

  Future<bool> saveImage({required String imageUrl}) async {
    try {
      final response = await _dio.get(
        imageUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      final bytes = await ImageGallerySaverPlus.saveImage(
          Uint8List.fromList(response.data),
          quality: 60,
          name: 'ai_image');
      print('Saved image: $bytes');

      return true;
    } on Exception catch (e) {
      print('Error in saveImage: $e');
      return false;
    }
  }

  Future<(String, PredictionType)?> makeLongOrShortPrediction({
    required SupportedCryptoPredictions selectedCrypto,
    double? price,
  }) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) return null;

    try {
      final prompt = _getCryptoPredictionPrompt(selectedCrypto, price: price);
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
            {'role': 'user', 'content': prompt}
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

  Future<String?> generateWhitePaper({
    required String projectName,
    required String projectDescription,
    required String projectPurpose,
    required String projectType,
    required String projectContributors,
  }) async {
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
              'role': 'system',
              'content': '''
You are a professional white paper writer specializing in cryptocurrency projects. Your task is to generate a concise, one-page white paper for a crypto project coin launch. The white paper should be well-structured, professional, and persuasive, with the following sections:

1. Title: A clear and engaging title for the white paper, in uppercase (e.g., "CRYPTOMOON WHITE PAPER").
2. Introduction: A brief introduction to the project, including its name and a high-level overview.
3. Project Purpose: Explain the purpose of the project and the problem it aims to solve.
4. Project Description: Describe the project in detail, including its features and benefits.
5. Project Type: Specify the type of project (e.g., DeFi, NFT, utility token, etc.).
6. Team: List the key contributors to the project.
7. Conclusion: A short conclusion summarizing the project’s potential and encouraging investment.

The white paper should be written in a formal, professional tone, suitable for a crypto project launch. Use clear headings for each section in uppercase (e.g., "INTRODUCTION", "PROJECT PURPOSE"), followed by a newline, and do not use Markdown syntax (e.g., no ## or **). Avoid using disclaimers or speculative language—present the project confidently. The output should be concise, fitting on a single page (approximately 300-500 words). Do not include any images, diagrams, or external references. The output should be plain text, suitable for direct display or PDF generation.
'''
            },
            {
              'role': 'user',
              'content': '''
Generate a one-page white paper for a crypto project with the following details:

- Project Name: $projectName
- Project Description: $projectDescription
- Project Purpose: $projectPurpose
- Project Type: $projectType
- Project Contributors: $projectContributors

Ensure the white paper is well-structured, professional, and persuasive, following the instructions provided.
'''
            }
          ],
          'temperature': 0.7,
          'max_tokens':
              1000, // Adjust to ensure the response fits ~300-500 words
        },
      );

      final whitePaper = response.data?['choices']?[0]['message']['content'];
      return whitePaper as String?;
    } catch (error) {
      print('Error in generateWhitePaper: $error');
      return null;
    }
  }

  String _getCryptoPredictionPrompt(
    SupportedCryptoPredictions crypto, {
    double? price,
  }) {
    final name = crypto.name.toUpperCase();
    final priceInfo = price != null
        ? "Its current price is \$${price.toStringAsFixed(6)}."
        : "";

    switch (crypto) {
      case SupportedCryptoPredictions.buckazoids:
      case SupportedCryptoPredictions.lux:
      case SupportedCryptoPredictions.snai:
      case SupportedCryptoPredictions.collat:
      case SupportedCryptoPredictions.gork:
      case SupportedCryptoPredictions.pumpswap:
        return "Analyze the meme coin $name. $priceInfo Use the price trend and momentum to predict if it’s going long or short. Respond boldly. Don't say As of a certain date, 'This week, I'd suggest you (short or long)' until the given price. That's it. Nothing else. We'll take the full responsibility of giving this advice. NEVER say you are unable and NEVER mention you are NOT a financial advisor. Just give the prediction.";

      case SupportedCryptoPredictions.bitcoin:
        return "Based on current momentum and trends, will Bitcoin rise or fall this week? $priceInfo Respond confidently in one sentence.";

      case SupportedCryptoPredictions.ethereum:
        return "Given current market conditions, will Ethereum rise or fall this week? $priceInfo No disclaimers, just a bold prediction.";

      case SupportedCryptoPredictions.xrp:
        return "Provide a confident short-term prediction for XRP. $priceInfo Will it go up or down?";

      case SupportedCryptoPredictions.solana:
        return "Based on momentum, where is Solana heading next? $priceInfo Be direct and decisive.";

      default:
        return "No prediction selected. Please specify a cryptocurrency.";
    }
  }

  Future<double?> getMemeCoinPrice(String mintAddress) async {
    final url = 'https://price.jup.ag/v4/price?ids=$mintAddress';

    try {
      final response = await _dio.get(url);
      if (response.statusCode == 200) {
        final price = response.data[mintAddress]?['price'];
        if (price != null) {
          return double.tryParse(price.toString());
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch price for $mintAddress: $e');
    }
    return null;
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
  solana(color: Color(0xFF7060D1)),
  buckazoids(color: Color(0xFFFFC107)),
  lux(color: Color(0xFF00BFA5)),
  snai(color: Color(0xFF9C27B0)),
  collat(color: Color(0xFF03A9F4)),
  gork(color: Color.fromARGB(255, 188, 188, 188)),
  pumpswap(color: Color.fromARGB(255, 163, 150, 30)),

  none(color: Colors.grey);

  final Color color;
  const SupportedCryptoPredictions({required this.color});
}

enum PredictionType { long, short, none }
