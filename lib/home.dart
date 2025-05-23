import 'dart:convert';

import 'package:background_location/background_location.dart';
import 'package:background_location_demo/location_history_screen.dart';
import 'package:background_location_demo/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends HookConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationPermission = useState<PermissionStatus?>(null);
    final isLocationUpdateRunning = useState<bool>(false);
    final locationHistoryNotifier =
        ref.watch(locationHistoryNotifierProvider.notifier);

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        PermissionStatus permission = await Permission.location.status;
        debugPrint('$permission');

        if (permission == PermissionStatus.denied) {
          permission = await Permission.location.request();
          debugPrint('$permission');
        }
        locationPermission.value = permission;
      });
      return null;
    }, []);

    return Scaffold(
      body: Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('位置情報サービスの状態: ${locationPermission.value}'),
          isLocationUpdateRunning.value
              ? Text('位置情報の更新: 実行中')
              : Text('位置情報の更新: 停止中'),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                child: const Text('位置情報の取得を開始する'),
                onPressed: () async {
                  final isServiceRunning =
                      await BackgroundLocation.isServiceRunning();
                  if (isServiceRunning == false) {
                    debugPrint('start background location updates');
                    BackgroundLocation.startLocationService(distanceFilter: 10);
                  }
                  debugPrint('位置情報の取得を開始');
                  BackgroundLocation.getLocationUpdates((location) {
                    debugPrint(
                        '${location.latitude} ${location.longitude} ${location.time}');

                    if (location.latitude == null ||
                        location.longitude == null) {
                      return;
                    }

                    int epochTime;
                    if (location.time == null) {
                      epochTime = DateTime.now().microsecondsSinceEpoch;
                    } else {
                      epochTime = (location.time! * 1000).toInt();
                    }

                    final myLocation = MyLocation(
                      location.latitude!,
                      location.longitude!,
                      epochTime,
                    );
                    final locations = ref.read(locationHistoryNotifierProvider);
                    debugPrint('${[...locations]}');
                    locationHistoryNotifier.add(myLocation);
                  });
                  isLocationUpdateRunning.value = true;
                },
              ),
              TextButton(
                child: Text('位置情報の取得を停止する'),
                onPressed: () {
                  BackgroundLocation.stopLocationService();
                  isLocationUpdateRunning.value = false;
                },
              ),
            ],
          ),
          TextButton(
            child: const Text('削除する'),
            onPressed: () async {
              await ref
                  .read(locationHistoryNotifierProvider.notifier)
                  .deleteAll();
            },
          ),
          TextButton(
            child: const Text('一覧を見る'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return const LocationHistoryScreen();
                  },
                ),
              );
            },
          )
        ],
      )),
    );
  }
}

class MyLocation {
  final double latitude;
  final double longitude;
  final int timestamp;

  MyLocation(this.latitude, this.longitude, this.timestamp);

  factory MyLocation.fromJson(Map<String, dynamic> json) {
    return MyLocation(json['latitude'], json['longitude'], json['timestamp']);
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp,
    };
  }
}

class LocationHistoryNotifier extends Notifier<List<MyLocation>> {
  late SharedPreferences _prefs;

  @override
  build() {
    _prefs = ref.watch(sharedPreferencesProvider);
    return _fetch();
  }

  List<MyLocation> _fetch() {
    final jsonString = _prefs.getString("locations");
    if (jsonString == null) {
      return [];
    }
    final decoded = jsonDecode(jsonString);
    if (decoded is List && decoded.isNotEmpty) {
      final json = decoded.cast<Map<String, dynamic>>();
      try {
        return json.map((item) => MyLocation.fromJson(item)).toList();
      } catch (e) {
        debugPrint('$e');
        rethrow;
      }
    } else {
      throw ('Unexpected JSON Schema: $json');
    }
  }

  Future<bool> add(MyLocation location) async {
    debugPrint('${state.runtimeType}');
    state = [location, ...state];
    final jsonString = jsonEncode(state.map((loc) => loc.toJson()).toList());
    return await _prefs.setString("locations", jsonString);
  }

  Future<bool> deleteAll() async {
    final ok = await _prefs.remove('locations');
    if (ok) {
      debugPrint('削除しました');
      state = [];
    }
    return ok;
  }
}

final locationHistoryNotifierProvider =
    NotifierProvider<LocationHistoryNotifier, List<MyLocation>>(() {
  return LocationHistoryNotifier();
});
