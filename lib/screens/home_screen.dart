import 'dart:ui';
import 'package:flutter/material.dart';
import '../widgets/activity_list.dart';
import '../widgets/pomodoro_timer.dart';
import '../widgets/digital_clock.dart';
import '../widgets/app_shortcuts.dart';
import '../utils/lang.dart';
import 'package:flutter/services.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  void _onLanguageChanged() {
    setState(() {}); // Triggers rebuild to update all AppLang text
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.5,
                colors: [
                  Color(0xFF1E1B4B), // Deep Indigo
                  Color(0xFF0F172A), // Slate Dark
                  Color(0xFF020617), // Real Dark
                ],
              ),
            ),
          ),

          SafeArea(
            child: Row(
              children: [
                // Left Side: Activity List with Glassmorphism
                Expanded(
                  flex: 4,
                  child: ClipRRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.03),
                          border: Border(
                            right: BorderSide(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.deepPurpleAccent.withOpacity(0.05),
                              blurRadius: 20,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: ActivityList(
                          onLanguageChanged: _onLanguageChanged,
                        ),
                      ),
                    ),
                  ),
                ),

                // Right Side: Time, Pomodoro, Shortcuts
                Expanded(
                  flex: 6,
                  child: DefaultTabController(
                    length: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          // TabBar for Pomodoro and Clock
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.deepPurpleAccent.withOpacity(
                                    0.1,
                                  ),
                                  blurRadius: 15,
                                  spreadRadius: -2,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(25),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                child: Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(25),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.1),
                                    ),
                                  ),
                                  child: TabBar(
                                    indicatorSize: TabBarIndicatorSize.tab,
                                    indicator: BoxDecoration(
                                      borderRadius: BorderRadius.circular(25),
                                      color: Colors.deepPurpleAccent
                                          .withOpacity(0.8),
                                    ),
                                    dividerColor: Colors.transparent,
                                    labelColor: Colors.white,
                                    unselectedLabelColor: Colors.white
                                        .withOpacity(0.5),
                                    tabs: [
                                      Tab(
                                        text: AppLang.pomodoroTab,
                                        icon: const Icon(Icons.timer),
                                      ),
                                      Tab(
                                        text: AppLang.clockTab,
                                        icon: const Icon(Icons.access_time),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // TabBarView for Content
                          Expanded(
                            child: TabBarView(
                              children: [
                                Center(
                                  child: PomodoroTimer(
                                    onLanguageChanged: _onLanguageChanged,
                                  ),
                                ),
                                const Center(child: DigitalClock()),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // App Shortcuts and Home Button horizontally aligned at the bottom
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Expanded(child: AppShortcuts()),
                              const SizedBox(width: 16),
                              FloatingActionButton.extended(
                                onPressed: () {
                                  // Exit app / Navigate to Home
                                  SystemNavigator.pop();
                                },
                                icon: const Icon(Icons.home),
                                label: Text(AppLang.homeButton),
                                backgroundColor: Colors.deepPurpleAccent,
                                elevation: 8,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
