import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../widgets/background_wrapper.dart';

class PaymentConfirmationScreen extends StatelessWidget {
  final String paymentMethod;
  final String mobileNumber;
  final String planName;
  final String amount;
  final String invoiceId;

  const PaymentConfirmationScreen({
    super.key,
    required this.paymentMethod,
    required this.mobileNumber,
    required this.planName,
    required this.amount,
    required this.invoiceId,
  });

  @override
  Widget build(BuildContext context) {
    return BackgroundWrapper(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            'Payment Confirmation',
            style: TextStyle(color: AppColors.textOnDark),
          ),
          backgroundColor: Colors.black.withOpacity(0.5),
          elevation: 1,
          iconTheme: const IconThemeData(color: AppColors.textOnDark),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: AppColors.cardDark,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          'INVOICE #$invoiceId',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      _buildInvoiceRow(
                        'Payment Method:',
                        paymentMethod.toUpperCase(),
                      ),
                      _buildInvoiceRow('Mobile Number:', mobileNumber),
                      _buildInvoiceRow('Sender Name:', 'Azwar'),
                      _buildInvoiceRow('Plan Selected:', planName),
                      _buildInvoiceRow('Amount:', amount),
                      const Divider(height: 30),
                      _buildInvoiceRow('Recipient Account:', '03123456789'),
                      _buildInvoiceRow(
                        'Recipient Name:',
                        'Smart DoorBell Inc.',
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    _showPaymentSuccessDialog(context);
                  },
                  child: const Text(
                    'Confirm Payment',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textOnDark,
            ),
          ),
          const Spacer(),
          Text(value, style: TextStyle(color: Colors.grey[300])),
        ],
      ),
    );
  }

  void _showPaymentSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.cardDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 60,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Payment Successful!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textOnDark,
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Your subscription is now active',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/dashboard',
                    (route) => false,
                  );
                },
                child: const Text(
                  'Back to Dashboard',
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
            ],
          ),
    );
  }
}
