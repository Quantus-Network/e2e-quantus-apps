import 'package:shared_preferences/shared_preferences.dart';

class RecentAddressesService {
  static const String _storageKey = 'recent_addresses';
  static const int _maxSize = 100;
  
  /// Maximum address length in characters.
  /// Typical blockchain addresses are 32-64 chars; 256 provides headroom for
  /// longer formats while preventing storage abuse from oversized inputs.
  static const int maxAddressLength = 256;

  static final RecentAddressesService _instance = RecentAddressesService._internal();

  factory RecentAddressesService() {
    return _instance;
  }

  RecentAddressesService._internal();

  /// Adds an address to the recent addresses list.
  /// 
  /// Returns `false` if the address exceeds [maxAddressLength] and was not added.
  /// Returns `true` if the address was successfully added.
  Future<bool> addAddress(String address) async {
    // Reject oversized addresses to prevent storage abuse
    if (address.length > maxAddressLength) {
      return false;
    }
    
    final prefs = await SharedPreferences.getInstance();
    List<String> addresses = await getAddresses();

    // Remove if already exists to avoid duplicates
    addresses.remove(address);

    // Add to the beginning (most recent first)
    addresses.insert(0, address);

    // Cap at max size
    if (addresses.length > _maxSize) {
      addresses = addresses.sublist(0, _maxSize);
    }

    // Save back
    await prefs.setStringList(_storageKey, addresses);
    return true;
  }

  Future<List<String>> getAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    final addresses = prefs.getStringList(_storageKey) ?? [];
    // Filter out any oversized addresses that may have been stored previously
    return addresses.where((a) => a.length <= maxAddressLength).toList();
  }
}
