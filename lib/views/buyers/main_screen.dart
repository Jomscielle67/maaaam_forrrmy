import 'package:daddies_store/views/buyers/nav_screens/account_screen.dart';
import 'package:daddies_store/views/buyers/nav_screens/cart_screen.dart';
import 'package:daddies_store/views/buyers/nav_screens/category_screen.dart';
import 'package:daddies_store/views/buyers/nav_screens/home_screen.dart';
import 'package:daddies_store/views/buyers/nav_screens/search_screen.dart';
import 'package:daddies_store/views/buyers/nav_screens/store_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;
  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  late int _pageIndex;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _pageIndex = widget.initialIndex;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  final List<Widget> _pages = [
    HomeScreen(),
    CategoryScreen(),
    CartScreen(),
    SearchScreen(),
    AccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _pages[_pageIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BottomNavigationBar(
            elevation: 0,
            backgroundColor: Theme.of(context).cardTheme.color,
            type: BottomNavigationBarType.fixed,
            currentIndex: _pageIndex,
            onTap: (value) {
              setState(() {
                _pageIndex = value;
              });
              _animationController.forward(from: 0);
            },
            selectedFontSize: 12,
            unselectedFontSize: 12,
            unselectedItemColor: Theme.of(context).textTheme.bodyMedium?.color,
            selectedItemColor: Theme.of(context).colorScheme.primary,
            items: [
              BottomNavigationBarItem(
                icon: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _pageIndex == 0 ? Colors.yellow.shade50 : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(CupertinoIcons.home, size: 24),
                ),
                label: 'HOME',
              ),
              BottomNavigationBarItem(
                icon: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _pageIndex == 1 ? Colors.yellow.shade50 : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SvgPicture.asset(
                    'assets/icons/explore.svg',
                    width: 24,
                    color: _pageIndex == 1 ? Colors.yellow.shade900 : Colors.grey.shade600,
                  ),
                ),
                label: 'CATEGORY',
              ),
              BottomNavigationBarItem(
                icon: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _pageIndex == 2 ? Colors.yellow.shade50 : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SvgPicture.asset(
                    'assets/icons/cart.svg',
                    width: 24,
                    color: _pageIndex == 2 ? Colors.yellow.shade900 : Colors.grey.shade600,
                  ),
                ),
                label: 'CART',
              ),
              BottomNavigationBarItem(
                icon: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _pageIndex == 3 ? Colors.yellow.shade50 : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SvgPicture.asset(
                    'assets/icons/search.svg',
                    width: 24,
                    color: _pageIndex == 3 ? Colors.yellow.shade900 : Colors.grey.shade600,
                  ),
                ),
                label: 'SEARCH',
              ),
              BottomNavigationBarItem(
                icon: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _pageIndex == 4 ? Colors.yellow.shade50 : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SvgPicture.asset(
                    'assets/icons/account.svg',
                    width: 24,
                    color: _pageIndex == 4 ? Colors.yellow.shade900 : Colors.grey.shade600,
                  ),
                ),
                label: 'ACCOUNT',
              ),
            ],
          ),
        ),
      ),
    );
  }
}