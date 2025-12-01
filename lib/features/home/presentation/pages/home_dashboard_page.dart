import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:progear_smart_bag/core/constants/app_sizes.dart';
import 'package:progear_smart_bag/core/theme/progear_background.dart';

// import 'package:progear_smart_bag/core/constants/app_colors.dart';

import 'package:progear_smart_bag/features/bag/controllers/bluetooth_controller.dart';
import 'package:progear_smart_bag/features/bag/presentation/widgets/alert_bag_connection.dart';
import 'package:progear_smart_bag/features/bag/presentation/widgets/connect_bag_sheet.dart';

import 'package:progear_smart_bag/features/weight/logic/weight_controller.dart';
import 'package:progear_smart_bag/shared/widgets/progear_button.dart';

// widgets
import '../widgets/home_header.dart';
import '../../../bag/presentation/widgets/bag_status_card.dart';
import '../widgets/weight_card.dart';
import '../widgets/two_up_cards.dart';
import 'package:progear_smart_bag/features/home/presentation/widgets/reset_weight_sheet.dart';

class HomeDashboardPage extends StatefulWidget {
  const HomeDashboardPage({super.key});

  @override
  State<HomeDashboardPage> createState() => _HomeDashboardPageState();
}

class _HomeDashboardPageState extends State<HomeDashboardPage> {
  bool _snapshotLoaded = false;

  @override
  void initState() {
    super.initState();

    // بعد ما تبني الصفحة:
    // 1) نشيك إذا اليوزر عنده controller مسجل في DB أو لا
    // 2) لو ماعنده → نطلع ConnectBagSheet (مع الـ instructions)
    // 3) لو عنده → نستخدم منطقك القديم (تنبيه الاتصال + load snapshot)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final sb = Supabase.instance.client;
      final uid = sb.auth.currentUser?.id;

      // حالة نادرة: ما فيه يوزر
      if (uid == null) {
        if (!mounted) return;
        _showAlertIfNoBluetoothConnected();
        await _loadLastSnapshotIfNeeded();
        return;
      }

      // هل عنده شنطة مسبقًا في esp32_controller؟
      final row = await sb
          .from('esp32_controller')
          .select('controllerID')
          .eq('userID', uid)
          .maybeSingle();

      if (!mounted) return;

      final String? cid = row?['controllerID'] as String?;
      final hasController = cid != null;

      if (!hasController) {
        // 🔹 New user → نطلع شيت "Let’s get your bag connected"
        await showModalBottomSheet(
          context: context,
          useSafeArea: true,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (_) => const ConnectBagSheet(),
        );

        // بعد ما يقفل الشيت، نحاول نحمّل snapshot (لو صار فيه controller)
        await _loadLastSnapshotIfNeeded();
      } else {
        // 🔹 Existing user → منطق التنبيه القديم
        _showAlertIfNoBluetoothConnected();
        await _loadLastSnapshotIfNeeded();
      }
    });
  }

  /// منطق التنبيه اللي كان عندك سابقًا:
  /// إذا مافي شنطة متصلة نطلع AlertBagConnection
  void _showAlertIfNoBluetoothConnected() {
    final bt = context.read<BluetoothController>();

    if (bt.connectedDevice == null) {
      showDialog(
        context: context,
        builder: (_) => const AlertBagConnection(),
      );
    }
  }

  /// تحميل آخر Snapshot (expected + current weight) من الـ DB
  /// عشان:
  /// - لو ما فيه بلوتوث: نعرض آخر وزن محفوظ
  /// - لو فيه بلوتوث: برضو نبدأ من قيمة منطقية
  Future<void> _loadLastSnapshotIfNeeded() async {
    if (_snapshotLoaded) return;

    try {
      final sb = Supabase.instance.client;
      final uid = sb.auth.currentUser?.id;
      if (uid == null) return;

      // حالياً نفترض لكل يوزر شنطة واحدة
      final row = await sb
          .from('esp32_controller')
          .select('controllerID')
          .eq('userID', uid)
          .limit(1)
          .maybeSingle();

      final cid = row?['controllerID'] as String?;
      if (cid == null) return;

      if (!mounted) return;
      final weightCtrl = context.read<WeightController>();
      await weightCtrl.loadSnapshotFromDb(cid);
      _snapshotLoaded = true;
    } catch (_) {
      // فشل بسيط، نخلي الـ UI يكمل عادي
    }
  }

  Future<void> _openResetSheet() async {
    final bt = context.read<BluetoothController>();
    final cid = bt.connectedDevice?.remoteId.str;

    // لو ما فيه شنطة متصلة نطلع تنبيه الاتصال بدل الشيت
    if (cid == null) {
      await showDialog(
        context: context,
        builder: (_) => const AlertBagConnection(),
      );
      return;
    }

    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
      isScrollControlled: isLandscape,
      builder: (_) {
        if (isLandscape) {
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.58,
            minChildSize: 0.40,
            maxChildSize: 0.95,
            builder: (ctx, scrollController) {
              return SingleChildScrollView(
                controller: scrollController,
                child: ResetWeightSheet(controllerID: cid),
              );
            },
          );
        } else {
          return ResetWeightSheet(controllerID: cid);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final weightCtrl = context.watch<WeightController>();

    return Scaffold(
      body: ProGearBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.lg,
              vertical: AppSizes.lg,
            ),
            children: [
              const HomeHeader(),
              const SizedBox(height: AppSizes.lg),
              const BagStatusCard(),
              const SizedBox(height: AppSizes.lg),

              // الوزن الحالي + المتوقع:
              // - لو فيه بلوتوث: live من الـ BLE
              // - لو مافيه بلوتوث: آخر Snapshot من الـ DB
              WeightCard(
                currentG: weightCtrl.currentG,
                expectedG: weightCtrl.expectedG,
              ),

              const SizedBox(height: AppSizes.lg),
              const TwoUpCards(),
              const SizedBox(height: AppSizes.lg),

              ProGearButton.outlined(
                label: 'Reset Expected Weight',
                onPressed: _openResetSheet,
                size: ProGearButtonSize.xl,
                expanded: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
