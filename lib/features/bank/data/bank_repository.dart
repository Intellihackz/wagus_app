import 'dart:convert';
import 'package:flutter/foundation.dart'; // for debugPrint
import 'package:privy_flutter/privy_flutter.dart';
import 'package:privy_flutter/src/models/embedded_solana_wallet/embedded_solana_wallet.dart';
import 'package:solana/solana.dart' as solana;
import 'package:solana_web3/programs.dart';
import 'package:solana_web3/solana_web3.dart' as web3;
import 'package:wagus/extensions.dart';

class BankRepository {
  static const String techMedicMint =
      'YLu5uLRfZTLMCY9m2CBJ1czWuNJCwFkctnXn4zcrGFM';
  static const int techMedicDecimals = 9; // Verify this for Tech Medic
  static final web3.Pubkey tokenProgramId =
      web3.Pubkey.fromBase58('TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA');
  static final web3.Pubkey systemProgramId =
      web3.Pubkey.fromBase58('11111111111111111111111111111111');
  static final web3.Pubkey rentSysvarId =
      web3.Pubkey.fromBase58('SysvarRent111111111111111111111111111111111');

  Future<void> withdrawFunds({
    required EmbeddedSolanaWallet wallet,
    required int amount,
    required String destinationAddress,
  }) async {
    debugPrint('[BankRepository] Starting withdrawal...');
    debugPrint('[BankRepository] Sender Wallet: ${wallet.address}');
    debugPrint('[BankRepository] Destination Wallet: $destinationAddress');
    debugPrint('[BankRepository] Amount: $amount');

    final cluster = web3.Cluster.mainnet;
    final connection = web3.Connection(cluster);
    final blockHash = await connection.getLatestBlockhash();

    debugPrint(
        '[BankRepository] Fetched latest blockhash: ${blockHash.blockhash}');

    final amountInUnits = _calculateAmountInUnits(amount, techMedicDecimals);
    debugPrint('[BankRepository] Amount in base units: $amountInUnits');

    // Convert addresses to Pubkey
    final senderPubkey = _pubkeyFromBase58(wallet.address);
    final destinationPubkey = _pubkeyFromBase58(destinationAddress);
    final mintPubkey = _pubkeyFromBase58(techMedicMint);

    // Get sender's token account (ATA) for Tech Medic
    final sourceAta =
        await _getSenderTokenAccount(connection, senderPubkey, mintPubkey);
    if (sourceAta == null) {
      throw Exception('Sender does not have a Tech Medic token account.');
    }
    debugPrint('[BankRepository] Source ATA: ${sourceAta.toBase58()}');

    // Calculate destination ATA dynamically using solana package
    final destinationAta =
        await _getAssociatedTokenAddress(destinationPubkey, mintPubkey);
    debugPrint(
        '[BankRepository] Destination ATA: ${destinationAta.toBase58()}');

    // Prepare the transaction
    final transaction = await _prepareTransaction(
      connection,
      senderPubkey,
      destinationPubkey,
      sourceAta,
      destinationAta,
      mintPubkey,
      amountInUnits,
      blockHash.blockhash,
    );

    debugPrint('[BankRepository] Transaction prepared.');

    await _signAndSendTransaction(wallet, connection, transaction);
  }

  BigInt _calculateAmountInUnits(int amount, int decimals) {
    return BigInt.from(amount) * BigInt.from(10).pow(decimals);
  }

  Future<web3.Pubkey?> _getSenderTokenAccount(
    web3.Connection connection,
    web3.Pubkey owner,
    web3.Pubkey mint,
  ) async {
    final tokenAccounts = await connection.getTokenAccountsByOwner(
      owner,
      filter: web3.TokenAccountsFilter.mint(mint),
      config: web3.GetTokenAccountsByOwnerConfig(),
    );
    if (tokenAccounts.isEmpty) return null;

    final pubkey = web3.Pubkey.fromBase58(tokenAccounts.first.pubkey);
    return pubkey;
  }

