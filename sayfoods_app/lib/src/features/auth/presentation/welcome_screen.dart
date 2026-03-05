import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Background Image
          Image.asset(
            'assets/images/welcome_bg.png',
            fit: BoxFit.cover,
            // Darken the background slightly so white text pops
            color: Colors.black.withOpacity(0.4),
            colorBlendMode: BlendMode.darken,
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 48.0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  // 2. Logo / Typography
                  // Note: The design had a logo, but we will use styled text for now.
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'Say',
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            color: Colors.purple,
                            letterSpacing: -1.5,
                          ),
                        ),
                        TextSpan(
                          text: 'foods',
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            color: Colors.red,
                            letterSpacing: -1.5,
                          ),
                        ),
                        TextSpan(
                          text: '.com',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 3. Main Headings
                  const Text(
                    'WELCOME TO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Text(
                    'Sayfoods',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 64,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                      letterSpacing: -2.0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Your one stop shop for fresh,\nquality and affordable foods',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),

                  const Spacer(),

                  // 4. Buttons
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: Navigate to Sign Up
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.shade900, // Deep purple
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'SIGN UP',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: Navigate to Login
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.shade900,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'REGISTER', // Based on screenshot, usually this is LOGIN
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
