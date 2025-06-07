import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:flutter/foundation.dart'; // for debugPrint
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/ecc/api.dart';
import 'package:pointycastle/ecc/curves/secp256r1.dart';
import 'package:pointycastle/key_generators/api.dart';
import 'package:pointycastle/key_generators/ec_key_generator.dart';
import 'package:privy_flutter/privy_flutter.dart';
import 'package:solana/solana.dart' as solana;
import 'package:solana_web3/programs.dart';
import 'package:solana_web3/solana_web3.dart' as web3;
import 'package:wagus/core/extensions/extensions.dart';

class BankRepository {
  final Dio _dio = Dio();
  final String _baseUrl = 'https://api.privy.io/v1';

  // static const int wagusDecimals = 6;
  static final web3.Pubkey tokenProgramId =
      web3.Pubkey.fromBase58('TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA');
  static final web3.Pubkey systemProgramId =
      web3.Pubkey.fromBase58('11111111111111111111111111111111');
  static final web3.Pubkey rentSysvarId =
      web3.Pubkey.fromBase58('SysvarRent111111111111111111111111111111111');

  final String _privyAppId = dotenv.env['PRIVY_APP_ID'] ?? '';
  final String _privySecretId =
      dotenv.env['PRIVY_SECRET_ID'] ?? ''; // App secret

  BankRepository() {
    _dio.options.headers['privy-app-id'] = _privyAppId;
    _dio.options.headers['Content-Type'] = 'application/json';
    _dio.options.headers['Authorization'] =
        'Basic ${base64Encode(utf8.encode("$_privyAppId:$_privySecretId"))}';

    _dio.interceptors.add(
      RetryInterceptor(
        dio: _dio,
        retries: 3,
        retryDelays: const [
          Duration(seconds: 1),
          Duration(seconds: 2),
          Duration(seconds: 3),
        ],
        retryEvaluator: (e, attempt) {
          if (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout ||
              e.type == DioExceptionType.sendTimeout) {
            return true;
          }

          final status = e.response?.statusCode;
          return [429, 500, 502, 503, 504].contains(status);
        },
      ),
    );
  }

  Future<String> withdrawFunds({
    required EmbeddedSolanaWallet wallet,
    required int amount,
    required String destinationAddress,
    required String wagusMint,
    required int decimals,
  }) async {
    debugPrint('[BankRepository] Starting withdrawal...');
    debugPrint('[BankRepository] Sender Wallet: ${wallet.address}');
    debugPrint('[BankRepository] Destination Wallet: $destinationAddress');
    debugPrint('[BankRepository] Amount: $amount');

    final rpcUrl = dotenv.env['HELIUS_RPC']!;
    final wsUrl = dotenv.env['HELIUS_WS']!;

    final connection = web3.Connection(
      web3.Cluster(Uri.parse(rpcUrl)),
      websocketCluster: web3.Cluster(Uri.parse(wsUrl)),
    );
    final blockHash = await connection.getLatestBlockhash();

    debugPrint(
        '[BankRepository] Fetched latest blockhash: ${blockHash.blockhash}');

    final amountInUnits = _calculateAmountInUnits(amount, decimals);
    debugPrint('[BankRepository] Amount in base units: $amountInUnits');

    // Convert addresses to Pubkey
    final senderPubkey = _pubkeyFromBase58(wallet.address);
    final destinationPubkey = _pubkeyFromBase58(destinationAddress);
    final mintPubkey = _pubkeyFromBase58(wagusMint);

    // Get sender's token account (ATA) for the specified mint
    final sourceAta =
        await _getSenderTokenAccount(connection, senderPubkey, mintPubkey);
    if (sourceAta == null) {
      throw Exception('Sender does not have the minted token account.');
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

    return await _signAndSendTransaction(wallet, connection, transaction);
  }

  Future<void> withdrawSol({
    required EmbeddedSolanaWallet wallet,
    required double solAmount,
    required String destinationAddress,
  }) async {
    debugPrint('[BankRepository] Starting SOL withdrawal...');
    debugPrint('[BankRepository] Sender Wallet: ${wallet.address}');
    debugPrint('[BankRepository] Destination Wallet: $destinationAddress');
    debugPrint('[BankRepository] SOL Amount: $solAmount');

    final connection = web3.Connection(
      web3.Cluster(Uri.parse(dotenv.env['HELIUS_RPC']!)),
      websocketCluster: web3.Cluster(Uri.parse(dotenv.env['HELIUS_WS']!)),
    );
    final blockHash = await connection.getLatestBlockhash();

    debugPrint(
        '[BankRepository] Fetched latest blockhash: ${blockHash.blockhash}');

    // Convert SOL to lamports (1 SOL = 1,000,000,000 lamports)
    final lamports = (solAmount * web3.lamportsPerSol).toInt();
    debugPrint('[BankRepository] Amount in lamports: $lamports');

    // Convert addresses to Pubkey
    final senderPubkey = _pubkeyFromBase58(wallet.address);
    final destinationPubkey = _pubkeyFromBase58(destinationAddress);

    // Prepare the transaction for SOL transfer
    final transaction = await _prepareSolTransaction(
      connection,
      senderPubkey,
      destinationPubkey,
      lamports,
      blockHash.blockhash,
    );

    debugPrint('[BankRepository] SOL Transaction prepared.');

    await _signAndSendTransaction(wallet, connection, transaction);
  }

  Future<web3.Transaction> _prepareSolTransaction(
    web3.Connection connection,
    web3.Pubkey senderPubkey,
    web3.Pubkey destinationPubkey,
    int lamports,
    String blockhash,
  ) async {
    final instructions = <web3.TransactionInstruction>[];

    // Add System Program transfer instruction for SOL
    instructions.add(
      SystemProgram.transfer(
        fromPubkey: senderPubkey,
        toPubkey: destinationPubkey,
        lamports: lamports.toBigInt(),
      ),
    );

    return web3.Transaction.v0(
      payer: senderPubkey,
      recentBlockhash: blockhash,
      instructions: instructions,
    );
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

  Future<String> _signAndSendTransaction(
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

        return txId;
      } catch (e) {
        debugPrint('[BankRepository] ❌ Error during send: $e');
        throw Exception('Failed to send transaction: $e');
      }
    } else {
      debugPrint(
          '[BankRepository] ❌ Failed to sign message: ${result.failure}');
      throw Exception('Failed to sign message');
    }
  }

