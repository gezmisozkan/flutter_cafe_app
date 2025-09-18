import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/store.dart';

class StoreService {
  StoreService(this._firestore);

  final FirebaseFirestore _firestore;

  Future<List<Store>> getStores() async {
    // Use mock data for UI testing
    return _getMockStores();

    // Uncomment below to re-enable Firebase
    // try {
    //   final snapshot = await _firestore
    //       .collection('stores')
    //       .where('active', isEqualTo: true)
    //       .get(const GetOptions(source: Source.serverAndCache));

    //   return snapshot.docs.map((doc) {
    //     final data = doc.data();
    //     return Store(
    //       id: doc.id,
    //       name: data['name'] as String? ?? 'Store',
    //       address: data['address'] as String? ?? '',
    //       latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
    //       longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
    //       isOpen: data['is_open'] as bool? ?? true,
    //       pickupPrepMinutes:
    //           (data['pickup_prep_minutes'] as num?)?.toInt() ?? 10,
    //       busyState: data['busy_state'] as String? ?? 'quiet',
    //     );
    //   }).toList();
    // } catch (_) {
    //   // Return mock data for MVP
    //   return _getMockStores();
    // }
  }

  List<Store> _getMockStores() {
    return [
      const Store(
        id: 'store1',
        name: 'Downtown Cafe',
        address: '123 Main St, Downtown',
        latitude: 40.7128,
        longitude: -74.0060,
        isOpen: true,
        pickupPrepMinutes: 5,
        busyState: 'quiet',
      ),
      const Store(
        id: 'store2',
        name: 'University Branch',
        address: '456 College Ave, University District',
        latitude: 40.7589,
        longitude: -73.9851,
        isOpen: true,
        pickupPrepMinutes: 15,
        busyState: 'busy',
      ),
      const Store(
        id: 'store3',
        name: 'Airport Location',
        address: '789 Terminal Blvd, Airport',
        latitude: 40.6892,
        longitude: -74.1745,
        isOpen: false,
        pickupPrepMinutes: 20,
        busyState: 'quiet',
      ),
    ];
  }
}

class StoreNotifier extends StateNotifier<StoreState> {
  StoreNotifier(this._service)
    : super(
        const StoreState(stores: [], selectedStoreId: null, userLocation: null),
      ) {
    _loadStores();
  }

  final StoreService _service;

  Future<void> _loadStores() async {
    try {
      final stores = await _service.getStores();
      state = StoreState(
        stores: stores,
        selectedStoreId: state.selectedStoreId,
        userLocation: state.userLocation,
      );
    } catch (_) {
      // Keep current state on error
    }
  }

  void selectStore(String storeId) {
    state = StoreState(
      stores: state.stores,
      selectedStoreId: storeId,
      userLocation: state.userLocation,
    );
  }

  void setUserLocation(UserLocation location) {
    state = StoreState(
      stores: state.stores,
      selectedStoreId: state.selectedStoreId,
      userLocation: location,
    );
  }

  Future<void> refresh() async {
    await _loadStores();
  }
}

final storeServiceProvider = Provider<StoreService>((ref) {
  return StoreService(FirebaseFirestore.instance);
});

final storeProvider = StateNotifierProvider<StoreNotifier, StoreState>((ref) {
  final service = ref.watch(storeServiceProvider);
  return StoreNotifier(service);
});