  Future<web3.Pubkey> _getAssociatedTokenAddress(
    web3.Pubkey owner,
    web3.Pubkey mint,
  ) async {
    final solanaOwner = solana.Ed25519HDPublicKey.fromBase58(owner.toBase58());
    final solanaMint = solana.Ed25519HDPublicKey.fromBase58(mint.toBase58());
    final tokenProgramId = solana.Ed25519HDPublicKey.fromBase58(
        'TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA');
    final seeds = [solanaOwner.bytes, tokenProgramId.bytes, solanaMint.bytes];
    final solanaAta = await solana.Ed25519HDPublicKey.findProgramAddress(
      seeds: seeds,
      programId: solana.AssociatedTokenAccountProgram.id,
    );
    return web3.Pubkey.fromUint8List(solanaAta.bytes);
  }

  Future<web3.Transaction> _prepareTransaction(
    web3.Connection connection,
    web3.Pubkey senderPubkey,
    web3.Pubkey destinationPubkey,
    web3.Pubkey sourceAta,
    web3.Pubkey destinationAta,
    web3.Pubkey mintPubkey,
    BigInt amountInUnits,
    String blockhash,
  ) async {
    final instructions = <web3.TransactionInstruction>[];

    // Check if the destination ATA exists
    final destinationAccountInfo =
        await connection.getAccountInfo(destinationAta);
    if (destinationAccountInfo == null) {
      debugPrint(
          '[BankRepository] Destination ATA does not exist, creating it...');
      instructions.add(
        _createAssociatedTokenAccountInstruction(
          payer: senderPubkey,
          associatedToken: destinationAta,
          owner: destinationPubkey,
          mint: mintPubkey,
        ),
      );
    }

    // Add transfer instruction
    instructions.add(
      TokenProgram.transfer(
        source: sourceAta,
        destination: destinationAta,
        owner: senderPubkey,
        amount: amountInUnits,
      ),
    );

    return web3.Transaction.v0(
      payer: senderPubkey,
      recentBlockhash: blockhash,
      instructions: instructions,
    );
  }

  web3.TransactionInstruction _createAssociatedTokenAccountInstruction({
    required web3.Pubkey payer,
    required web3.Pubkey associatedToken,
    required web3.Pubkey owner,
    required web3.Pubkey mint,
  }) {
    final keys = [
      web3.AccountMeta(payer,
          isSigner: true, isWritable: true), // Payer (sender)
      web3.AccountMeta(associatedToken,
          isSigner: false, isWritable: true), // ATA to create
      web3.AccountMeta(owner,
          isSigner: false, isWritable: false), // Owner of the ATA
      web3.AccountMeta(mint, isSigner: false, isWritable: false), // Token mint
      web3.AccountMeta(systemProgramId,
          isSigner: false, isWritable: false), // System Program
      web3.AccountMeta(tokenProgramId,
          isSigner: false, isWritable: false), // Token Program
      web3.AccountMeta(rentSysvarId,
          isSigner: false, isWritable: false), // Rent Sysvar
    ];

    final data = Uint8List.fromList(
        [1]); // Instruction 1 for Associated Token Program (create ATA)
    return web3.TransactionInstruction(
      keys: keys,
      programId: web3.Pubkey.fromBase58(
          'ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL'), // Associated Token Program ID
      data: data,
    );
  }

  web3.Pubkey _pubkeyFromBase58(String address) {
    return web3.Pubkey.fromBase58(address);
  }

  Future<void> _signAndSendTransaction(
    EmbeddedSolanaWallet wallet,
    web3.Connection connection,
    web3.Transaction transaction,
  ) async {
    final messageBytes = transaction.serializeMessage().asUint8List();
    final base64Message = base64Encode(messageBytes);

    debugPrint('[BankRepository] Requesting signature...');
    final Result<String> result =
        await wallet.provider.signMessage(base64Message);

    if (result.isSuccess) {
      try {
        debugPrint('[BankRepository] Signature success.');
        final signature = base64Decode(result.success);
        transaction.addSignature(_pubkeyFromBase58(wallet.address), signature);

        debugPrint('[BankRepository] Sending transaction...');
        final txId = await connection.sendAndConfirmTransaction(transaction);
        debugPrint('[BankRepository] ✅ Transaction confirmed: $txId');
      } catch (e) {
        debugPrint('[BankRepository] ❌ Error during send: $e');
        rethrow;
      }
    } else {
      debugPrint(
          '[BankRepository] ❌ Failed to sign message: ${result.failure}');
      throw Exception('Failed to sign message');
    }
  }
}
