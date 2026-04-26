/// Prémios em moedas (Luminárias) exibidos no ranking mensal — valores da app; ajuste aqui se mudar a política.
abstract final class GlobalRankPrizes {
  static int coinsForRank(int rank) {
    if (rank <= 0) return 0;
    switch (rank) {
      case 1:
        return 500;
      case 2:
        return 300;
      case 3:
        return 150;
      case 4:
        return 100;
      case 5:
        return 75;
      case 6:
        return 60;
      case 7:
        return 50;
      case 8:
        return 40;
      case 9:
        return 30;
      case 10:
        return 25;
      default:
        return 15;
    }
  }

  /// Linhas para a tabela de prémios (top N).
  static List<({int rank, int coins})> prizeRows({int maxRank = 10}) {
    return List.generate(maxRank, (i) {
      final r = i + 1;
      return (rank: r, coins: coinsForRank(r));
    });
  }
}
