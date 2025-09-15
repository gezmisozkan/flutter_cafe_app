class LoyaltyTransaction {
  LoyaltyTransaction({
    required this.delta,
    required this.reason,
    required this.createdAt,
  });

  final int delta; // positive = earn, negative = redeem
  final String reason;
  final DateTime createdAt;
}

class RewardItem {
  RewardItem({
    required this.id,
    required this.title,
    required this.costPoints,
    this.isActive = true,
  });

  final String id;
  final String title;
  final int costPoints;
  final bool isActive;
}
