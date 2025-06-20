import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';
import 'dart:math' as math;
import 'dart:ui';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with TickerProviderStateMixin {
  late AnimationController _bgController;
  late AnimationController _textController;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _bgController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLargeScreen = size.width > 600;
    return Scaffold(
      body: Stack(
        children: [
          // 1. Animated Gradient Background
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, child) {
              return Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                    ],
                  ),
                ),
              );
            },
          ),
          // 2. Main Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: size.width * 0.06, vertical: size.height * 0.03),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 3. Hero Glass Card
                      GlassCard(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: size.width * 0.06, vertical: size.height * 0.03),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.18),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.10),
                                      blurRadius: 16,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                padding: EdgeInsets.all(size.width * 0.06),
                                child: Icon(Icons.edit_note_rounded, size: isLargeScreen ? 64 : 44, color: const Color(0xFF6D5DF6)),
                              ),
                              SizedBox(width: size.width * 0.04),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Blogify',
                                    style: GoogleFonts.poppins(
                                      fontSize: isLargeScreen ? 44 : 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black.withOpacity(0.85),
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  AnimatedBuilder(
                                    animation: _textController,
                                    builder: (context, child) {
                                      return Opacity(
                                        opacity: _textController.value,
                                        child: child,
                                      );
                                    },
                                    child: Text(
                                      'Modern Blogging App',
                                      style: GoogleFonts.poppins(
                                        fontSize: isLargeScreen ? 20 : 15,
                                        color: Colors.black.withOpacity(0.55),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: size.height * 0.03),
                      // 4. Animated Tagline
                      AnimatedBuilder(
                        animation: _textController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _textController.value,
                            child: child,
                          );
                        },
                        child: Text(
                          'Share your thoughts and stories with the world!',
                          style: GoogleFonts.poppins(
                            fontSize: isLargeScreen ? 22 : 16,
                            color: Colors.black.withOpacity(0.55),
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(height: size.height * 0.03),
                      // 5. Get Started Button
                      SizedBox(
                        width: size.width * 0.7,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6D5DF6),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: size.width * 0.08,
                              vertical: size.height * 0.018,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            textStyle: GoogleFonts.poppins(
                              fontSize: isLargeScreen ? 22 : 16,
                              fontWeight: FontWeight.bold,
                            ),
                            elevation: 8,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Get Started'),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward, size: isLargeScreen ? 24 : 18),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: size.height * 0.04),
                      // 6. Feature Chips (Glass)
                      SizedBox(
                        height: isLargeScreen ? 90 : 70,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            GlassChip(icon: Icons.edit, label: 'Write Blogs'),
                            GlassChip(icon: Icons.person, label: 'Profile'),
                            GlassChip(icon: Icons.thumb_up_alt, label: 'Like & Comment'),
                            GlassChip(icon: Icons.image, label: 'Upload Avatar'),
                            GlassChip(icon: Icons.security, label: 'Secure Auth'),
                          ],
                        ),
                      ),
                      SizedBox(height: size.height * 0.04),
                      // 7. About Section (Glass)
                      GlassCard(
                        child: Padding(
                          padding: EdgeInsets.all(size.width * 0.05),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'About Blogify',
                                style: GoogleFonts.poppins(
                                  fontSize: isLargeScreen ? 26 : 18,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF6D5DF6),
                                ),
                              ),
                              SizedBox(height: size.height * 0.01),
                              Text(
                                'Blogify is a modern blogging platform where you can write, edit, and share your stories. Enjoy features like user authentication, profile management, blog editing, likes, comments, and more!',
                                style: GoogleFonts.poppins(
                                  fontSize: isLargeScreen ? 16 : 13,
                                  color: Colors.black.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: size.height * 0.04),
                      // 8. Footer
                      Text(
                        '© 2024 Pydah Soft. All rights reserved.',
                        style: GoogleFonts.poppins(
                          fontSize: isLargeScreen ? 15 : 11,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Glassmorphism Card
class GlassCard extends StatelessWidget {
  final Widget child;
  const GlassCard({required this.child});
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

// Glassmorphism Feature Chip
class GlassChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const GlassChip({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: const Color(0xFF6D5DF6), size: 22),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF6D5DF6),
                    fontWeight: FontWeight.w600,
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