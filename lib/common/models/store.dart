import 'dart:math';

class Store {
  const Store({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.isOpen,
    required this.pickupPrepMinutes,
    required this.busyState,
  });

  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final bool isOpen;
  final int pickupPrepMinutes;
  final String busyState; // 'quiet', 'busy', 'very_busy'

  String get statusText {
    if (!isOpen) return 'Closed';
    switch (busyState) {
      case 'quiet':
        return 'Open • Ready now';
      case 'busy':
        return 'Open • 5-10 min wait';
      case 'very_busy':
        return 'Open • 15+ min wait';
      default:
        return 'Open';
    }
  }

  double distanceFrom(double userLat, double userLon) {
    // Simple distance calculation (not accurate for large distances)
    const double earthRadius = 6371; // km
    final dLat = _toRadians(latitude - userLat);
    final dLon = _toRadians(longitude - userLon);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(userLat) * cos(latitude) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * asin(sqrt(a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * (pi / 180);
}

class StoreState {
  const StoreState({
    required this.stores,
    required this.selectedStoreId,
    required this.userLocation,
  });

  final List<Store> stores;
  final String? selectedStoreId;
  final UserLocation? userLocation;

  Store? get selectedStore {
    if (selectedStoreId == null) return null;
    return stores.firstWhere(
      (s) => s.id == selectedStoreId,
      orElse: () => stores.first,
    );
  }

  Store? get nearestStore {
    if (userLocation == null || stores.isEmpty) return null;
    stores.sort((a, b) {
      final distA = a.distanceFrom(
        userLocation!.latitude,
        userLocation!.longitude,
      );
      final distB = b.distanceFrom(
        userLocation!.latitude,
        userLocation!.longitude,
      );
      return distA.compareTo(distB);
    });
    return stores.first;
  }
}

class UserLocation {
  const UserLocation({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}
