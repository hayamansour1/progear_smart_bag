import 'package:flutter/material.dart';
import 'package:progear_smart_bag/core/constants/app_images.dart';
import 'package:progear_smart_bag/core/constants/app_sizes.dart';
import 'package:progear_smart_bag/shared/widgets/progear_button.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/theme/progear_background.dart';
import 'package:go_router/go_router.dart';

class GetStartedPage extends StatelessWidget {
  const GetStartedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ProGearBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.xxl),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final h = constraints.maxHeight;
                final isCompact = h < 520;

                if (isCompact) {
                  return SingleChildScrollView(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewPadding.bottom + 16,
                      top: 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.asset(AppImages.progear,
                            height: 28, fit: BoxFit.contain),
                        const SizedBox(height: 20),
                        const Text("Welcome!", style: AppTextStyles.heading),
                        const SizedBox(height: 6),
                        const Text(
                          "Your smart gear\n journey starts here",
                          style: AppTextStyles.heading1,
                        ),
                        const SizedBox(height: 60),
                        Row(
                          children: [
                            Expanded(
                              child: ProGearButton.outlined(
                                label: 'Log in',
                                onPressed: () => context.go('/login'),
                                size: ProGearButtonSize.lg,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ProGearButton.primary(
                                label: 'Register',
                                onPressed: () => context.go('/register'),
                                size: ProGearButtonSize.lg,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 120),
                    Image.asset(
                      AppImages.progear,
                      height: 30,
                      fit: BoxFit.contain,
                    ),
                    const Spacer(flex: 2),
                    const Text("Welcome!", style: AppTextStyles.heading),
                    const SizedBox(height: 8),
                    const Text(
                      "Your smart gear\n journey starts here",
                      style: AppTextStyles.heading1,
                    ),
                    const Spacer(flex: 3),
                    Row(
                      children: [
                        Expanded(
                          child: ProGearButton.outlined(
                            label: 'Log in',
                            onPressed: () => context.go('/login'),
                            size: ProGearButtonSize.lg,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ProGearButton.primary(
                            label: 'Register',
                            onPressed: () => context.go('/register'),
                            size: ProGearButtonSize.lg,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 130),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
