import 'package:flutter/material.dart';
import '../models/subscription_plan.dart';
import '../services/api_service.dart';
import '../constants/colors.dart';
import '../widgets/background_wrapper.dart';
import 'subscription_receipt_screen.dart';

class SubscriptionPlansScreen extends StatefulWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  State<SubscriptionPlansScreen> createState() => _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen> {
  List<SubscriptionPlan> plans = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    try {
      final fetchedPlans = await ApiService.getSubscriptionPlans();
      setState(() {
        plans = fetchedPlans;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundWrapper(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.black.withOpacity(0.5),
          elevation: 1,
          iconTheme: const IconThemeData(color: AppColors.textOnDark),
          title: const Text(
            'Subscription Plans',
            style: TextStyle(
              color: AppColors.textOnDark,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : plans.isEmpty
                ? const Center(
                    child: Text(
                      'No plans available',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: plans.length,
                    itemBuilder: (context, index) {
                      final plan = plans[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                plan.name,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'PKR ${plan.price.toStringAsFixed(0)}/${plan.duration}',
                                style: TextStyle(
                                  fontSize: 20,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ...plan.features.map((feature) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle, color: AppColors.primary, size: 18),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        feature,
                                        style: const TextStyle(color: Colors.white, fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () => _selectPlan(plan),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Select Plan',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  void _selectPlan(SubscriptionPlan plan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubscriptionReceiptScreen(plan: plan),
      ),
    );
  }
}