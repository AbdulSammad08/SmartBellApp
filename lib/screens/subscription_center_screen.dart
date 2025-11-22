import 'package:flutter/material.dart'; 
import '../constants/colors.dart';
import '../screens/payment_confirmation_screen.dart';
import '../widgets/background_wrapper.dart';

class SubscriptionCenterScreen extends StatefulWidget {
  const SubscriptionCenterScreen({super.key});

  @override
  State<SubscriptionCenterScreen> createState() => _SubscriptionCenterScreenState();
}

class _SubscriptionCenterScreenState extends State<SubscriptionCenterScreen> {
  int? selectedPlan;
  String? selectedPaymentMethod;
  final Map<String, String> mobileNumbers = {'easypaisa': '', 'jazzcash': ''};
  String? errorMessage;
  final _formKey = GlobalKey<FormState>();

  final List<Map<String, dynamic>> plans = [
    {
      'title': 'Basic (1-2 Devices)',
      'price': '300 PKR',
      'devices': '1-2',
      'features': ['Cloud Storage', 'Smart Alerts'],
    },
    {
      'title': 'Standard (3-5 Devices)',
      'price': '600 PKR',
      'devices': '3-5',
      'features': ['Cloud Storage', 'Smart Alerts'],
    },
    {
      'title': 'Premium (6-8 Devices)',
      'price': '900 PKR',
      'devices': '6-8',
      'features': ['Cloud Storage', 'Smart Alerts'],
    },
    {
      'title': 'Enterprise (9-12 Devices)',
      'price': '1300 PKR',
      'devices': '9+',
      'features': ['Cloud Storage', 'Smart Alerts'],
    },
  ];

  String? validateMobileNumber(String? value) {
    if (value == null || value.isEmpty) return 'Enter mobile number';
    if (value.length != 11 || !value.startsWith('03')) {
      return 'Invalid 11-digit mobile number';
    }
    return null;
  }

  Widget _buildPaymentMethodCard(String title, IconData icon, String number) {
    return GestureDetector(
      onTap: () => setState(() => selectedPaymentMethod = title.toLowerCase()),
      child: Column(
        children: [
          Card(
            elevation: 3,
            color: AppColors.cardDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(
                color: selectedPaymentMethod == title.toLowerCase()
                    ? AppColors.primary
                    : Colors.grey.shade700,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                children: [
                  Icon(icon, size: 40, color: AppColors.primary),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (number.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundWrapper(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.black.withOpacity(0.5),
          iconTheme: const IconThemeData(color: AppColors.textOnDark),
          title: const Text(
            'Subscription Plans',
            style: TextStyle(color: AppColors.textOnDark),
          ),
          elevation: 1,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose Your Plan',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                  ),
                  itemCount: plans.length,
                  itemBuilder: (context, index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color: selectedPlan == index
                            ? AppColors.primary.withOpacity(0.2)
                            : AppColors.cardDark,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: selectedPlan == index
                              ? AppColors.primary
                              : Colors.grey.shade700,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            selectedPlan = index;
                            selectedPaymentMethod = null;
                          });
                        },
                        borderRadius: BorderRadius.circular(15),
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                plans[index]['title'],
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                plans[index]['price'],
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 15),
                              ...plans[index]['features']
                                  .map<Widget>((feature) => Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        child: Row(
                                          children: [
                                            Icon(Icons.check_circle,
                                                color: AppColors.primary, size: 18),
                                            const SizedBox(width: 8),
                                            Text(
                                              feature,
                                              style: const TextStyle(
                                                color: Colors.white70,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ))
                                  .toList(),
                              const Spacer(),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 30),
                if (selectedPlan != null) ...[
                  const Divider(color: Colors.white70),
                  const SizedBox(height: 20),
                  const Text(
                    'Select Payment Method',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPaymentMethodCard(
                          'EasyPaisa',
                          Icons.account_balance_wallet,
                          mobileNumbers['easypaisa']!,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildPaymentMethodCard(
                          'JazzCash',
                          Icons.payment,
                          mobileNumbers['jazzcash']!,
                        ),
                      ),
                    ],
                  ),
                  if (selectedPaymentMethod != null) ...[
                    const SizedBox(height: 20),
                    TextFormField(
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Enter $selectedPaymentMethod Mobile Number',
                        labelStyle: const TextStyle(color: Colors.white),
                        hintText: '03XX-XXXXXXX',
                        hintStyle: const TextStyle(color: Colors.white54),
                        border: const OutlineInputBorder(),
                        errorText: errorMessage,
                      ),
                      keyboardType: TextInputType.phone,
                      validator: validateMobileNumber,
                      onChanged: (value) {
                        final validation = validateMobileNumber(value);
                        setState(() {
                          errorMessage = validation;
                          if (validation == null) {
                            mobileNumbers[selectedPaymentMethod!] = value;
                          } else {
                            mobileNumbers[selectedPaymentMethod!] = '';
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              mobileNumbers[selectedPaymentMethod]!.isNotEmpty
                                  ? AppColors.primary
                                  : Colors.grey,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: mobileNumbers[selectedPaymentMethod]!.isNotEmpty
                            ? () {
                                if (_formKey.currentState!.validate()) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PaymentConfirmationScreen(
                                        paymentMethod: selectedPaymentMethod!,
                                        mobileNumber: mobileNumbers[selectedPaymentMethod]!,
                                        planName: plans[selectedPlan!]['title'],
                                        amount: plans[selectedPlan!]['price'],
                                        invoiceId: 'INV-${DateTime.now().millisecondsSinceEpoch}',
                                      ),
                                    ),
                                  );
                                }
                              }
                            : null,
                        child: const Text(
                          'Proceed to Payment',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ]
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
