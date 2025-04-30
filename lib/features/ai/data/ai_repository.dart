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
