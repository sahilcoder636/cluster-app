import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'core/router.dart';
import 'core/theme.dart';
import 'data/services/notification_service.dart';
import 'data/services/streak_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  await Hive.initFlutter();
  await Hive.openBox(StreakService.boxName);
  await Hive.openBox<dynamic>('pack_played_box');
  await NotificationService.instance.initialize();

  await MobileAds.instance.initialize();
  await Purchases.configure(
    PurchasesConfiguration('test_WTmaAhbzjGxbJqIwYNRQVrEWRHW'),
  );

  runApp(const ProviderScope(child: ClusterApp()));
}

class ClusterApp extends StatelessWidget {
  const ClusterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Cluster',
      theme: buildAppTheme(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
