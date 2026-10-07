import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

class CaptainEarningsScreen extends StatelessWidget {
  const CaptainEarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Captain Earnings", style: TextStyle(fontWeight: FontWeight.w800)),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(Icons.account_balance_wallet_outlined, color: AppTheme.primaryPurple),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Wallet Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.wallet, color: Colors.white70, size: 18),
                      SizedBox(width: 6),
                      Text("Wallet Balance", style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text("₹2,450", style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.25),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Instant withdrawal of ₹2,450 sent to UPI ID priya@okaxis")),
                        );
                      },
                      child: const Text("Withdraw to Bank / UPI", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Daily & Weekly Bar Chart Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE8DEFA)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Daily Earnings", style: TextStyle(fontSize: 12, color: AppTheme.inkSoft, fontWeight: FontWeight.bold)),
                          const Text("₹1,240", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.ink)),
                          const SizedBox(height: 2),
                          Row(
                            children: const [
                              Icon(Icons.arrow_drop_up, color: AppTheme.safeGreen, size: 18),
                              Text("+12% vs yesterday", style: TextStyle(color: AppTheme.safeGreen, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                      const Text("Today · 15 Oct", style: TextStyle(color: AppTheme.inkSoft, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const Divider(height: 24),
                  const Text("Weekly Earnings", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.ink)),
                  const SizedBox(height: 14),

                  // Bar Chart Representation
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildBar("Mon", 40),
                      _buildBar("Tue", 55),
                      _buildBar("Wed", 45),
                      _buildBar("Thu", 65),
                      _buildBar("Fri", 70),
                      _buildBar("Sat", 80),
                      _buildBar("Sun", 95, isToday: true),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Incentive Banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.purpleTint,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.stars, color: AppTheme.primaryPurple, size: 20),
                            SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Incentive Bonus: +₹300 today", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppTheme.primaryPurple)),
                                Text("Complete 5 more rides for ₹500", style: TextStyle(fontSize: 11, color: AppTheme.inkSoft)),
                              ],
                            ),
                          ],
                        ),
                        Text("Active", style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primaryPurple, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Transaction History
            const Text("Transaction History", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.ink)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE8DEFA)),
              ),
              child: Column(
                children: [
                  _buildTxnItem("Ride Payout #8821", "Today, 6:42 PM", "+ ₹180", isCredit: true),
                  const Divider(),
                  _buildTxnItem("Incentive Bonus Goal", "Today, 6:30 PM", "+ ₹300", isCredit: true),
                  const Divider(),
                  _buildTxnItem("Withdrawal to Bank (UPI)", "Yesterday, 8:15 PM", "- ₹1,000", isCredit: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBar(String day, double height, {bool isToday = false}) {
    return Column(
      children: [
        Container(
          width: 24,
          height: height,
          decoration: BoxDecoration(
            color: isToday ? AppTheme.primaryPurple : const Color(0xFFC4B5FD),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          day,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isToday ? AppTheme.primaryPurple : AppTheme.inkSoft,
          ),
        ),
      ],
    );
  }

  Widget _buildTxnItem(String title, String subtitle, String amount, {required bool isCredit}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: isCredit ? AppTheme.safeGreen.withOpacity(0.15) : AppTheme.alertRed.withOpacity(0.15),
                child: Icon(
                  isCredit ? Icons.add : Icons.arrow_outward,
                  color: isCredit ? AppTheme.safeGreen : AppTheme.alertRed,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(subtitle, style: const TextStyle(color: AppTheme.inkSoft, fontSize: 11)),
                ],
              ),
            ],
          ),
          Text(
            amount,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              color: isCredit ? AppTheme.safeGreen : AppTheme.ink,
            ),
          ),
        ],
      ),
    );
  }
}
