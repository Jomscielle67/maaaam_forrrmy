import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:daddies_store/providers/theme_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _handleForgotPassword(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please sign in to reset your password'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: user.email!,
      );
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset email sent to your email address!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Dark Mode Toggle
          Card(
            child: ListTile(
              leading: Icon(
                themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                color: Theme.of(context).primaryColor,
              ),
              title: const Text('Dark Mode'),
              subtitle: Text(
                themeProvider.isDarkMode ? 'Enabled' : 'Disabled',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              trailing: Switch(
                value: themeProvider.isDarkMode,
                onChanged: (value) => themeProvider.toggleTheme(),
                activeColor: Theme.of(context).primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Forgot Password
          Card(
            child: ListTile(
              leading: Icon(
                Icons.lock_reset,
                color: Theme.of(context).primaryColor,
              ),
              title: const Text('Reset Password'),
              subtitle: const Text('Send password reset link to your email'),
              onTap: () => _handleForgotPassword(context),
            ),
          ),
          const SizedBox(height: 16),
          
          // Account Settings
          
        ],
      ),
    );
  }
}