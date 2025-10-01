import 'package:flutter/material.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:progear_smart_bag/core/constants/app_sizes.dart';
// import 'package:progear_smart_bag/core/services/bluetooth/blue_service_impl.dart';
import 'package:progear_smart_bag/core/theme/progear_background.dart';
import 'package:progear_smart_bag/shared/widgets/progear_button.dart';

// widgets
import '../widgets/home_header.dart';
import '../../../bag/presentation/widgets/bag_status_card.dart';
import '../widgets/weight_card.dart';
import '../widgets/two_up_cards.dart';

class HomeDashboardPage extends StatelessWidget {
  const HomeDashboardPage({super.key});

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
              const WeightCard(currentKg: 5.6, maxKg: 8),
              const SizedBox(height: AppSizes.lg),
              const TwoUpCards(),
              const SizedBox(height: AppSizes.lg),
              ProGearButton.outlined(
                label: 'Reset Weight',
                onPressed: () {
                  // TODO: reset action
                },
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
