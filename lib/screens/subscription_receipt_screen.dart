import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../widgets/background_wrapper.dart';
import '../models/subscription_plan.dart';
import 'admin_account_details_screen.dart';

class SubscriptionReceiptScreen extends StatefulWidget {
  final SubscriptionPlan plan;

  const SubscriptionReceiptScreen({super.key, required this.plan});

  @override
  State<SubscriptionReceiptScreen> createState() => _SubscriptionReceiptScreenState();
}

class _SubscriptionReceiptScreenState extends State<SubscriptionReceiptScreen> {
  String _selectedCycle = 'monthly';
  
  double get monthlyPricePKR => widget.plan.price;
  double get yearlyPricePKR => (monthlyPricePKR * 12) - (monthlyPricePKR * 2); // 2 months discount
  double get finalAmount => _selectedCycle == 'monthly' ? monthlyPricePKR : yearlyPricePKR;

  @override
  Widget build(BuildContext context) {
    return BackgroundWrapper(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            'Receipt',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textOnDark,
            ),
          ),
          backgroundColor: Colors.black.withOpacity(0.5),
          elevation: 1,
          iconTheme: const IconThemeData(color: AppColors.textOnDark),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Card(
              color: AppColors.cardDark,
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.receipt, size: 80, color: AppColors.primary),
                    const SizedBox(height: 20),
                    Text(
                      'Subscription Receipt',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textOnDark,
                      ),
                    ),
                    const SizedBox(height: 30),
                    
                    // Plan Details Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary.withOpacity(0.1), Colors.transparent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.star, color: Colors.white, size: 24),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.plan.name,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textOnDark,
                                      ),
                                    ),
                                    Text(
                                      'Premium Features Included',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildReceiptRow('Monthly Price:', 'PKR ${monthlyPricePKR.toStringAsFixed(0)}'),
                          _buildReceiptRow('Yearly Price:', 'PKR ${yearlyPricePKR.toStringAsFixed(0)} (2 months free)'),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 25),
                    
                    // Billing Cycle Selection
                    const Text(
                      'Select Billing Cycle:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textOnDark,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: _selectedCycle == 'monthly' ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedCycle == 'monthly' ? AppColors.primary : Colors.grey.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: RadioListTile<String>(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            title: const Text(
                              'One Month',
                              style: TextStyle(color: AppColors.textOnDark, fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              'PKR ${monthlyPricePKR.toStringAsFixed(0)}',
                              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            value: 'monthly',
                            groupValue: _selectedCycle,
                            activeColor: AppColors.primary,
                            onChanged: (value) {
                              setState(() => _selectedCycle = value!);
                            },
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: _selectedCycle == 'yearly' ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedCycle == 'yearly' ? AppColors.primary : Colors.grey.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: RadioListTile<String>(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            title: const Text(
                              'One Year',
                              style: TextStyle(color: AppColors.textOnDark, fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              'PKR ${yearlyPricePKR.toStringAsFixed(0)} (2 months free)',
                              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            value: 'yearly',
                            groupValue: _selectedCycle,
                            activeColor: AppColors.primary,
                            onChanged: (value) {
                              setState(() => _selectedCycle = value!);
                            },
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    const Divider(color: Colors.grey),
                    const SizedBox(height: 20),
                    
                    // Final Total
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary.withOpacity(0.2), AppColors.primary.withOpacity(0.05)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Total Amount',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textOnDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'PKR ${finalAmount.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Action Buttons
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AdminAccountDetailsScreen(
                                    plan: widget.plan,
                                    billingCycle: _selectedCycle,
                                    finalAmount: finalAmount,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Continue',
                              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.grey.withOpacity(0.5), width: 2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Leave',
                              style: TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textOnDark,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}