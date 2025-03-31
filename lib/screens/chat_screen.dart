import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:catchup/apis/apiss.dart';
import 'package:catchup/helper/my_date_util.dart';
import 'package:catchup/main.dart';

import 'package:catchup/models1/chat_user.dart';
import 'package:catchup/models1/message.dart';
import 'package:catchup/screens/view_profile_screen_.dart';
import 'package:catchup/widgets1/chat_user_card.dart';
import 'package:catchup/widgets1/message_card.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:flutter/foundation.dart' as foundation;
import 'package:image_picker/image_picker.dart';


class ChatScreen extends StatefulWidget {
  final ChatUserr2 user;

  const ChatScreen({super.key, required this.user});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {

  //for storing all messages
   List<Message> _list = [];

   //for handling text changes
   final _textController = TextEditingController();

   bool _showEmoji = false, _isUploading = false;

  @override
  Widget build(BuildContext context) {

    Size mq1 = MediaQuery.of(context).size;
    return GestureDetector(
      onTap: FocusScope.of(context).unfocus,
      child: SafeArea(
        child: WillPopScope(
          onWillPop: (){
            if(_showEmoji){
              setState(() {
                _showEmoji = !_showEmoji;
              });
              return Future.value(false);
            }
            else{
              return Future.value(true);
            }
          },
            child: Scaffold(
              appBar: AppBar(
                automaticallyImplyLeading: false,
                flexibleSpace: _appBar(),
              ),
                  
              backgroundColor: const Color.fromARGB(255, 234, 248, 255),
                  
              //body
              body: Column(
                children: [
                  Expanded(
                    child: StreamBuilder(
                    stream: APIss.getAllMessages(widget.user),
                            builder: (context, snapshot) {
                              switch (snapshot.connectionState) {
                  
                    //if some or all data is loaded then show it
                    case ConnectionState.waiting:
                    case ConnectionState.none:
                      //return const Center(child: CircularProgressIndicator());
                      return const SizedBox();
                  
                      //if some or all data is loaded then show it
                    case ConnectionState.active:
                    case ConnectionState.done:
                       final data = snapshot.data?.docs;
                  
                       _list =
                          data?.map((e) => Message.fromJson(e.data())).toList() ??
                                        [];
                  
                      if (_list.isNotEmpty) {
                        return ListView.builder(
                          reverse: true,
                  
                          itemCount: _list.length,
                  
                          physics: const BouncingScrollPhysics(),
                           itemBuilder: (context, index) {
                             return MessageCard(message: _list[index]);
                             //return Text('Message: ${_list[index]}');
                  
                          },
                        );
                      } else {
                        return Center(
                           child: const Text(
                               'Say Hi! 👋',
                             style: TextStyle(
                               fontSize: 50,
                             ),
                  
                           )
                              ,
                  
                        );
                      }
                              }
                            },
                          ),
                  )
                  ,//
                  if(_isUploading)
                  const Align(
                    alignment: Alignment.centerRight,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                      child: CircularProgressIndicator(strokeWidth: 2,)
                  )
                  ),

                  _chatInput(),
                  
                  
                  // SizedBox(
                  //   height: mq.height * .35,
                  //   child: EmojiPicker(
                  //   textEditingController: _textController,
                  //   config: Config(
                  //        columns: 7,
                  //        emojiSizeMax: 32 * (Platform.isIOS ? 1.30 : 1.0),
                  //       //
                  //   ),
                  //   ),
                  // )



      ],
              ),
            
            ),

        ),
      ),
    );
  }

