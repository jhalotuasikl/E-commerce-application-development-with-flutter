import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class MapsPicker extends StatefulWidget {
  const MapsPicker({super.key});

  @override
  State<MapsPicker> createState() => _MapsPickerState();
}

class _MapsPickerState extends State<MapsPicker> {
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _pointAnnotationManager;
  Point? _selectedPoint;

  // Koordinat default Yogyakarta
  final double defaultLat = -7.797068;
  final double defaultLng = 110.370529;

  Future<Uint8List> _loadMarkerImage() async {
    try {
      final ByteData bytes = await rootBundle.load("assets/marker.png");
      return bytes.buffer.asUint8List();
    } catch (e) {
      print("Error load marker image: $e");
      rethrow;
    }
  }


  Future<CameraOptions> _getInitialCamera() async {
    final initialPoint = Point(coordinates: Position(defaultLng, defaultLat));
    _selectedPoint = initialPoint; // set selected point awal
    return CameraOptions(center: initialPoint, zoom: 14);
  }

  void _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    _pointAnnotationManager =
    await _mapboxMap!.annotations.createPointAnnotationManager();

    // Tambahkan marker otomatis di Yogyakarta
    if (_selectedPoint != null) {
      final markerImage = await _loadMarkerImage();
      await _pointAnnotationManager?.create(
        PointAnnotationOptions(
          geometry: _selectedPoint!,
          image: markerImage,
          iconSize: 1.5,
        ),
      );
    }
  }

  void _onMapTap(MapContentGestureContext context) async {
    if (_mapboxMap == null) return;

    final geometry = context.point;
    if (geometry != null) {
      await _pointAnnotationManager?.deleteAll();
      setState(() {
        _selectedPoint = geometry;
      });

      final markerImage = await _loadMarkerImage();
      await _pointAnnotationManager?.create(
        PointAnnotationOptions(
          geometry: geometry,
          image: markerImage,
          iconSize: 1.5,
        ),
      );
    }
  }

  void _confirmSelection() {
    if (_selectedPoint != null) {
      final pos = _selectedPoint!.coordinates as Position;
      Navigator.pop(context, {
        "lat": pos.lat,
        "lng": pos.lng,
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pilih lokasi dulu di peta")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pilih Lokasi"),
        actions: [
          IconButton(
            onPressed: _confirmSelection,
            icon: const Icon(Icons.check),
          ),
        ],
      ),
      body: FutureBuilder<CameraOptions>(
        future: _getInitialCamera(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return MapWidget(
            key: const ValueKey("mapWidget"),
            cameraOptions: snapshot.data!,
            onMapCreated: _onMapCreated,
            onTapListener: _onMapTap,
          );
        },
      ),
    );
  }
}
