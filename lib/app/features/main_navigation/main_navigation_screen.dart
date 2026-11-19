import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:my_money_manager/app/features/transactions/transaction_history_screen.dart';
import '../accounts/accounts_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../salary_allocation/salary_allocation_screen.dart';
import '../settings/settings_screen.dart';
import '../transactions/add_transaction_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  // 0: Home, 1: Allocation, 2: Accounts, 3: Profile (with Analytics)
  // Center Floating Plus Button: Add Transaction
  final List<Widget> _screens = [
    DashboardScreen(),
    SalaryAllocationScreen(showBackButton: true),

    AccountsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isHome = _currentIndex == 0;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isHome ? Brightness.light : Brightness.dark,
        statusBarBrightness: isHome ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: IndexedStack(index: _currentIndex, children: _screens),
      floatingActionButton: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => TransactionHistoryScreen()));
        },
        child: Container(
          height: 56,
          width: 56,
          margin: const EdgeInsets.only(top: 24),
          decoration: const BoxDecoration(
            color: Color(0xFFD4F938), // Figma Neon lime
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.add, size: 30, color: Color(0xFF1E232A)),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  0,
                  Icons.home_outlined,
                  Icons.home_rounded,
                  'Home',
                ),
                _buildNavItem(
                  1,
                  Icons.calculate_outlined,
                  Icons.calculate_rounded,
                  'Allocation',
                ),
                const SizedBox(
                  width: 48,
                ), // Gap for center floating + Add Transaction button
                _buildNavItem(
                  2,
                  Icons.account_balance_wallet_outlined,
                  Icons.account_balance_wallet_rounded,
                  'Accounts',
                ),
                _buildNavItem(
                  3,
                  Icons.person_outline_rounded,
                  Icons.person_rounded,
                  'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData unselectedIcon,
    IconData selectedIcon,
    String label,
  ) {
    final isSelected = _currentIndex == index;
    final color = isSelected
        ? const Color(0xFF65B741)
        : const Color(0xFF717784);

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? selectedIcon : unselectedIcon,
              color: color,
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
