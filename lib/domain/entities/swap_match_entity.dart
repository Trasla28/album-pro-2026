enum MatchType { perfect, partial }

class SwapMatchEntity {
  final String userId;
  final String userName;
  final String? avatarUrl;
  final MatchType matchType;
  final double rating;
  final List<int> theyHaveIWant;
  final List<int> iHaveTheyWant;

  const SwapMatchEntity({
    required this.userId,
    required this.userName,
    this.avatarUrl,
    required this.matchType,
    required this.rating,
    required this.theyHaveIWant,
    required this.iHaveTheyWant,
  });

  bool get isPerfect => matchType == MatchType.perfect;
}
