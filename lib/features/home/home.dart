import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:wagus/features/home/bloc/home_bloc.dart';
import 'package:wagus/features/home/domain/message.dart';
import 'package:wagus/features/home/widgets/home_shop_dialog.dart';
import 'package:wagus/features/portal/bloc/portal_bloc.dart';
import 'package:wagus/features/portal/data/portal_repository.dart';
import 'package:wagus/services/user_service.dart';
import 'package:wagus/theme/app_palette.dart';

class Home extends HookWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    final inputController = useTextEditingController();
    final isLoading = useState(false);

    return BlocBuilder<PortalBloc, PortalState>(
      builder: (context, portalState) {
        return BlocBuilder<HomeBloc, HomeState>(
          builder: (context, homeState) {
            return Scaffold(
              body: Stack(
                children: [
                  if (isLoading.value)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.5),
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                    ),
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        showDialog(
                          barrierDismissible: false,
                          context: context,
                          builder: (_) =>
                              HomeShopDialog(onPurchase: (tier, cost) async {
                            final portalRepository =
                                context.read<PortalRepository>();
                            final portalBloc = context.read<PortalBloc>();
                            final wallet = portalBloc
                                .state.user!.embeddedSolanaWallets.first;

                            final userDoc =
                                await UserService().getUser(wallet.address);
                            final userData = userDoc.data();
                            final currentTier =
                                (userData?['tier'] ?? 'Basic') as String;

                            // Safely convert tier string to enum
                            final desiredTier = TierStatus.values.firstWhere(
                              (e) => e.name.toLowerCase() == tier.toLowerCase(),
                              orElse: () => TierStatus.basic,
                            );

                            if (_isUpgradeInvalid(currentTier, desiredTier)) {
                              throw Exception(
                                  'You already have a higher or same tier.');
                            }

                            await portalRepository.sendTokens(
                              senderWallet: wallet,
                              fromWalletAddress: wallet.address,
                              toWalletAddress:
                                  '4R9rEp5HvMjy8RBBSW7fMBPUkYp34FEbVuctDdVfFYwY',
                              mintAddress: portalBloc.state.currentTokenAddress,
                              amount: cost,
                            );

                            await UserService()
                                .upgradeTier(wallet.address, tier);

                            if (context.mounted) {
                              context
                                  .read<PortalBloc>()
                                  .add(PortalUpdateTierEvent(
                                    desiredTier,
                                  ));
                            }
                          }),
                        );
                      },
                      child: Image.asset(
                        'assets/background/home_logo.png',
                        height: 200,
                        fit: BoxFit.cover,
                      ),
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
                              final message = homeState.messages[index];

                              String getTierPrefix(TierStatus? tier) {
                                if (tier == null ||
                                    tier == TierStatus.none ||
                                    tier == TierStatus.basic) {
                                  return '[B]';
                                }

                                final name = tier.name;
                                if (name.isEmpty) return '[B]';

                                return '[${name[0]}]';
                              }

                              return IntrinsicHeight(
                                child: Row(
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
                                    Align(
                                      alignment: Alignment.topLeft,
                                      child: RichText(
                                        text: TextSpan(
                                          children: [
                                            TextSpan(
                                              text: getTierPrefix(message.tier),
                                              style: TextStyle(
                                                color: message.tier.color,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            TextSpan(
                                              text:
                                                  '[${message.sender.substring(0, 3)}..${message.sender.substring(message.sender.length - 3)}]',
                                              style: TextStyle(
                                                color: AppPalette.contrastLight,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        homeState.messages[index].text,
                                        softWrap: true,
                                        style: TextStyle(
                                          color: AppPalette.contrastLight,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
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
                                  final text = inputController.text.trim();
                                  if (text.isNotEmpty) {
                                    context.read<HomeBloc>().add(
                                          HomeSendMessageEvent(
                                            message: Message(
                                              text: text,
                                              sender: portalState
                                                  .user!
                                                  .embeddedSolanaWallets
                                                  .first
                                                  .address,
                                              tier: portalState.tierStatus ==
                                                      TierStatus.none
                                                  ? TierStatus.basic
                                                  : portalState.tierStatus,
                                            ),
                                          ),
                                        );
                                  }
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

  bool _isUpgradeInvalid(String currentTier, TierStatus desiredTier) {
    const tiers = ['Basic', 'Adventurer', 'Elite', 'Creator'];

    final currentIndex = tiers.indexOf(currentTier);
    final desiredIndex = tiers.indexOf(desiredTier.name);

    return currentIndex >= desiredIndex;
  }
}
