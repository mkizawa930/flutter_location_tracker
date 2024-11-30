import 'package:background_location_demo/home.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class LocationHistoryScreen extends ConsumerWidget {
  const LocationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locations = ref.watch(locationHistoryNotifierProvider);

    return Scaffold(
      appBar: AppBar(),
      body: ListView.builder(
        itemCount: locations.length,
        itemBuilder: (context, index) {
          final location = locations[index];
          final datetime =
              DateTime.fromMicrosecondsSinceEpoch(location.timestamp);
          return ListTile(
            title: Text('$datetime'),
            subtitle: Text('${location.latitude} ${location.longitude}'),
          );
        },
      ),
    );
  }
}
