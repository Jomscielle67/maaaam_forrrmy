import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:daddies_store/views/chat/chat_screen.dart';

class VendorChatListScreen extends StatelessWidget {
  final String vendorId;

  const VendorChatListScreen({
    Key? key,
    required this.vendorId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('VendorChatListScreen - vendorId: $vendorId'); // Debug print
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Messages'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('conversations')
            .where('participants', arrayContains: vendorId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            print('VendorChatListScreen - Error: ${snapshot.error}'); // Debug print
            return const Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            print('VendorChatListScreen - Waiting for data...'); // Debug print
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            print('VendorChatListScreen - No data or empty docs'); // Debug print
            return const Center(
              child: Text('No messages yet'),
            );
          }

          print('VendorChatListScreen - Number of conversations: ${snapshot.data!.docs.length}'); // Debug print

          // Sort conversations by lastMessageTime
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
              final data = doc.data() as Map<String, dynamic>?;
              
              if (data == null) {
                print('VendorChatListScreen - Data is null for doc at index $index'); // Debug print
                return const SizedBox();
              }

              final participants = data['participants'] as List?;
              if (participants == null || participants.isEmpty) {
                print('VendorChatListScreen - No participants for doc at index $index'); // Debug print
                return const SizedBox();
              }

              final buyerId = participants.firstWhere(
                (id) => id != vendorId,
                orElse: () => '',
              );

              if (buyerId.isEmpty) {
                print('VendorChatListScreen - No buyer ID found for doc at index $index'); // Debug print
                return const SizedBox();
              }

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('buyers')
                    .doc(buyerId)
                    .get(),
                builder: (context, buyerSnapshot) {
                  if (!buyerSnapshot.hasData) {
                    print('VendorChatListScreen - No buyer data for ID: $buyerId'); // Debug print
                    return const SizedBox();
                  }

                  final buyerData = buyerSnapshot.data!.data() as Map<String, dynamic>?;
                  if (buyerData == null) {
                    print('VendorChatListScreen - Buyer data is null for ID: $buyerId'); // Debug print
                    return const SizedBox();
                  }

                  final buyerName = buyerData['fullName'] as String? ?? 'Unknown Customer';
                  final lastMessageTime = (data['lastMessageTime'] as Timestamp).toDate();
                  final isLastMessageFromMe = data['lastMessageSenderId'] == vendorId;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: buyerData['profileImage'] != null
                          ? NetworkImage(buyerData['profileImage'] as String)
                          : null,
                      child: buyerData['profileImage'] == null
                          ? Text(buyerName[0].toUpperCase())
                          : null,
                    ),
                    title: Text(buyerName),
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
                            currentUserId: vendorId,
                            otherUserId: buyerId,
                            otherUserName: buyerName,
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