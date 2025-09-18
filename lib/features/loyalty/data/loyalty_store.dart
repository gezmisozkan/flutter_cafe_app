import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
      ) {
    _loadWalletData();
  }
  final Ref _ref;

  static final List<RewardItem> _defaultRewards = [
    RewardItem(id: 'r1', title: 'Free Espresso', costPoints: 50),
    RewardItem(id: 'r2', title: 'Free Latte', costPoints: 120),
    RewardItem(id: 'r3', title: 'Croissant', costPoints: 80),
  ];

  Future<void> _loadWalletData() async {
    // Use mock data for UI testing
    state = LoyaltyState(
      points: 150, // Mock points for testing
      transactions: [
        LoyaltyTransaction(
          delta: 50,
          reason: 'Welcome bonus',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        LoyaltyTransaction(
          delta: 30,
          reason: 'Order completed',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        LoyaltyTransaction(
          delta: 70,
          reason: 'Order completed',
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        ),
      ],
      rewards: _defaultRewards,
    );

    // Uncomment below to re-enable Firebase/Supabase
    // final session = _ref.read(authStoreProvider);
    // if (session == null) return;

    // try {
    //   // Try Firestore first
    //   await _loadFromFirestore(session.userId);
    // } catch (_) {
    //   // Fallback to Supabase
    //   try {
    //     await _loadFromSupabase(session.userId);
    //   } catch (_) {
    //     // Keep default state on error
    //   }
    // }
  }

  Future<void> _loadFromFirestore(String userId) async {
    final firestore = FirebaseFirestore.instance;

    // Load wallet points
    final walletDoc = await firestore.doc('loyalty_wallets/$userId').get();
    int points = 0;
    if (walletDoc.exists) {
      final data = walletDoc.data();
      points = (data?['points'] as num?)?.toInt() ?? 0;
    }

    // Load transactions
    final transactionsSnap = await firestore
        .collection('loyalty_wallets/$userId/ledger')
        .orderBy('created_at', descending: true)
        .limit(50)
        .get();

    final transactions = transactionsSnap.docs.map((doc) {
      final data = doc.data();
      return LoyaltyTransaction(
        delta: (data['delta'] as num?)?.toInt() ?? 0,
        reason: data['reason'] as String? ?? 'Transaction',
        createdAt:
            (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    }).toList();

    state = state.copyWith(points: points, transactions: transactions);
  }

  Future<void> _loadFromSupabase(String userId) async {
    final client = _ref.read(supabaseClientProvider);
    if (client == null) return;

    // Load wallet points
    final wallet = await client
        .from('loyalty_wallets')
        .select('points')
        .eq('user_id', userId)
        .maybeSingle();

    int points = 0;
    if (wallet != null) {
      points = (wallet['points'] as num?)?.toInt() ?? 0;
    }

    // Load transactions
    final transactionsData = await client
        .from('loyalty_transactions')
        .select('delta, reason, created_at')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50);

    final transactions = (transactionsData as List).map((data) {
      return LoyaltyTransaction(
        delta: (data['delta'] as num?)?.toInt() ?? 0,
        reason: data['reason'] as String? ?? 'Transaction',
        createdAt: DateTime.parse(data['created_at'] as String),
      );
    }).toList();

    state = state.copyWith(points: points, transactions: transactions);
  }

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

    final session = _ref.read(authStoreProvider);
    if (session == null) return;

    try {
      // Try Firestore first
      await _saveToFirestore(session.userId, tx);
    } catch (_) {
      // Fallback to Supabase
      try {
        await _saveToSupabase(session.userId, tx);
      } catch (_) {
        // Keep local state even if save fails
      }
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

    final session = _ref.read(authStoreProvider);
    if (session == null) return false;

    try {
      // Try Firestore first
      await _saveToFirestore(session.userId, tx);
    } catch (_) {
      // Fallback to Supabase
      try {
        await _saveToSupabase(session.userId, tx);
      } catch (_) {
        // Keep local state even if save fails
      }
    }
    return true;
  }

  Future<void> _saveToFirestore(String userId, LoyaltyTransaction tx) async {
    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();

    // Save transaction to ledger
    final txRef = firestore.collection('loyalty_wallets/$userId/ledger').doc();
    batch.set(txRef, {
      'delta': tx.delta,
      'reason': tx.reason,
      'created_at': Timestamp.fromDate(tx.createdAt),
    });

    // Update wallet points
    final walletRef = firestore.doc('loyalty_wallets/$userId');
    batch.set(walletRef, {
      'points': state.points,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  Future<void> _saveToSupabase(String userId, LoyaltyTransaction tx) async {
    final client = _ref.read(supabaseClientProvider);
    if (client == null) return;

    await client.from('loyalty_transactions').insert({
      'user_id': userId,
      'delta': tx.delta,
      'reason': tx.reason,
    });
    await client.from('loyalty_wallets').upsert({
      'user_id': userId,
      'points': state.points,
    });
  }
}

final loyaltyStoreProvider = StateNotifierProvider<LoyaltyStore, LoyaltyState>((
  ref,
) {
  return LoyaltyStore(ref);
});
