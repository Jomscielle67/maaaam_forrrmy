import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:daddies_store/views/chat/chat_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VendorChatListScreen extends StatelessWidget {
  final String currentUserId;

  const VendorChatListScreen({
    Key? key,
    required this.currentUserId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('conversations')
            .where('participants', arrayContains: currentUserId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No conversations yet'),
            );
          }

          // Sort conversations by lastMessageTime in memory
          final sortedDocs = snapshot.data!.docs.toList()
            ..sort((a, b) {
              final aTime = (a.data() as Map<String, dynamic>)['lastMessageTime'] as Timestamp;
              final bTime = (b.data() as Map<String, dynamic>)['lastMessageTime'] as Timestamp;
              return bTime.compareTo(aTime);
            });

          return ListView.builder(
            itemCount: sortedDocs.length,
            itemBuilder: (context, index) {
              final doc = sortedDocs[index];
              final data = doc.data() as Map<String, dynamic>;
              final otherUserId = (data['participants'] as List)
                  .firstWhere((id) => id != currentUserId);

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(otherUserId)
                    .get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const SizedBox();
                  }

                  final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                  final userName = userData['name'] ?? 'Unknown User';
                  final lastMessageTime = (data['lastMessageTime'] as Timestamp).toDate();
                  final isLastMessageFromMe = data['lastMessageSenderId'] == currentUserId;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: userData['profileImage'] != null
                          ? NetworkImage(userData['profileImage'])
                          : null,
                      child: userData['profileImage'] == null
                          ? Text(userName[0].toUpperCase())
                          : null,
                    ),
                    title: Text(userName),
                    subtitle: Text(
                      isLastMessageFromMe
                          ? 'You: ${data['lastMessage']}'
                          : data['lastMessage'] ?? 'No messages yet',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      '${lastMessageTime.hour}:${lastMessageTime.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            currentUserId: currentUserId,
                            otherUserId: otherUserId,
                            otherUserName: userName,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
} 