  // app bar widget
  Widget _appBar(){
    Size mq = MediaQuery.of(context).size;

    return InkWell(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ViewProfileScreen(user: widget.user)));
      },

        child: StreamBuilder(
            stream: APIss.getUserInfo(widget.user),
            builder: (context, snapshot) {

            final data = snapshot.data?.docs;
            final list =
                data?.map((e) => ChatUserr2.fromJson(e.data())).toList() ?? [];

        return Row(children: [
          //back button
          IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.black54,
              )),

          //user profile picture
          ClipRRect(
            borderRadius: BorderRadius.circular(mq.height * .1),
            child: CachedNetworkImage(
              width: mq.height * .05,
              height: mq.height * .05,
              fit: BoxFit.cover,
              imageUrl: list.isNotEmpty ? list[0].image : widget.user.image.isNotEmpty
                  ? widget.user.image
                  : "https://via.placeholder.com/150",
              errorWidget: (context, url, error) =>
              const CircleAvatar(
                  child: Icon(CupertinoIcons.person)),
            ),
          ),

          SizedBox(width: 10),

          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              //user Name
              Text(list.isNotEmpty ? list[0].name : widget.user.name,
                  style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500)),

              SizedBox(height: 2),

              //Last time Seen
              Text(
                list.isNotEmpty ?
                    list[0].isOnline ? 'Online'
                        : MyDateUtil.getLastActiveTime(
                        context: context,
                        lastActive: list[0].lastActive
                    )
                    : MyDateUtil.getLastActiveTime(
                    context: context,
                    lastActive: widget.user.lastActive
                ),
                style: const TextStyle(
                  fontSize:10,
                  color: Colors.black87,
                ),
              ),
            ],
          )
        ],);


    })
    );
  }

  //bottom chat input field
  Widget _chatInput(){
    Size mq = MediaQuery.of(context).size;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: mq.height * .01, horizontal: mq.width * .025),
      child: Row(
        children: [
          Expanded(
            //Card for elevation effect
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Row(
                children: [
                  //emoji button
                  IconButton(
                      onPressed: () {
                        onTap: FocusScope.of(context).unfocus();
                        setState(() => _showEmoji = !_showEmoji);
                      },
                      icon: const Icon(
                        Icons.emoji_emotions,
                        color: Colors.blueAccent,
                        size: 25,
                      )),

                  Expanded(
                    child: TextField(
                      controller: _textController,
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      onTap: () {
                        if (_showEmoji) setState(() => _showEmoji = !_showEmoji);
                      },
                      decoration: const InputDecoration(
                        hintText: 'Type Something....',
                          hintStyle: TextStyle(color: Colors.blueAccent,), border: InputBorder.none
                      ),
                    ),
                  ),
            
                  //gallery button
                  IconButton(
                      onPressed: () async {
                        final ImagePicker picker = ImagePicker();
                        // Pick an image.
                        final List<XFile> images = await picker.pickMultiImage(imageQuality: 80);

                        for(var i in images){
                          setState(() => _isUploading = true);
                          await APIss.sendChatImage(
                              widget.user,
                              File(i.path));
                          setState(() => _isUploading = false);

                        }
                      },
                      icon: const Icon(
                        Icons.image,
                        color: Colors.blueAccent,
                        size: 26,
      
                      )),
            
                  //camera button
                  IconButton(
                      onPressed: () async {
                          final ImagePicker picker = ImagePicker();
                          // Pick an image.
                          final XFile? image = await picker.pickImage(
                              source: ImageSource.camera,
                              imageQuality: 80);
                          if(image != null) {
                            setState(() => _isUploading = true);

                            await APIss.sendChatImage(
                                widget.user,
                                File(image.path));
                            setState(() => _isUploading = false);

                          }
                      },
                      icon: const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.blueAccent,
                        size: 26,
                      )),

                  //adding some space
                  SizedBox(width: mq.width * .02),
            
                ],
              ),
            ),
          ),


          //send message button
          MaterialButton(

            onPressed: () {
              if (_textController.text.isNotEmpty) {
                if(_list.isEmpty){
                  APIss.sendFirstMessage(widget.user, _textController.text, MyType.text);


                }else{
                  APIss.sendMessage(widget.user, _textController.text, MyType.text);

                }
                _textController.text = '';
              }
            },

            minWidth: 0, //to remove the space between icons
            padding: EdgeInsets.only(top: 10, bottom: 10, right: 5, left: 10),
            shape: CircleBorder(),
            color: Colors.green,
            child: const Icon(
              Icons.send,
              color: Colors.white,
              size: 28,
            ),
          )
        ],
      ),
    );

  }
}
