import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'analytics_service.dart';

class LocationService {
  static Position? _currentPosition;
  static String? _currentAddress;
  static StreamSubscription<Position>? _positionStream;
  static final List<LocationListener> _listeners = [];

  // Campus locations (predefined)
  static const Map<String, CampusLocation> campusLocations = {
    'library': CampusLocation(
      id: 'library',
      name: 'Main Library',
      latitude: 40.7128,
      longitude: -74.0060,
      description: 'Central campus library',
    ),
    'student_center': CampusLocation(
      id: 'student_center',
      name: 'Student Center',
      latitude: 40.7130,
      longitude: -74.0058,
      description: 'Main student activities building',
    ),
    'cafeteria': CampusLocation(
      id: 'cafeteria',
      name: 'Main Cafeteria',
      latitude: 40.7125,
      longitude: -74.0062,
      description: 'Primary dining facility',
    ),
    'gym': CampusLocation(
      id: 'gym',
      name: 'Fitness Center',
      latitude: 40.7132,
      longitude: -74.0055,
      description: 'Campus fitness and recreation center',
    ),
    'parking_lot_a': CampusLocation(
      id: 'parking_lot_a',
      name: 'Parking Lot A',
      latitude: 40.7120,
      longitude: -74.0070,
      description: 'Main parking area',
    ),
    'dormitory_north': CampusLocation(
      id: 'dormitory_north',
      name: 'North Dormitory',
      latitude: 40.7135,
      longitude: -74.0050,
      description: 'North campus residence hall',
    ),
    'dormitory_south': CampusLocation(
      id: 'dormitory_south',
      name: 'South Dormitory',
      latitude: 40.7115,
      longitude: -74.0065,
      description: 'South campus residence hall',
    ),
    'academic_building_1': CampusLocation(
      id: 'academic_building_1',
      name: 'Academic Building 1',
      latitude: 40.7127,
      longitude: -74.0057,
      description: 'Main academic building',
    ),
    'academic_building_2': CampusLocation(
      id: 'academic_building_2',
      name: 'Academic Building 2',
      latitude: 40.7129,
      longitude: -74.0059,
      description: 'Secondary academic building',
    ),
    'sports_field': CampusLocation(
      id: 'sports_field',
      name: 'Sports Field',
      latitude: 40.7140,
      longitude: -74.0045,
      description: 'Outdoor sports and recreation area',
    ),
  };

  // Initialize location service
  static Future<void> initialize() async {
    try {
      final hasPermission = await checkLocationPermission();
      if (hasPermission) {
        await getCurrentLocation();
      }
      
      if (kDebugMode) {
        print('Location service initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing location service: $e');
      }
    }
  }

