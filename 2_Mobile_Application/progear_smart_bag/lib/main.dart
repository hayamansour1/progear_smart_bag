import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:progear_smart_bag/core/app_keys.dart';
import 'package:progear_smart_bag/core/routing/app_router.dart';
import 'package:progear_smart_bag/core/theme/app_theme.dart';

// Bluetooth
import 'package:progear_smart_bag/core/services/bluetooth/blue_service_impl.dart';
import 'package:progear_smart_bag/features/bag/controllers/bluetooth_controller.dart';

// Battery
import 'package:progear_smart_bag/core/services/parser/bag_parser.dart';
import 'package:progear_smart_bag/features/home/data/battery_repository.dart';
import 'package:progear_smart_bag/features/home/logic/battery_controller.dart';

// Weight
import 'package:progear_smart_bag/features/weight/logic/weight_controller.dart';

// Activity unread store + last controller
import 'package:progear_smart_bag/features/activity/data/activity_seen_store.dart';
import 'package:progear_smart_bag/features/activity/data/last_controller_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // Init local store used for unread badges/dots
  await ActivitySeenStore.instance.init();

  runApp(
    MultiProvider(
      providers: [
        // --- Bluetooth controller ---
        ChangeNotifierProvider(
          create: (_) => BluetoothController(BlueServiceImpl()),
        ),

        // --- Battery controller ---
        ChangeNotifierProvider(
          create: (ctx) {
            final repo = BatteryRepository(Supabase.instance.client);
            final ctrl = BatteryController(
              BagParser(),
              repository: repo,
            );

            ctrl.boot();
            return ctrl;
          },
        ),

        // --- Weight controller (live grams via BLE) ---
        ChangeNotifierProvider(
          create: (_) => WeightController(BagParser()),
        ),
      ],
      child: const ProGearApp(),
    ),
  );
}

class ProGearApp extends StatefulWidget {
  const ProGearApp({super.key});

  @override
  State<ProGearApp> createState() => _ProGearAppState();
}

class _ProGearAppState extends State<ProGearApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      scaffoldMessengerKey: rootMessengerKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: appRouter,
    );
  }
}
