import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../domain/models.dart';

class LoyaltyState {
  const LoyaltyState({
    required this.points,
    required this.transactions,
    required this.rewards,
  });

  final int points;
  final List<LoyaltyTransaction> transactions;
  final List<RewardItem> rewards;

  LoyaltyState copyWith({
    int? points,
    List<LoyaltyTransaction>? transactions,
    List<RewardItem>? rewards,
  }) {
    return LoyaltyState(
      points: points ?? this.points,
      transactions: transactions ?? this.transactions,
      rewards: rewards ?? this.rewards,
    );
  }
}

class LoyaltyStore extends StateNotifier<LoyaltyState> {
  LoyaltyStore()
    : super(
        LoyaltyState(
          points: 0,
          transactions: const [],
          rewards: _defaultRewards,
        ),
      );

  static final List<RewardItem> _defaultRewards = [
    RewardItem(id: 'r1', title: 'Free Espresso', costPoints: 50),
    RewardItem(id: 'r2', title: 'Free Latte', costPoints: 120),
    RewardItem(id: 'r3', title: 'Croissant', costPoints: 80),
  ];

  void earn(int delta, {String reason = 'Earned at counter'}) {
    final tx = LoyaltyTransaction(
      delta: delta,
      reason: reason,
      createdAt: DateTime.now(),
    );
    state = state.copyWith(
      points: state.points + delta,
      transactions: [...state.transactions, tx],
    );
  }

  bool redeem(RewardItem reward) {
    if (state.points < reward.costPoints) return false;
    final tx = LoyaltyTransaction(
      delta: -reward.costPoints,
      reason: 'Redeem: ${reward.title}',
      createdAt: DateTime.now(),
    );
    state = state.copyWith(
      points: state.points - reward.costPoints,
      transactions: [...state.transactions, tx],
    );
    return true;
  }
}

final loyaltyStoreProvider = StateNotifierProvider<LoyaltyStore, LoyaltyState>((
  ref,
) {
  return LoyaltyStore();
});
