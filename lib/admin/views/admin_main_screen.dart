import 'package:daddies_store/admin/views/screens/side_bar_screens/categories_screen.dart';
import 'package:daddies_store/admin/views/screens/side_bar_screens/dashboard_screen.dart';
import 'package:daddies_store/admin/views/screens/side_bar_screens/orders_screen.dart';
import 'package:daddies_store/admin/views/screens/side_bar_screens/products_screen.dart';
import 'package:daddies_store/admin/views/screens/side_bar_screens/upload_banner_screen.dart';
import 'package:daddies_store/admin/views/screens/side_bar_screens/vendors_screen.dart';
import 'package:daddies_store/admin/views/screens/side_bar_screens/couriers_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_admin_scaffold/admin_scaffold.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  Widget _selectedItem = DashboardScreen();

  void screenSlector(AdminMenuItem item) {
    switch (item.route) {
      case DashboardScreen.routeName:
        setState(() {
          _selectedItem = DashboardScreen();
        });
        break;
      case VendorsScreen.routeName:
        setState(() {
          _selectedItem = VendorsScreen();
        });
        break;
      case CategoriesScreen.routeName:
        setState(() {
          _selectedItem = CategoriesScreen();
        });
        break;
      case OrdersScreen.routeName:
        setState(() {
          _selectedItem = OrdersScreen();
        });
        break;
      case ProductsScreen.routeName:
        setState(() {
          _selectedItem = ProductsScreen();
        });
        break;
      case UploadBannerScreen.routeName:
        setState(() {
          _selectedItem = UploadBannerScreen();
        });
        break;
      case CouriersScreen.routeName:
        setState(() {
          _selectedItem = CouriersScreen();
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E88E5),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E88E5).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Text(
                'DADDY',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'ADMIN',
              style: TextStyle(
                color: Color(0xFF1E88E5),
                fontWeight: FontWeight.bold,
                fontSize: 20,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.notifications_outlined, color: Color(0xFF1E88E5)),
              onPressed: () {},
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.person_outline, color: Color(0xFF1E88E5)),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: const Text('Goodbye Daddy'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        child: const Text(
                          'Logout',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      sideBar: SideBar(
        items: [
          AdminMenuItem(
            title: 'DASHBOARD',
            icon: Icons.dashboard_outlined,
            route: DashboardScreen.routeName,
          ),
          AdminMenuItem(
            title: 'VENDORS',
            icon: CupertinoIcons.person_3_fill,
            route: VendorsScreen.routeName,
          ),
          AdminMenuItem(
            title: 'COURIERS',
            icon: Icons.delivery_dining,
            route: CouriersScreen.routeName,
          ),
          AdminMenuItem(
            title: 'ORDERS',
            icon: CupertinoIcons.cart_fill,
            route: OrdersScreen.routeName,
          ),
          AdminMenuItem(
            title: 'CATEGORIES',
            icon: Icons.category_outlined,
            route: CategoriesScreen.routeName,
          ),
          AdminMenuItem(
            title: 'ADD BANNER',
            icon: CupertinoIcons.add_circled_solid,
            route: UploadBannerScreen.routeName,
          ),
          AdminMenuItem(
            title: 'PRODUCTS',
            icon: Icons.shopping_bag_outlined,
            route: ProductsScreen.routeName,
          ),
        ],
        selectedRoute: DashboardScreen.routeName,
        onSelected: (item) {
          screenSlector(item);
        },
        header: Container(
          height: 60,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF1565C0),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'DADDY ISSUES',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
        footer: Container(
          height: 60,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF1565C0),
                blurRadius: 8,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'GROUP 5',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        child: _selectedItem,
      ),
    );
  }
}
