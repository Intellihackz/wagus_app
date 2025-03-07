import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:flutter/material.dart';
import 'package:privy_flutter/privy_flutter.dart';
import 'package:solana_web3/solana_web3.dart' as web3;
import 'package:wagus/features/portal/data/portal_repository.dart';
import 'package:wagus/shared/holder/holder.dart';

part 'portal_event.dart';
part 'portal_state.dart';

class PortalBloc extends Bloc<PortalEvent, PortalState> {
  final PortalRepository portalRepository;

  PortalBloc({required this.portalRepository}) : super(const PortalState()) {
    on<PortalInitialEvent>(_onPortalInitialEvent);

    on<PortalAuthorizeEvent>((event, emit) async {
      final user = await portalRepository.connect();

      emit(state.copyWith(user: () => user));
    });
  }

  Future<void> _onPortalInitialEvent(
    PortalInitialEvent event,
    Emitter<PortalState> emit,
  ) async {
    final user = await portalRepository.init();
    Holder? holder;
    if (user != null) {
      holder = await getTokenAccounts(user.embeddedSolanaWallets.first.address);
    }

    emit(state.copyWith(
        holdersCount: 238, user: () => user, holder: () => holder));
  }

  Future<Holder> getTokenAccounts(String address) async {
    final cluster = web3.Cluster.mainnet;
    final connection = web3.Connection(cluster);
    final publicKey = web3.Pubkey.fromBase58(address);

    final splTokenKey =
        web3.Pubkey.fromBase58('TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA');

    try {
      final tokenAccounts = await connection.getTokenAccountsByOwner(
        publicKey,
        filter: web3.TokenAccountsFilter.programId(splTokenKey),
      );

      final tokenKey = web3.Pubkey.fromString(tokenAccounts.first.pubkey);

      final tokenAccountBalance = await connection.getTokenAccountBalance(
        tokenKey,
      );

      final tokensInSol =
          tokenAccounts.first.account.lamports / web3.lamportsPerSol;

      return Holder(
        holderType: HolderType.shrimp,
        holdings: tokensInSol,
        tokenAmount: double.parse(tokenAccountBalance.uiAmountString),
      );
    } catch (e) {
      return Holder(
        holderType: HolderType.plankton,
        holdings: 0,
        tokenAmount: 0,
      );
    }
  }
}
