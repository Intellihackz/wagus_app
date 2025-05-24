class GuessEntry {
  final String wallet;
  final String guess;

  GuessEntry({required this.wallet, required this.guess});

  factory GuessEntry.fromMap(Map<String, dynamic> data) {
    return GuessEntry(
      wallet: data['wallet'],
      guess: data['guess'],
    );
  }

  Map<String, dynamic> toMap() => {
        'wallet': wallet,
        'guess': guess,
      };
}
