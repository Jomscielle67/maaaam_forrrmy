import 'package:daddies_store/vendor/views/screens/earnings_screen.dart';
import 'package:daddies_store/vendor/views/screens/edit_screen.dart';
import 'package:daddies_store/vendor/views/screens/logout_screen.dart';
import 'package:daddies_store/vendor/views/screens/upload_screen.dart';
import 'package:daddies_store/vendor/views/screens/vendor_orders_screen.dart';
import 'package:daddies_store/vendor/views/screens/vendor_chat_list_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MainVendorScreen extends StatefulWidget {
  const MainVendorScreen({super.key});

  @override
  State<MainVendorScreen> createState() => _MainVendorScreenState();
}

class _MainVendorScreenState extends State<MainVendorScreen> {
  int _pageIndex = 0;

  List<Widget> _pages = [
    EarningsScreen(),
    UploadScreen(),
    EditScreen(),
    const VendorOrdersScreen(),
    VendorChatListScreen(vendorId: FirebaseAuth.instance.currentUser!.uid),
    LogoutScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _pageIndex,
        onTap: (int index) {
          setState(() {
            _pageIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        unselectedItemColor: Colors.black,
        selectedItemColor: Colors.blue.shade800,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.money_dollar),
            label: 'Earnings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.upload_file),
            label: 'Upload',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit),
            label: 'Edit',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart), 
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout), 
            label: 'Logout'
          ),
        ],
      ),
      body: _pages[_pageIndex],
    );
  }
}