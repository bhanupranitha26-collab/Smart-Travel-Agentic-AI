import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/travel_place.dart';
import '../models/trip_plan.dart';
import '../services/travel_data_service.dart';
import '../services/sync_service.dart';
class MapScreen extends StatefulWidget {
  final bool embedded;

  const MapScreen({super.key, this.embedded = false});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController mapController = MapController();
  final TravelDataService travelData = TravelDataService.instance;
  static final LatLng _fallbackCenter = LatLng(20.5937, 78.9629);

  List<LatLng> _routePoints = [];
  String? _lastRouteSig;
  double? _routeDistanceKm;

  Future<void> _fetchRoute(List<LatLng> waypoints) async {
    if (waypoints.length < 2) {
      if (mounted && _routePoints.isNotEmpty) {
        setState(() {
          _routePoints = [];
          _routeDistanceKm = null;
        });
      }
      return;
    }
    final sig = waypoints.map((w) => '${w.latitude},${w.longitude}').join('|');
    if (_lastRouteSig == sig) return;
    _lastRouteSig = sig;

    try {
      final coordsStr = waypoints.map((w) => '${w.longitude},${w.latitude}').join(';');
      final url = 'https://router.project-osrm.org/route/v1/driving/$coordsStr?overview=full&geometries=geojson';
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final coordinates = data['routes'][0]['geometry']['coordinates'] as List;
          final points = coordinates.map((c) => LatLng(c[1] as double, c[0] as double)).toList();
          final distanceMeters = (data['routes'][0]['distance'] as num?)?.toDouble();
          if (mounted) {
            setState(() {
              _routePoints = points;
              if (distanceMeters != null) {
                _routeDistanceKm = distanceMeters / 1000.0;
              }
            });
          }
          return;
        }
      }
    } catch (e) {
      debugPrint('Error fetching route: $e');
    }

    if (mounted) {
      setState(() {
        _routePoints = waypoints;
        _routeDistanceKm = null;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    travelData.addListener(_handleTravelDataChanged);
    _initialize();
  }

  @override
  void dispose() {
    travelData.removeListener(_handleTravelDataChanged);
    super.dispose();
  }

  LatLng get _currentFocusCenter {
    if (travelData.itineraryStops.isNotEmpty) {
      return LatLng(
        travelData.itineraryStops.first.latitude,
        travelData.itineraryStops.first.longitude,
      );
    }
    return travelData.cityCenter ?? _fallbackCenter;
  }

  void _updateMapBounds() {
    final points = <LatLng>[];

    if (travelData.cityCenter != null) points.add(travelData.cityCenter!);

    LatLng? startPoint = travelData.sourceCenter;

    final waypoints = <LatLng>[];
    
    if (startPoint != null) {
      points.add(startPoint);
      waypoints.add(startPoint);
    }

    for (final stop in travelData.itineraryStops) {
      final p = LatLng(stop.latitude, stop.longitude);
      points.add(p);
      waypoints.add(p);
    }
    
    if (travelData.cityCenter != null) {
       // if no stops, just go to city center. Alternatively, always end at city center if we didn't add it as a stop.
       if (waypoints.isEmpty || waypoints.length == 1) {
         waypoints.add(travelData.cityCenter!);
       }
    }

    if (waypoints.length >= 2) {
      // OSRM handles max 100 waypoints for driving, we limit to 25 to be safe
      _fetchRoute(waypoints.length > 25 ? waypoints.sublist(0, 25) : waypoints);
    }

    if (points.isNotEmpty) {
      try {
        final bounds = LatLngBounds.fromPoints(points);
        if (points.length == 1) {
          mapController.move(points.first, 13);
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            mapController.fitBounds(
              bounds,
              options: const FitBoundsOptions(padding: EdgeInsets.all(60)),
            );
          });
        }
      } catch (e) {
        mapController.move(points.first, 13);
      }
    } else {
      mapController.move(_fallbackCenter, 13);
    }
    setState(() {});
  }

  Future<void> _initialize() async {
    await travelData.initialize();
    await travelData.refreshTripLocation();
    if (!mounted) return;
    _updateMapBounds();
  }

  void _handleTravelDataChanged() {
    if (!mounted) return;
    _updateMapBounds();
  }

  void _recenterMap() {
    _updateMapBounds();
  }

  void _selectPlace(TravelPlace place) {
    travelData.selectPlace(place);
  }

  Color _stopColor(PlannerStop stop) {
    if (travelData.visitedPlaceIds.contains(stop.place)) {
      return const Color(0xFFF1F3F4);
    }
    return stop.category == 'event'
        ? const Color(0xFFE3A32B)
        : const Color(0xFF4285F4);
  }

  Color _cardColor(TravelPlace place) {
    switch (place.category) {
      case 'restaurant':
        return const Color(0xFF6EBE7B);
      case 'hotel':
        return const Color(0xFF5B79A5);
      case 'museum':
        return const Color(0xFFB58153);
      default:
        return const Color(0xFF4DB6AC);
    }
  }

  IconData _placeIcon(TravelPlace place) {
    switch (place.category) {
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'hotel':
        return Icons.hotel_rounded;
      case 'museum':
        return Icons.museum_rounded;
      default:
        return Icons.place_rounded;
    }
  }

  Widget _buildGemCard(TravelPlace place) {
    final selected = travelData.selectedPlace?.id == place.id;
    return GestureDetector(
      onTap: () => _selectPlace(place),
      child: Container(
        width: 178,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: selected
              ? Border.all(color: const Color(0xFF008080), width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 126,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _cardColor(place),
                      _cardColor(place).withOpacity(0.45),
                    ],
                  ),
                ),
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _placeIcon(place),
                        color: const Color(0xFF008080),
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                place.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF20252D),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    size: 12,
                    color: Color(0xFF0B8B7A),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${place.category.toUpperCase()} • ${place.distanceKm.toStringAsFixed(1)} km away',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.black.withOpacity(0.56),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (!travelData.tripIsActive) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.map_rounded, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Trip is not started',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E2530)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please plan and start a trip first.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      );
    }

    final selectedPlace =
        travelData.selectedPlace ??
        (travelData.nearbyGems.isNotEmpty ? travelData.nearbyGems.first : null);

    if (travelData.loadingPlaces && travelData.places.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        // 1. Full Bleed Map
        Positioned.fill(
          child: FlutterMap(
            mapController: mapController,
          options: MapOptions(
            center: _currentFocusCenter,
            zoom: 13,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.smarttravel',
            ),
            PolylineLayer(
              polylines: [
                if (_routePoints.isNotEmpty)
                  Polyline(
                    points: _routePoints,
                    color: const Color(0xFF008080),
                    strokeWidth: 4.0,
                  )
                else if (travelData.sourceCenter != null && travelData.cityCenter != null)
                  Polyline(
                    points: [
                      travelData.sourceCenter!,
                      travelData.cityCenter!,
                    ],
                    color: const Color(0xFF008080),
                    strokeWidth: 4.0,
                  ),
              ],
            ),
            MarkerLayer(
              markers: [
                if (travelData.cityCenter != null)
                  Marker(
                    width: 100,
                    height: 80,
                    point: travelData.cityCenter!,
                    builder: (_) {
                      final startPoint = travelData.sourceCenter;
                      final fallbackDist = startPoint != null 
                        ? const Distance().as(LengthUnit.Meter, startPoint, travelData.cityCenter!) / 1000.0
                        : 0.0;
                      final distToShow = _routeDistanceKm ?? fallbackDist;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (startPoint != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              margin: const EdgeInsets.only(bottom: 2),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFF008080), width: 1.5),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2)),
                                ],
                              ),
                              child: Text(
                                "${distToShow.toStringAsFixed(1)} km",
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF008080)),
                              ),
                            ),
                          const Icon(Icons.location_on_rounded, color: Color(0xFF008080), size: 36),
                        ],
                      );
                    },
                  ),
                if (travelData.currentLocation != null)
                  Marker(
                    width: 40,
                    height: 40,
                    point: travelData.currentLocation!,
                    builder: (_) => Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF22A7F0),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const Icon(Icons.my_location_rounded, color: Colors.white, size: 18),
                    ),
                  ),
              ],
            ),
          ],
        )),

        // 2. Top App Bar Floating
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset('assets/logo/travelpilot_logo.png', height: 28, errorBuilder: (ctx, _, __) => const Icon(Icons.flight_takeoff, color: Color(0xFF008080), size: 24)),
                        const SizedBox(width: 8),
                        const Text(
                          'TripPilot',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF008080),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ValueListenableBuilder<bool>(
                          valueListenable: SyncService.instance.isSynced,
                          builder: (context, synced, _) {
                            return Tooltip(
                              message: "Agent Cloud Sync Active",
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: synced ? const Color(0xFF34A853) : Colors.grey,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  FloatingActionButton.small(
                    heroTag: "recenterBtn",
                    onPressed: _recenterMap,
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.my_location_rounded, color: Color(0xFF008080)),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Feature removed at user request
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return _buildBody();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(title: const Text('Map')),
      body: SafeArea(child: _buildBody()),
    );
  }
}
