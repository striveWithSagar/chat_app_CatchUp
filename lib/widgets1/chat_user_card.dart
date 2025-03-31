import 'package:cached_network_image/cached_network_image.dart';
import 'package:catchup/apis/apiss.dart';
import 'package:catchup/helper/my_date_util.dart';
import 'package:catchup/models1/message.dart';
import 'package:catchup/screens/chat_screen.dart';
import 'package:catchup/widgets1/dialogs/profile_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';


import '../models1/chat_user.dart';// Ensure APIss is properly imported

class ChatUserCard extends StatefulWidget {
  final ChatUserr2 user;

  const ChatUserCard({super.key, required this.user});

  @override
  State<ChatUserCard> createState() => _ChatUserCardState();
}

class _ChatUserCardState extends State<ChatUserCard> {

  //last message info
  Message? _message;

  @override
  Widget build(BuildContext context) {
    Size mq = MediaQuery.of(context).size;

    return Card(
      child: InkWell(
        onTap: () {
          // Navigate to chat screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(user: widget.user),
            ),
          );
        },
        child: StreamBuilder(
          stream: APIss.getLastMessage(widget.user), // Ensure APIss is defined
          builder: (context, snapshot) {
            final data = snapshot.data?.docs;
            final list =
                data?.map((e) => Message.fromJson(e.data())).toList() ?? [];
            if (list.isNotEmpty) _message = list[0];

            return ListTile(
              // User profile picture
              leading: InkWell(
                onTap: () {
                  showDialog(
                      context: context,
                      builder: (_) => ProfileDialog(user: widget.user));
                },

                child: ClipRRect(
                  borderRadius: BorderRadius.circular(mq.height * 0.03),
                  child: CachedNetworkImage(
                    width: mq.height * 0.055,
                    height: mq.height * 0.055,
                    fit: BoxFit.cover,
                    imageUrl: widget.user.image.isNotEmpty
                        ? widget.user.image
                        : "https://via.placeholder.com/150",
                    errorWidget: (context, url, error) =>
                    const CircleAvatar(child: Icon(CupertinoIcons.person)),
                  ),
                ),
              ),

              // User name
              title: Text(widget.user.name),

              //last message
              subtitle: Text(
                  _message != null
                      ? _message!.type == MyType.image ? 'image'
                  : _message!.msg
                      : widget.user.about,
                  maxLines: 1),

              //last message time
              trailing: _message == null
                  ? null //show nothing when no message is sent
                  : _message!.read.isEmpty &&
                  _message!.fromId != APIss.user.uid
                  ?
              //show for unread message
              const SizedBox(
                width: 15,
                height: 15,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                      color: Color.fromARGB(255, 0, 230, 119),
                      borderRadius:
                      BorderRadius.all(Radius.circular(10))),
                ),
              )
                  :
              //message sent time
              Text(
                MyDateUtil.getLastMessageTime(
                    context: context, time: _message!.sent),
                style: const TextStyle(color: Colors.black54),
              ),
            );
          },
        )),
    );
  }
}