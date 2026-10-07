import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

class CaptainLoginScreen extends StatefulWidget {
  const CaptainLoginScreen({super.key});

  @override
  State<CaptainLoginScreen> createState() => _CaptainLoginScreenState();
}

class _CaptainLoginScreenState extends State<CaptainLoginScreen> {
  final TextEditingController _phoneController = TextEditingController(text: "98 7654 3210");
  final List<TextEditingController> _otpControllers = List.generate(6, (i) => TextEditingController());

  @override
  void initState() {
    super.initState();
    // Default sample OTP
    const otp = "497280";
    for (int i = 0; i < 6; i++) {
      _otpControllers[i].text = otp[i];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF5314C9),
              Color(0xFF2A096E),
              Color(0xFF180340),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Mascot Header
                Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(
                          colors: [Color(0xFF8C52FF), Color(0xFF5314C9)],
                        ),
                        border: Border.all(color: AppTheme.goldYellow, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text("🦸♀️", style: TextStyle(fontSize: 64)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    RichText(
                      textAlign: TextAlign.center,
                      text: const TextSpan(
                        style: TextStyle(fontFamily: 'SpaceGrotesk', fontSize: 24, fontWeight: FontWeight.w800),
                        children: [
                          TextSpan(text: "Captain\n", style: TextStyle(color: Colors.white)),
                          TextSpan(text: "SuperWomen", style: TextStyle(color: AppTheme.goldYellow)),
                        ],
                      ),
                    ),
                  ],
                ),

                // White Card with Inputs
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.35),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Welcome Back!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.ink)),
                      const SizedBox(height: 4),
                      const Text("Log in to continue with Captain SuperWomen — Safe rides for you", style: TextStyle(fontSize: 12, color: AppTheme.inkSoft)),
                      const SizedBox(height: 16),

                      const Text("Phone Number", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.inkSoft)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9F7FD),
                          border: Border.all(color: const Color(0xFFE8DEFA), width: 1.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Text("🇮🇳 +91", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                decoration: const InputDecoration(border: InputBorder.none),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text("Enter 6-digit OTP", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.inkSoft)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(6, (index) {
                          return Container(
                            width: 44,
                            height: 50,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: const Color(0xFFE8DEFA), width: 1.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _otpControllers[index].text,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.primaryPurple,
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 18),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryPurple,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, '/dashboard');
                          },
                          child: const Text("Verify & Login →", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                        ),
                      ),
                      const SizedBox(height: 14),

                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Text("🛡️ Women-Driven", style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppTheme.inkSoft)),
                          Text("⭐ 4.9★ 5L+ Rides", style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppTheme.inkSoft)),
                          Text("📍 30+ Cities", style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppTheme.inkSoft)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
