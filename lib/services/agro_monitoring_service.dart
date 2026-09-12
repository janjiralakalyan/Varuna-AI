import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class AgroMonitoringService {
  static const String _baseUrl = 'https://api.agromonitoring.com/agro/1.0';
  static final String _apiKey = AppConstants.agroMonitoringApiKey;

  // 🌍 1. CREATE POLYGON
  // Registers a farm area to get a polyid. Required for soil and satellite data.
  static Future<String> createPolygon(String name, List<List<double>> coordinates) async {
    final url = Uri.parse('$_baseUrl/polygons?appid=$_apiKey');
    
    final payload = {
      "name": name,
      "geo_json": {
        "type": "Feature",
        "properties": {},
        "geometry": {
          "type": "Polygon",
          "coordinates": [coordinates]
        }
      }
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['id']; // polyid
      } else if (response.statusCode == 400 || response.statusCode == 422) {
        // AgroMonitoring returns 400/422 if polygon intersects or is invalid, 
        // try to parse existing if possible, but for simplicity throw error for demo.
        final data = jsonDecode(response.body);
        throw Exception('Failed to create polygon: ${data['message']}');
      } else {
        throw Exception('Failed to create polygon: Code ${response.statusCode}');
      }
    } catch (e) {
      print('AgroMonitoringService Error (createPolygon): $e');
      rethrow;
    }
  }

  // 🔍 1b. GET EXISTING POLYGON ID
  // If polygon already exists, fetch the first one from the account.
  static Future<String?> getExistingPolygonId() async {
    final url = Uri.parse('$_baseUrl/polygons?appid=$_apiKey');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> polygons = jsonDecode(response.body);
        if (polygons.isNotEmpty) {
          return polygons.first['id'];
        }
      }
      return null;
    } catch (e) {
      print('AgroMonitoringService Error (getExistingPolygonId): $e');
      return null;
    }
  }

  // 🌱 2. GET CURRENT SOIL DATA
  static Future<Map<String, dynamic>> getCurrentSoilData(String polyId) async {
    final url = Uri.parse('$_baseUrl/soil?polyid=$polyId&appid=$_apiKey');
    
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load soil data: Code ${response.statusCode}');
      }
    } catch (e) {
      print('AgroMonitoringService Error (getCurrentSoilData): $e');
      rethrow;
    }
  }

  // 🌤 3. GET WEATHER FORECAST OR CURRENT
  static Future<List<dynamic>> getWeatherForecast(double lat, double lon) async {
    final url = Uri.parse('$_baseUrl/weather/forecast?lat=$lat&lon=$lon&appid=$_apiKey');
    
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
         throw Exception('Failed to load weather data: Code ${response.statusCode}');
      }
    } catch (e) {
      print('AgroMonitoringService Error (getWeatherForecast): $e');
      rethrow;
    }
  }

  // 🛰 4. GET SATELLITE IMAGES (NDVI / TRUE COLOR / MOISTURE)
  static Future<List<dynamic>> getSatelliteImages(String polyId, DateTime start, DateTime end) async {
    // Subtract 5 minutes from now as safety ceiling to prevent server-side 'end can not be after now' error
    final nowCeiling = DateTime.now().subtract(const Duration(minutes: 5));
    final safeEnd = end.isAfter(nowCeiling) ? nowCeiling : end;
    
    int startUnix = (start.millisecondsSinceEpoch / 1000).round();
    int endUnix = (safeEnd.millisecondsSinceEpoch / 1000).round();
    if (endUnix <= startUnix) {
      startUnix = endUnix - (90 * 86400); // 90 days window
    }

    try {
      final url = Uri.parse('$_baseUrl/image/search?start=$startUnix&end=$endUnix&polyid=$polyId&appid=$_apiKey');
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final List<dynamic> images = jsonDecode(response.body);
        if (images.isNotEmpty) {
          return _upgradeImageUrls(images);
        }
        
        // If 30-day window is empty, widen to 180 days to capture previous cloud-free pass
        final wideStartUnix = endUnix - (180 * 86400);
        final wideUrl = Uri.parse('$_baseUrl/image/search?start=$wideStartUnix&end=$endUnix&polyid=$polyId&appid=$_apiKey');
        final wideResp = await http.get(wideUrl);
        if (wideResp.statusCode == 200) {
          final List<dynamic> wideImages = jsonDecode(wideResp.body);
          return _upgradeImageUrls(wideImages);
        }
        return [];
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  static List<dynamic> _upgradeImageUrls(List<dynamic> rawImages) {
    return rawImages.map((item) {
      if (item is Map<String, dynamic>) {
        final map = Map<String, dynamic>.from(item);
        if (map['image'] is Map) {
          final imgMap = Map<String, dynamic>.from(map['image'] as Map);
          imgMap.forEach((key, val) {
            if (val is String && val.startsWith('http://')) {
              imgMap[key] = val.replaceFirst('http://', 'https://');
            }
          });
          map['image'] = imgMap;
        }
        return map;
      }
      return item;
    }).toList();
  }
}
