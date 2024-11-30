import 'package:background_location/background_location.dart';
import 'package:background_location_demo/location_history_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

final locationHistoryProvider = StateProvider<List<Location>>((ref) {
  return [];
});

class HomeScreen extends HookConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationPermission = useState<PermissionStatus?>(null);
    final isLocationUpdateRunning = useState<bool>(false);

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
                    isLocationUpdateRunning.value = true;
                  }
                  BackgroundLocation.getLocationUpdates((location) {
                    debugPrint('${location.latitude} ${location.longitude}');
                    ref
                        .read(locationHistoryProvider.notifier)
                        .update((locations) => [location, ...locations]);
                  });
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
