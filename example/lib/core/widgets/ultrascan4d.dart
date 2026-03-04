import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../constants/ui/app_colors.dart';
import '../constants/ui/app_text_styles.dart';


class Ultrascan4d extends StatelessWidget {
  const Ultrascan4d({super.key});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'ultrascan'.tr,
            style: AppTextStyles.heading5.copyWith(
              color: AppColors.silverColor,
            ),
          ),
          Text(
            '4D',
            style: AppTextStyles.heading6.copyWith(
              color: AppColors.silverColor,
            ),
          ),
        ],
      ),
    );
  }
}
