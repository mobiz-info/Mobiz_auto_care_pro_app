import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../controllers/job_card_pricing_controller.dart';
import '../pricing/accessories_card.dart';

class AccessoriesTabView extends StatelessWidget {
  final JobCardPricingController controller;

  const AccessoriesTabView({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AccessoriesCard(controller: controller),
        ],
      ),
    );
  }
}

