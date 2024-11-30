import 'package:background_location_demo/home.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class LocationHistoryScreen extends ConsumerWidget {
  const LocationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locations = ref.watch(locationHistoryProvider);

    return Scaffold(
      appBar: AppBar(),
      body: ListView.builder(
        itemCount: locations.length,
        itemBuilder: (context, index) {
          final location = locations[index];
          DateTime? time;
          if (location.time != null) {
            final epoch = (location.time! * 1000).toInt();
            time = DateTime.fromMicrosecondsSinceEpoch(epoch);
          }
          return ListTile(
            title: Text('${time ?? ''}'),
            subtitle: Text('${location.latitude} ${location.longitude}'),
          );
        },
      ),
    );
  }
}
