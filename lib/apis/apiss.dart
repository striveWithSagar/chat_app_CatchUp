import 'dart:developer';
import 'dart:io';

import 'package:catchup/models1/message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models1/chat_user.dart';

class APIss{
  //for authentication
  static FirebaseAuth auth = FirebaseAuth.instance;

  //for accessing cloud firebase database
  static FirebaseFirestore firestore = FirebaseFirestore.instance;

  //for accessing cloud firebase Storage
  static FirebaseStorage storage = FirebaseStorage.instance;

  static FirebaseMessaging FMessaging = FirebaseMessaging.instance;



  //to return current user
  static User get user => auth.currentUser!;

  //for storing self information
  static late ChatUserr2 mee;

  //for checking if user exists or not
  static Future<bool> userExists() async{
    return (await firestore.collection('users').doc(auth.currentUser!.uid).get()).exists;
  }

  //for getting current user info
  static Future<void> getSelfInfo() async{
    await firestore.
        collection('users').
        doc(user.uid).
        get().then((user) async{

            if(user.exists){
            mee = ChatUserr2.fromJson(user.data()!);
            APIss.updateActiveStatus(true);

            await getFirebaseMessagingToken();
            log('My Data: ${user.data()}');
        }
      else{
        await createUser().then((value) => getSelfInfo());
      }
    });
  }

  //for creating a new user
  static Future<void> createUser() async{

    final time = DateTime.now().millisecondsSinceEpoch.toString();


    final chatUser = ChatUserr2(
                  id: user.uid,
                  name: user.displayName.toString(),
                  email: user.email.toString(),
                  about: "Hey I am using CatchUp",
                  image: user.photoURL.toString(),
                  createdAt: time,
                  isOnline: false,
                  lastActive: time,
                  pushToken: '',

    );
    return await firestore.collection('users').doc(user.uid).set(chatUser.toJson());
  }


  //for updating the information
  static Future<void> updateUserInfo() async{
    await firestore.collection('users').doc(user.uid).update({
      'name' : mee.name ,
      'about' : mee.about ,
    });
  }

  //update profile picture of user
  static Future<void> updateProfilePicture(File file) async{
    final ext = file.path.split('.').last;
    final ref = storage.ref().child('profile_pictures/${user.uid}.$ext');
    await ref.putFile(file, SettableMetadata(contentType: 'image/$ext')).then((p0){
      log('Data Transferred: ${p0.bytesTransferred / 1000} kb');
    });

    mee.image = await ref.getDownloadURL();

    await firestore.collection('users').doc(user.uid).update({
      'image' : mee.image
    });

  }


  ///******************   Char Screen Related APIs   *******************
  // chats (collection) --> conversation_id(doc) --> messages (collection) --> messages(doc)
  ///

  // useful for getting conversation id
  static String getConversationID(String id) => user.uid.hashCode <= id.hashCode
      ? '${user.uid}_$id'
      : '${id}_${user.uid}';

  // for getting all messages of a specific conversation from firestore database
  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllMessages(
      ChatUserr2 user) {
    return firestore
        .collection('chats/${getConversationID(user.id)}/messages/')
        .orderBy('sent', descending: true)
        .snapshots();
  }


  //for sending messages
  static Future<void> sendMessage(
      ChatUserr2 chatUser, String msg, MyType type) async {
    //message sending time (also used as id)
    final time = DateTime.now().millisecondsSinceEpoch.toString();

    //message to send
    final Message message = Message(
        told: chatUser.id,
        msg: msg,
        read: '',
        type: type,
        fromId: user.uid,
        sent: time);

    final ref = firestore
        .collection('chats/${getConversationID(chatUser.id)}/messages/');
    await ref.doc(time).set(message.toJson());
  }

  //update read status of message
  static Future<void> updateMessageReadStatus(Message message) async {
    firestore
        .collection('chats/${getConversationID(message.fromId)}/messages/')
        .doc(message.sent)
        .update({'read': DateTime.now().millisecondsSinceEpoch.toString()});
  }