  // Check location permission
  static Future<bool> checkLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.deniedForever) {
        return false;
      }
      
      return permission == LocationPermission.whileInUse || 
             permission == LocationPermission.always;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking location permission: $e');
      }
      return false;
    }
  }

  // Get current location
  static Future<Position?> getCurrentLocation({bool forceRefresh = false}) async {
    try {
      if (!forceRefresh && _currentPosition != null) {
        return _currentPosition;
      }

      final hasPermission = await checkLocationPermission();
      if (!hasPermission) {
        return null;
      }

      final isLocationEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isLocationEnabled) {
        throw LocationServiceDisabledException();
      }

      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // Get address for current position
      if (_currentPosition != null) {
        _currentAddress = await getAddressFromCoordinates(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        );
      }

      // Notify listeners
      _notifyListeners(_currentPosition);

      // Log analytics
      await AnalyticsService.logFeatureUsed(
        featureName: 'location_obtained',
        parameters: {
          'accuracy': _currentPosition?.accuracy,
          'has_address': _currentAddress != null,
        },
      );

      return _currentPosition;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting current location: $e');
      }
      
      await AnalyticsService.logError(
        errorType: 'location_error',
        errorMessage: e.toString(),
      );
      
      return null;
    }
  }

  // Get address from coordinates
  static Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        return '${placemark.street}, ${placemark.locality}, ${placemark.administrativeArea}';
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting address from coordinates: $e');
      }
    }
    return null;
  }

  // Get coordinates from address
  static Future<List<Location>> getCoordinatesFromAddress(String address) async {
    try {
      return await locationFromAddress(address);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting coordinates from address: $e');
      }
      return [];
    }
  }

  // Calculate distance between two points
  static double calculateDistance(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  // Calculate bearing between two points
  static double calculateBearing(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    return Geolocator.bearingBetween(lat1, lon1, lat2, lon2);
  }

  // Find nearest campus location
  static CampusLocation? findNearestCampusLocation(double latitude, double longitude) {
    if (campusLocations.isEmpty) return null;

    CampusLocation? nearest;
    double minDistance = double.infinity;

    for (final location in campusLocations.values) {
      final distance = calculateDistance(
        latitude, longitude,
        location.latitude, location.longitude,
      );
      
      if (distance < minDistance) {
        minDistance = distance;
        nearest = location;
      }
    }

    return nearest;
  }

  // Get campus locations within radius
  static List<CampusLocation> getCampusLocationsWithinRadius(
    double latitude, double longitude, double radiusInMeters,
  ) {
    final locationsWithinRadius = <CampusLocation>[];

    for (final location in campusLocations.values) {
      final distance = calculateDistance(
        latitude, longitude,
        location.latitude, location.longitude,
      );
      
      if (distance <= radiusInMeters) {
        locationsWithinRadius.add(location);
      }
    }

    // Sort by distance
    locationsWithinRadius.sort((a, b) {
      final distanceA = calculateDistance(latitude, longitude, a.latitude, a.longitude);
      final distanceB = calculateDistance(latitude, longitude, b.latitude, b.longitude);
      return distanceA.compareTo(distanceB);
    });

    return locationsWithinRadius;
  }

  // Start location tracking
  static Future<void> startLocationTracking({
    Duration interval = const Duration(seconds: 30),
    double distanceFilter = 10.0,
  }) async {
    try {
      final hasPermission = await checkLocationPermission();
      if (!hasPermission) return;

      _positionStream?.cancel();

      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      );

      _positionStream = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) {
          _currentPosition = position;
          _notifyListeners(position);
          
          // Update address periodically
          getAddressFromCoordinates(position.latitude, position.longitude)
              .then((address) => _currentAddress = address);
        },
        onError: (error) {
          if (kDebugMode) {
            print('Location tracking error: $error');
          }
        },
      );

      if (kDebugMode) {
        print('Location tracking started');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error starting location tracking: $e');
      }
    }
  }

  // Stop location tracking
  static Future<void> stopLocationTracking() async {
    await _positionStream?.cancel();
    _positionStream = null;
    
    if (kDebugMode) {
      print('Location tracking stopped');
    }
  }

  // Add location listener
  static void addLocationListener(LocationListener listener) {
    _listeners.add(listener);
  }

  // Remove location listener
  static void removeLocationListener(LocationListener listener) {
    _listeners.remove(listener);
  }

  // Notify listeners
  static void _notifyListeners(Position? position) {
    for (final listener in _listeners) {
      listener.onLocationChanged(position);
    }
  }

  // Get current position (cached)
  static Position? get currentPosition => _currentPosition;

  // Get current address (cached)
  static String? get currentAddress => _currentAddress;

  // Check if location is on campus
  static bool isLocationOnCampus(double latitude, double longitude, {double radiusInMeters = 1000}) {
    // Define campus center (you should update these coordinates)
    const campusCenterLat = 40.7128;
    const campusCenterLon = -74.0060;

    final distance = calculateDistance(
      latitude, longitude,
      campusCenterLat, campusCenterLon,
    );

    return distance <= radiusInMeters;
  }

  // Get location suggestions based on input
  static List<CampusLocation> getLocationSuggestions(String query) {
    if (query.isEmpty) return campusLocations.values.toList();

    final queryLower = query.toLowerCase();
    return campusLocations.values.where((location) {
      return location.name.toLowerCase().contains(queryLower) ||
             location.description.toLowerCase().contains(queryLower);
    }).toList();
  }

  // Format distance for display
  static String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()}m';
    } else {
      final km = distanceInMeters / 1000;
      return '${km.toStringAsFixed(1)}km';
    }
  }

  // Get location accuracy description
  static String getAccuracyDescription(double? accuracy) {
    if (accuracy == null) return 'Unknown';
    
    if (accuracy <= 5) return 'Excellent';
    if (accuracy <= 10) return 'Good';
    if (accuracy <= 20) return 'Fair';
    return 'Poor';
  }

  // Open location settings
  static Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  // Open app settings
  static Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  // Dispose
  static Future<void> dispose() async {
    await stopLocationTracking();
    _listeners.clear();
    _currentPosition = null;
    _currentAddress = null;
  }
}

// Campus location model
class CampusLocation {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String description;

  const CampusLocation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
    };
  }

  factory CampusLocation.fromMap(Map<String, dynamic> map) {
    return CampusLocation(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      description: map['description'] ?? '',
    );
  }
}

// Location listener interface
abstract class LocationListener {
  void onLocationChanged(Position? position);
}

// Location result class
class LocationResult {
  final bool success;
  final Position? position;
  final String? address;
  final String? error;

  LocationResult({
    required this.success,
    this.position,
    this.address,
    this.error,
  });
}