import 'package:equatable/equatable.dart';

class Token extends Equatable {
  final String name;
  final String ticker;
  final String address;
  final int decimals;
  final double usdPerToken;

  const Token({
    required this.name,
    required this.ticker,
    required this.address,
    required this.decimals,
    required this.usdPerToken,
  });

  static Token empty() {
    return const Token(
      name: '',
      ticker: '',
      address: '',
      decimals: 0,
      usdPerToken: 0.0,
    );
  }

  factory Token.fromMap(Map<String, dynamic> map) {
    return Token(
      name: map['name'] ?? '',
      ticker: map['ticker'] ?? '',
      address: map['address'] ?? '',
      decimals: map['decimals'] ?? 0,
      usdPerToken: map['usdPerToken'] ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'ticker': ticker,
      'address': address,
      'decimals': decimals,
      'usdPerToken': usdPerToken,
    };
  }

  @override
  List<Object> get props => [name, ticker, address, decimals, usdPerToken];
}