  Future<String> _generateRecipientPublicKey() async {
    final curve = ECCurve_secp256r1();
    final keyGen = ECKeyGenerator()
      ..init(ParametersWithRandom(
          ECKeyGeneratorParameters(curve), SecureRandom('Fortuna')));
    final keyPair = keyGen.generateKeyPair();
    final publicKey = keyPair.publicKey as ECPublicKey;

    final qBytes = publicKey.Q!.getEncoded(false);
    final base64PublicKey = base64Encode(qBytes);

    debugPrint('Generated Recipient Public Key: $base64PublicKey');
    return base64PublicKey;
  }

  Future<List<Map<String, dynamic>>> _getWallets() async {
    final url = '$_baseUrl/wallets';

    try {
      final response = await _dio.get(url);
      debugPrint('[BankRepository] Get wallets response: ${response.data}');
      return List<Map<String, dynamic>>.from(response.data['wallets'] ?? []);
    } catch (e) {
      debugPrint('[BankRepository] Failed to fetch wallets: $e');
      if (e is DioException) debugPrint('Dio Error: ${e.response?.data}');
      throw Exception('Failed to fetch wallets: $e');
    }
  }

  Future<(String, String)> exportWalletPrivateKey({
    required EmbeddedSolanaWallet wallet,
  }) async {
    debugPrint('[BankRepository] Starting wallet private key export...');

    // Step 1: Fetch all wallets from Privy API
    final wallets = await _getWallets();

    // Step 2: Find the wallet ID matching the provided wallet's address
    final matchingWallet = wallets.firstWhere(
      (w) => w['address'] == wallet.address,
      orElse: () => throw Exception(
          'No matching wallet found for address: ${wallet.address}'),
    );
    final walletId = matchingWallet['id'] as String;

    debugPrint('[BankRepository] Matched Wallet ID: $walletId');

    // Step 3: Export the private key with HPKE
    final url = '$_baseUrl/wallets/$walletId/export';
    final recipientPublicKey = await _generateRecipientPublicKey();
    final body = {
      'encryption_type': 'HPKE',
      'recipient_public_key': recipientPublicKey,
    };

    try {
      final response = await _dio.post(url, data: body);
      debugPrint('[BankRepository] Export API response: ${response.data}');

      final encryptionType = response.data['encryption_type'] as String;
      final ciphertext = response.data['ciphertext'] as String;
      final encapsulatedKey = response.data['encapsulated_key'] as String;

      if (encryptionType != 'HPKE') {
        throw Exception('Unexpected encryption type: $encryptionType');
      }

      debugPrint('[BankRepository] Private key exported successfully');
      return (ciphertext, encapsulatedKey);
    } catch (e) {
      debugPrint('[BankRepository] Failed to export private key: $e');
      if (e is DioException) debugPrint('Dio Error: ${e.response?.data}');
      throw Exception('Failed to export wallet private key: $e');
    }
  }

  Future<void> deleteUser(String userId) async {
    final url = '$_baseUrl/users/$userId';

    try {
      final response = await _dio.delete(url);
      if (response.statusCode == 204) {
        debugPrint('[BankRepository] ✅ User deleted successfully');
      } else {
        debugPrint(
            '[BankRepository] ❌ Failed to delete user, unexpected status code: ${response.statusCode}');
        throw Exception('Unexpected status code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[BankRepository] ❌ Error deleting user: $e');
      if (e is DioException) debugPrint('Dio Error: ${e.response?.data}');
      throw Exception('Failed to delete user: $e');
    }
  }
}
