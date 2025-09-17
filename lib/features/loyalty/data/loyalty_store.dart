import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../domain/models.dart';
import '../../../common/services/supabase.dart';
import '../../auth/data/auth_store.dart';

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
  LoyaltyStore(this._ref)
    : super(
        LoyaltyState(
          points: 0,
          transactions: const [],
          rewards: _defaultRewards,
        ),
      );
  final Ref _ref;

  static final List<RewardItem> _defaultRewards = [
    RewardItem(id: 'r1', title: 'Free Espresso', costPoints: 50),
    RewardItem(id: 'r2', title: 'Free Latte', costPoints: 120),
    RewardItem(id: 'r3', title: 'Croissant', costPoints: 80),
  ];

  Future<void> earn(int delta, {String reason = 'Earned at counter'}) async {
    final tx = LoyaltyTransaction(
      delta: delta,
      reason: reason,
      createdAt: DateTime.now(),
    );
    state = state.copyWith(
      points: state.points + delta,
      transactions: [...state.transactions, tx],
    );
    final client = _ref.read(supabaseClientProvider);
    final session = _ref.read(authStoreProvider);
    if (client != null && session != null) {
      await client.from('loyalty_transactions').insert({
        'user_id': session.userId,
        'delta': delta,
        'reason': reason,
      });
      await client.from('loyalty_wallets').upsert({
        'user_id': session.userId,
        'points': state.points,
      });
    }
  }

  Future<bool> redeem(RewardItem reward) async {
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
    final client = _ref.read(supabaseClientProvider);
    final session = _ref.read(authStoreProvider);
    if (client != null && session != null) {
      await client.from('loyalty_transactions').insert({
        'user_id': session.userId,
        'delta': -reward.costPoints,
        'reason': 'Redeem: ${reward.title}',
      });
      await client.from('loyalty_wallets').upsert({
        'user_id': session.userId,
        'points': state.points,
      });
    }
    return true;
  }
}

final loyaltyStoreProvider = StateNotifierProvider<LoyaltyStore, LoyaltyState>((
  ref,
) {
  return LoyaltyStore(ref);
});
