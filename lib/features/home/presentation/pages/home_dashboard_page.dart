import 'package:flutter/material.dart';
import 'package:progear_smart_bag/core/constants/app_sizes.dart';
import 'package:progear_smart_bag/core/theme/progear_background.dart';
import 'package:progear_smart_bag/features/bag/controllers/bluetooth_controller.dart';
import 'package:progear_smart_bag/features/bag/presentation/widgets/alert_bag_connection.dart';
import 'package:progear_smart_bag/features/weight/logic/weight_controller.dart';
import 'package:progear_smart_bag/shared/widgets/progear_button.dart';
import 'package:provider/provider.dart';

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
  // When BLE is ready, ask BluetoothController for the real id:
  late String _controllerID;
  // TEMP for testing without BLE:
  // static const _controllerID = 'ctrl_14be0569';

  @override
  void initState() {
    // TODO: check is BLE ready and update controllerID
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controllerID =
          context.read<BluetoothController>().connectedDevice?.remoteId.str ??
              'ctrl_14be0569';
      if (_controllerID.isEmpty || _controllerID == 'ctrl_14be0569') {
        showDialog(
            context: context,
            builder: (context) {
              return AlertBagConnection();
            });
      }
    });

    // TEMP for testing without BLE:
    // _controllerID = 'ctrl_14be0569';
  }

  Future<void> _openResetSheet() async {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,

      // Keep native swipe-down to dismiss in portrait
      enableDrag: true,
      isDismissible: true,

      // Only make it draggable/scrollable in landscape
      isScrollControlled: isLandscape,

      builder: (_) {
        if (isLandscape) {
          // Landscape: DraggableScrollableSheet so all content fits on short heights
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.58,
            minChildSize: 0.40,
            maxChildSize: 0.95,
            builder: (ctx, scrollController) {
              return SingleChildScrollView(
                controller: scrollController,
                child: ResetWeightSheet(
                  controllerID: _controllerID,
                ),
              );
            },
          );
        } else {
          // Portrait: normal compact sheet with swipe-down to dismiss
          return ResetWeightSheet(
            controllerID: _controllerID,
          );
        }
      },
    );

    if (!mounted) return;
  }

  @override
  Widget build(BuildContext context) {
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

              //  REAL (when BLE + expected weight are ready)
              WeightCard(
                currentG: context.watch<WeightController>().currentG,
                // TODO: replace with real expected grams from DB state
                expectedG: 8000,
              ),

              //   TEMP fake grams for now (to keep UI running)
              // const WeightCard(currentG: 5600, expectedG: 8000),

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
