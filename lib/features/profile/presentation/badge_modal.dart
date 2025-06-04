import 'dart:convert';
import 'dart:io';

import 'package:android_id/android_id.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:privy_flutter/privy_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wagus/features/bank/data/bank_repository.dart';
import 'package:wagus/features/home/data/home_repository.dart';
import 'package:wagus/features/home/domain/message.dart';
import 'package:wagus/features/portal/bloc/portal_bloc.dart';
import 'package:wagus/theme/app_palette.dart';

class BadgeModal extends StatelessWidget {
  const BadgeModal({
    super.key,
    required this.wallet,
    required this.mint,
  });
  final EmbeddedSolanaWallet wallet;
  final String mint;

  @override
  Widget build(BuildContext context) {
    Future<void> checkEarlyAccess(String walletAddress, int wagusAmount) async {
      final deviceInfo = DeviceInfoPlugin();
      String deviceId; // declare once

      if (Platform.isAndroid) {
        const androidIdPlugin = AndroidId();
        deviceId = await androidIdPlugin.getId() ?? '';

        if (deviceId.isEmpty) {
          throw Exception('Failed to retrieve Android device ID');
        }
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? '';
      } else {
        deviceId = 'unsupported';
      }

      final response = await Dio().post(
        'https://wagus-claim-silnt-a3ca9e3fbf49.herokuapp.com/early-access',
        data: {
          'walletAddress': walletAddress,
          'deviceId': deviceId,
          'wagusAmount': wagusAmount,
        },
      );

      final result =
          response.data is String ? jsonDecode(response.data) : response.data;

      if (response.statusCode == 200) {
        // eligible
      } else {
        throw Exception(result['error'] ?? 'Unknown error');
      }
    }

    Future<List<String>> fetchClaimedBadgeIds(String wallet) async {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(wallet)
          .get();
      final data = userDoc.data();
      if (data == null) return [];
      final claimedBadges = List<String>.from(data['badges'] ?? []);
      return claimedBadges;
    }

    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Available Badges',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  if (context.canPop()) context.pop();
                },
              ),
            ],
          ),
          Expanded(
            child: FutureBuilder<List<String>>(
                future: fetchClaimedBadgeIds(wallet.address),
                builder: (context, badgeSnapshot) {
                  if (!badgeSnapshot.hasData) {
                    return Center(
                        child: CircularProgressIndicator(
                      color: context.appColors.contrastLight,
                    ));
                  }

                  final claimedBadgeIds = badgeSnapshot.data!;

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('badges')
                        .where('active', isEqualTo: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final badges = snapshot.data!.docs;

                      return ListView.builder(
                        itemCount: badges.length,
                        itemBuilder: (context, index) {
                          final badgeDoc = badges[index];
                          final badge = badgeDoc.data() as Map<String, dynamic>;
                          final badgeId = badgeDoc.id;
                          final isClaimed = claimedBadgeIds.contains(badgeId);
                          final imageProvider = CachedNetworkImageProvider(
                              badge['backgroundImgUrl']);

                          final currentClaims = badge['claimed'] ?? 0;
                          final supplyCap = badge['supplyCap'] ?? 500;
                          final isSoldOut = currentClaims >= supplyCap;

                          return FutureBuilder(
                            future: precacheImage(imageProvider, context),
                            builder: (context, imageSnapshot) {
                              final isLoaded = imageSnapshot.connectionState ==
                                  ConnectionState.done;

                              final cardContent = Container(
                                margin: const EdgeInsets.only(bottom: 20),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[900],
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white12),
                                  image: DecorationImage(
                                    image: imageProvider,
                                    fit: BoxFit.cover,
                                    colorFilter: ColorFilter.mode(
                                      Colors.black.withOpacity(0.65),
                                      BlendMode.darken,
                                    ),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      badge['name'],
                                      style: const TextStyle(
                                        fontSize: 18,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      badge['description'],
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    if (badge['traits'] is Map)
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 6,
                                        children: (badge['traits']
                                                as Map<String, dynamic>)
                                            .entries
                                            .map((entry) => Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 10,
                                                      vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white10,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: Text(
                                                    '${entry.key}: ${entry.value}',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontFamily: 'monospace',
                                                    ),
                                                  ),
                                                ))
                                            .toList(),
                                      ),
                                    const SizedBox(height: 12),
                                    Text(
                                      badge['priceUSD'] != null
                                          ? '\$${badge['priceUSD'].toString()}'
                                          : 'Free',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color.fromARGB(
                                                  255, 61, 26, 31)
                                              .withOpacity(0.2),
                                          foregroundColor: Colors.white,
                                          shadowColor: Colors.transparent,
                                          elevation: 0,
                                          side: BorderSide(
                                            color: const Color.fromARGB(
                                                255, 101, 17, 17),
                                            width: 1,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 14),
                                        ),
                                        onPressed: isSoldOut
                                            ? null
                                            : () async {
                                                print(
                                                    'testing! is claimed: $isClaimed');
                                                if (isClaimed) {
                                                  if (context.canPop())
                                                    context.pop();
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content: const Text(
                                                        'Badge already claimed',
                                                        style: TextStyle(
                                                            color: Colors.red),
                                                      ),
                                                    ),
                                                  );
                                                  return;
                                                }

                                                final portalState = context
                                                    .read<PortalBloc>()
                                                    .state;
                                                final usdTarget =
                                                    double.tryParse(badge[
                                                                    'priceUSD']
                                                                ?.toString() ??
                                                            '') ??
                                                        0.0;

                                                final usdPerToken = portalState
                                                    .selectedToken.usdPerToken
                                                    .toDouble();

                                                if (badgeId ==
                                                    'PoHkntyQUX2fKnAJbPvO') {
                                                  final wagusBalance =
                                                      portalState.holder
                                                              ?.tokenAmount ??
                                                          0;

                                                  try {
                                                    if (portalState
                                                            .selectedToken
                                                            .ticker !=
                                                        'WAGUS') {
                                                      throw Exception(
                                                          'You must select WAGUS to claim this badge.');
                                                    }
                                                    await checkEarlyAccess(
                                                        wallet.address,
                                                        wagusBalance.toInt());
                                                  } catch (e) {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          e
                                                              .toString()
                                                              .replaceAll(
                                                                  'Exception: ',
                                                                  ''),
                                                          style:
                                                              const TextStyle(
                                                                  color: Colors
                                                                      .red),
                                                        ),
                                                      ),
                                                    );
                                                    return; // prevent claim
                                                  }
                                                }
                                                final tokenAmount =
                                                    (usdTarget / usdPerToken)
                                                        .ceil();

                                                try {
                                                  final treasuryWallet = dotenv
                                                          .env[
                                                      'TREASURY_WALLET_ADDRESS'];
                                                  if (treasuryWallet == null)
                                                    throw Exception(
                                                        "Missing treasury wallet");

                                                  final currentTokenAddress =
                                                      context
                                                          .read<PortalBloc>()
                                                          .state
                                                          .selectedToken
                                                          .address;
                                                  final amount = double.tryParse(
                                                          badge['priceUSD']
                                                                  ?.toString() ??
                                                              '0') ??
                                                      0.0;

                                                  final decimals = context
                                                      .read<PortalBloc>()
                                                      .state
                                                      .selectedToken
                                                      .decimals;

                                                  if (usdTarget > 0) {
                                                    final txId = await context
                                                        .read<BankRepository>()
                                                        .withdrawFunds(
                                                          wallet: wallet,
                                                          amount: tokenAmount,
                                                          destinationAddress:
                                                              treasuryWallet,
                                                          wagusMint:
                                                              currentTokenAddress,
                                                          decimals: decimals,
                                                        );

                                                    await Dio().post(
                                                      'https://wagus-claim-silnt-a3ca9e3fbf49.herokuapp.com/claim-badge',
                                                      data: {
                                                        'userWallet':
                                                            wallet.address,
                                                        'amount': amount,
                                                        'badgeId': badgeId,
                                                        'txSignature': txId,
                                                      },
                                                      options:
                                                          Options(headers: {
                                                        'Authorization':
                                                            'Bearer ${dotenv.env['INTERNAL_API_KEY']}',
                                                      }),
                                                    );
                                                  } else {
                                                    await Dio().post(
                                                      'https://wagus-claim-silnt-a3ca9e3fbf49.herokuapp.com/claim-badge',
                                                      data: {
                                                        'userWallet':
                                                            wallet.address,
                                                        'amount': amount,
                                                        'badgeId': badgeId,
                                                        'txSignature': 'Free'
                                                      },
                                                      options:
                                                          Options(headers: {
                                                        'Authorization':
                                                            'Bearer ${dotenv.env['INTERNAL_API_KEY']}',
                                                      }),
                                                    );
                                                  }

                                                  final message = Message(
                                                    text:
                                                        '[BADGE] ${wallet.address.substring(0, 4)}...${wallet.address.substring(wallet.address.length - 4)} claimed the "${badge['name']}" badge 🏅',
                                                    sender: 'System',
                                                    tier: TierStatus.system,
                                                    room: 'General',
                                                    likedBy: [],
                                                  );

                                                  await context
                                                      .read<HomeRepository>()
                                                      .sendMessage(message);

                                                  if (context.canPop())
                                                    context.pop();
                                                } catch (e) {
                                                  debugPrint(
                                                      "Badge purchase failed: $e");
                                                  // Optional: show SnackBar or error dialog
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        badge['requirements'] ??
                                                            'Failed to purchase badge: $e',
                                                        style: const TextStyle(
                                                            color: Colors.red),
                                                      ),
                                                    ),
                                                  );

                                                  if (context.canPop()) {
                                                    context.pop();
                                                  }

                                                  return;
                                                }
                                              },
                                        child: Text(
                                          isClaimed
                                              ? 'Claimed'
                                              : isSoldOut
                                                  ? 'Sold Out'
                                                  : badge['priceUSD'] != null
                                                      ? 'Buy Badge'
                                                      : 'Claim for Free',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.6,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );

                              return isLoaded
                                  ? cardContent
                                  : Shimmer.fromColors(
                                      baseColor:
                                          Colors.grey.shade800.withOpacity(0.5),
                                      highlightColor: Colors.grey.shade600,
                                      child: Container(
                                        height: 220,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[900],
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                      ),
                                    );
                            },
                          );
                        },
                      );
                    },
                  );
                }),
          ),
        ],
      ),
    );
  }
}