  //get only last message of a specific chat
  static Stream<QuerySnapshot<Map<String, dynamic>>> getLastMessage(
      ChatUserr2 user) {
    return firestore
        .collection('chats/${getConversationID(user.id)}/messages/')
        .orderBy('sent', descending: true)
        .limit(1)
        .snapshots();
  }

  //send chat image
  static Future<void> sendChatImage(ChatUserr2 chatUser, File file) async {
    //getting image file extension
    final ext = file.path.split('.').last;

    //storage file ref with path
    final ref = storage.ref().child(
        'images/${getConversationID(chatUser.id)}/${DateTime.now().millisecondsSinceEpoch}.$ext');

    //uploading image
    await ref
        .putFile(file, SettableMetadata(contentType: 'image/$ext'))
        .then((p0) {
      log('Data Transferred: ${p0.bytesTransferred / 1000} kb');
    });

    //updating image in firestore database
    final imageUrl = await ref.getDownloadURL();
    await sendMessage(chatUser, imageUrl, MyType.image);
  }

  // for getting specific user info
  static Stream<QuerySnapshot<Map<String, dynamic>>> getUserInfo(
      ChatUserr2 chatUser) {
    return firestore
        .collection('users')
        .where('id', isEqualTo: chatUser.id)
        .snapshots();
  }

  // update online or last active status of user
  static Future<void> updateActiveStatus(bool isOnline) async {
    firestore.collection('users').doc(user.uid).update({
      'is_online': isOnline,
      'last_active': DateTime.now().millisecondsSinceEpoch.toString(),
      'push_token': mee.pushToken,
    });
  }

  // for getting firebase messaging token
  static Future<void> getFirebaseMessagingToken() async {
    await FMessaging.requestPermission();

    await FMessaging.getToken().then((t) {
      if (t != null) {
        mee.pushToken = t;
        log('Push Token: $t');
      }
    });
  }

  //delete message
  static Future<void> deleteMessage(Message message) async {
    await firestore
        .collection('chats/${getConversationID(message.told)}/messages/')
        .doc(message.sent)
        .delete();

    if (message.type == MyType.image) {
      await storage.refFromURL(message.msg).delete();
    }
  }

  //update message
  static Future<void> updateMessage(Message message, String updatedMsg) async {
    await firestore
        .collection('chats/${getConversationID(message.told)}/messages/')
        .doc(message.sent)
        .update({'msg': updatedMsg});
  }

  // for adding an chat user for our conversation
  static Future<bool> addChatUser(String email) async {
    final data = await firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .get();

    log('data: ${data.docs}');

    if (data.docs.isNotEmpty && data.docs.first.id != user.uid) {
      //user exists

      log('user exists: ${data.docs.first.data()}');

      firestore
          .collection('users')
          .doc(user.uid)
          .collection('my_users')
          .doc(data.docs.first.id)
          .set({});

      return true;
    } else {
      //user doesn't exists

      return false;
    }
  }

  // for getting id's of known users from firestore database
  static Stream<QuerySnapshot<Map<String, dynamic>>> getMyUsersId() {
    return firestore
        .collection('users')
        .doc(user.uid)
        .collection('my_users')
        .snapshots();
  }

  // for getting all users from firestore database
  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllUsers(
      List<String> userIds) {
    log('\nUserIds: $userIds');

    return firestore
        .collection('users')
        .where('id',
        whereIn: userIds.isEmpty
            ? ['']
            : userIds) //because empty list throws an error
    // .where('id', isNotEqualTo: user.uid)
        .snapshots();
  }

  // for adding an user to my user when first message is send
  static Future<void> sendFirstMessage(
      ChatUserr2 chatUser, String msg, MyType type) async {
    await firestore
        .collection('users')
        .doc(chatUser.id)
        .collection('my_users')
        .doc(user.uid)
        .set({}).then((value) => sendMessage(chatUser, msg, type));
  }

}
