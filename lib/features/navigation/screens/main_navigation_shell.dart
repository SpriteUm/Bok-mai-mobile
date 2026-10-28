import 'package:flutter/material.dart';
import 'package:bok_mai_mobile/core/theme/app_colors.dart';
import 'package:bok_mai_mobile/core/theme/app_theme.dart';
import 'package:bok_mai_mobile/features/feed/screens/home_screen.dart';
import 'package:bok_mai_mobile/features/history/screens/my_history_screen.dart';
import 'package:bok_mai_mobile/features/map/screens/interactive_map_screen.dart';
import 'package:bok_mai_mobile/features/profile/screens/profile_screen.dart';
import 'package:bok_mai_mobile/features/report/screens/report_form_screen.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const InteractiveMapScreen(),
    const MyHistoryScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // ตรวจสอบขนาดหน้าจอ: ถ้ากว้างกว่าหรือเท่ากับ 640px (iPad / Tablet) ให้ใช้ NavigationRail ด้านข้าง
    final isTablet = MediaQuery.sizeOf(context).width >= 640;

    if (isTablet) {
      return Scaffold(
        body: Row(
          children: [
            // iPad / Tablet Side Navigation Rail
            NavigationRail(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/logo_icon.png',
                      height: 40,
                      width: 40,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.campaign_rounded,
                        color: AppColors.primary,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FloatingActionButton(
                      elevation: 2,
                      tooltip: 'แจ้งปัญหา',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ReportFormScreen()),
                        );
                      },
                      child: const Icon(Icons.add_a_photo_rounded),
                    ),
                  ],
                ),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dynamic_feed_outlined),
                  selectedIcon: Icon(Icons.dynamic_feed_rounded),
                  label: Text('ฟีดสาธารณะ'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.map_outlined),
                  selectedIcon: Icon(Icons.map_rounded),
                  label: Text('แผนที่รวม'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.assignment_outlined),
                  selectedIcon: Icon(Icons.assignment_rounded),
                  label: Text('ประวัติของฉัน'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.account_circle_outlined),
                  selectedIcon: Icon(Icons.account_circle_rounded),
                  label: Text('โปรไฟล์'),
                ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
            // Content Screen
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: _screens,
              ),
            ),
          ],
        ),
      );
    }

    // Phone Compact Layout: Bottom Navigation Bar + FAB
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ReportFormScreen()),
          );
        },
        icon: const Icon(Icons.add_a_photo_rounded),
        label: const Text(
          'แจ้งปัญหา',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dynamic_feed_outlined),
            selectedIcon: Icon(Icons.dynamic_feed_rounded),
            label: 'ฟีดสาธารณะ',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map_rounded),
            label: 'แผนที่รวม',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment_rounded),
            label: 'ประวัติของฉัน',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_circle_outlined),
            selectedIcon: Icon(Icons.account_circle_rounded),
            label: 'โปรไฟล์',
          ),
        ],
      ),
    );
  }
}
