import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daddies_store/vendor/views/auth/vendor_auth_screen.dart';
import 'package:daddies_store/views/buyers/nav_screens/buyers_orders_screen.dart';
import 'package:daddies_store/views/buyers/nav_screens/cart_screen.dart';
import 'package:daddies_store/views/buyers/nav_screens/settings_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:daddies_store/views/buyers/nav_screens/profile_screen.dart';
import 'package:daddies_store/vendor/views/auth/vendor_terms.dart';
import 'package:daddies_store/views/buyers/nav_screens/chat_list_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    CollectionReference users = FirebaseFirestore.instance.collection('buyers');
    return FutureBuilder<DocumentSnapshot>(
      future: users.doc(FirebaseAuth.instance.currentUser!.uid).get(),
      builder: (
        BuildContext context,
        AsyncSnapshot<DocumentSnapshot> snapshot,
      ) {
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text("Something went wrong")),
          );
        }

        if (snapshot.hasData && !snapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: Text("Document does not exist")),
          );
        }

        if (snapshot.connectionState == ConnectionState.done) {
          Map<String, dynamic> data =
              snapshot.data!.data() as Map<String, dynamic>;

          return Scaffold(
            appBar: AppBar(
              backgroundColor: const Color.fromARGB(255, 27, 126, 219),
              title: const Text(
                'PROFILE',
                style: TextStyle(
                  fontFamily: 'Brand-Bold',
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.star),
                  onPressed: () {
                    // TODO: Handle favorite button
                  },
                ),
              ],
            ),
            body: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 35),
                  Center(
                    child: CircleAvatar(
                      radius: 64,
                      backgroundColor: const Color.fromARGB(255, 24, 172, 159),
                      backgroundImage:
                          data['profileImage'] != null
                              ? NetworkImage(data['profileImage'])
                              : null,
                      child:
                          data['profileImage'] == null
                              ? const Icon(
                                Icons.person,
                                size: 64,
                                color: Colors.white,
                              )
                              : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    data['fullName'] ?? 'No Name',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    data['email'] ?? 'No Email',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text("Edit Profile"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(15.0),
                    child: Divider(thickness: 2, color: Colors.grey),
                  ),

                  // Clickable ListTiles
                  ListTile(
                    leading: const Icon(Icons.settings),
                    title: const Text('Settings'),
                    onTap: () {
                      // TODO: Navigate to settings
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.phone),
                    title: const Text('Phone'),
                    subtitle: Text(data['phoneNumber'] ?? 'Not Provided'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.shopping_cart),
                    title: const Text('Cart'),
                    onTap: () {
                      // TODO: Navigate to cart
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CartScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.shopping_bag),
                    title: const Text('Orders'),
                    onTap: () {
                      // TODO: Navigate to orders
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BuyersOrdersScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.message),
                    title: const Text('Messages'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatListScreen(
                            currentUserId: FirebaseAuth.instance.currentUser!.uid,
                          ),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.store),
                    title: const Text('Become a Vendor'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const VendorAuthScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Logout'),
                    onTap: () async {
                      try {
                        await FirebaseAuth.instance.signOut();
                        if (context.mounted) {
                          // Show success message
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Logged out successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          // Navigate to login screen
                          Navigator.pushReplacementNamed(context, '/login');
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error logging out: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        }

        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}
