import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:resonance_network_wallet/features/main/screens/notifications_screen.dart';
import 'package:resonance_network_wallet/features/main/screens/settings_screen.dart';
import 'package:resonance_network_wallet/features/main/screens/transactions_screen.dart';
import 'package:resonance_network_wallet/features/main/screens/wallet_main.dart';
import 'package:resonance_network_wallet/models/wallet_state_manager.dart';
import 'package:resonance_network_wallet/shared/extensions/media_query_data_extension.dart';

class NavItem {
  final String offIcon;
  final String onIcon;
  final String label;

  NavItem(this.offIcon, this.onIcon, this.label);
}

// Custom painter for the custom bottom navigation bar
class BottomNavPainter extends CustomPainter {
  final bool isTablet;

  BottomNavPainter({super.repaint, required this.isTablet});

  double get offset => isTablet ? 130 : 80;

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    Path path = Path();

    path.moveTo(0, size.height);

    path.lineTo(size.width, size.height);
    path.lineTo(size.width, 0);
    path.lineTo((size.width * 1 / 2) + offset, 0);
    path.lineTo((size.width * 1 / 2), size.height / 2);
    path.lineTo((size.width * 1 / 2) - offset, 0);
    path.lineTo(0, 0);

    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class NavbarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const NavbarItem({
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.white : Colors.grey,
            size: isSelected ? 30 : 24,
          ),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey,
              fontSize: isSelected ? 14 : 12,
            ),
          ),
        ],
      ),
    );
  }
}

class Navbar extends StatefulWidget {
  const Navbar({super.key});

  @override
  State<Navbar> createState() => _NavbarState();
}

class _NavbarState extends State<Navbar> {
  int _selectedIndex = 0;
  final bool _notificationTestDisabled = true; // Flag for notifications

  final List<NavItem> _navItems = [
    NavItem(
      'assets/navbar/home_icon_off.svg',
      'assets/navbar/home_icon_on.svg',
      'Home',
    ),
    NavItem(
      'assets/navbar/history_icon_off.svg',
      'assets/navbar/history_icon_on.svg',
      'History',
    ),
    NavItem(
      'assets/navbar/floating_button.svg',
      'assets/navbar/floating_button.svg',
      'Send',
    ),
    NavItem(
      'assets/navbar/settings_icon_off.svg',
      'assets/navbar/settings_icon_on.svg',
      'Settings',
    ),
    NavItem(
      'assets/navbar/notifications_icon_off.svg',
      'assets/navbar/notifications_icon_on.svg',
      'Notifications',
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index > 2 ? index - 1 : index;
    });
  }

  Widget _buildNavItem(int index, NavItem item, bool isTablet) {
    bool isSelected = index > 2
        ? _selectedIndex == index - 1
        : _selectedIndex == index;

    // Floating action button item
    if (index == 2) {
      return SizedBox(
        height: isTablet ? 100 : 75,
        width: isTablet ? 95 : 70,
        child: GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/send');
          },
          child: SvgPicture.asset(item.onIcon),
        ),
      );
    }

    // Notification item with test flag
    if (index == 4 && _notificationTestDisabled) {
      return SizedBox(
        height: isTablet ? 40 : 32,
        width: isTablet ? 78 : 70,
        child: InkWell(
          onTap: null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                'assets/navbar/notifications_icon_off.svg',
                width: isTablet ? 32 : 20,
                colorFilter: const ColorFilter.mode(
                  Colors.blueGrey,
                  BlendMode.srcIn,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return InkWell(
      onTap: () {
        _onItemTapped(index);
      },
      child: SizedBox(
        height: isTablet ? 40 : 32,
        width: isTablet ? 78 : 70,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            isSelected
                ? SvgPicture.asset(item.onIcon, width: isTablet ? 32 : 20)
                : SvgPicture.asset(item.offIcon, width: isTablet ? 32 : 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    final walletStateManager = Provider.of<WalletStateManager>(context);

    return IndexedStack(
      index: _selectedIndex,
      children: [
        const WalletMain(),
        TransactionsScreen(manager: walletStateManager),
        const SettingsScreen(),
        NotificationsScreen(manager: walletStateManager),
      ],
    );
  }

  Widget _buildBottomNavigationBar(bool isTablet) {
    final height = isTablet ? 110.0 : 90.0;

    return Container(
      color: Colors.transparent,
      height: height,
      child: Stack(
        children: [
          CustomPaint(
            size: Size(MediaQuery.of(context).size.width, height),
            painter: BottomNavPainter(isTablet: isTablet),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _navItems.asMap().entries.map((entry) {
              int index = entry.key;
              NavItem item = entry.value;

              return _buildNavItem(index, item, isTablet);
            }).toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).isTablet;

    return Scaffold(
      extendBody: true,
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigationBar(isTablet),
    );
  }
}
