import 'package:catchup/models1/chat_user.dart';
import 'package:catchup/screens/profile_screen.dart';
import 'package:catchup/widgets1/chat_user_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../apis/apiss.dart';
import '../helper/dialogs.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<ChatUserr2> _list = [];
  final List<ChatUserr2> _searchList = [];
  bool _isSearching = false;

  Future<void> _signOut() async {
    await APIss.auth.signOut();
    await GoogleSignIn().signOut();
  }

  @override
  void initState() {
    super.initState();
    APIss.getSelfInfo();


    //for updating user active status according to lifecycle events
    //resume -- active or online
    //pause  -- inactive or offline
    SystemChannels.lifecycle.setMessageHandler((message) {

      if (APIss.auth.currentUser != null){

        if (APIss.auth.currentUser != null) {
          if (message.toString().contains('resume')) {
            APIss.updateActiveStatus(true);
          }
          if (message.toString().contains('pause')) {
            APIss.updateActiveStatus(false);
          }
        }

      }



      return Future.value(message);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      //for hiding keyboard when a tap is detected on screen
      onTap: () => FocusScope.of(context).unfocus(),
      child: WillPopScope(
        //if search in on & back button is pressed then close search
        //or else simple close current screen on back button click
        onWillPop: () {
          if(_isSearching){
            setState(() {
              _isSearching = !_isSearching;
            });
            return Future.value(false);
          }
          else{
            return Future.value(false);
          }

        },
        child: Scaffold(
          appBar: AppBar(
            leading: const Icon(CupertinoIcons.home),
            elevation: 1,
            centerTitle: true,


            title: _isSearching
                ? TextField(
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Name, Email, ...',
              ),
              autofocus: true,

              style: const TextStyle(fontSize: 17, letterSpacing: 0.5),

              onChanged: (val) {

                _searchList.clear();

                for (var user in _list) {
                  if (user.name.toLowerCase().contains(val.toLowerCase()) ||
                      user.email.toLowerCase().contains(val.toLowerCase())) {
                    _searchList.add(user);
                  }
                }
                setState(() {});
              },
            )
                : const Text('CatchUp'),
            actions: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                  });
                },
                icon: Icon(
                  _isSearching
                      ? CupertinoIcons.clear_circled_solid
                      : Icons.search,
                ),
              ),
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfileScreen(user: APIss.mee),
                    ),
                  );
                },
                icon: const Icon(Icons.more_vert),
              ),
            ],
          ),



          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FloatingActionButton(
              onPressed: () {
                _addChatUserDialog();
              },
              child: const Icon(Icons.add_comment_rounded),
            ),
          ),



          body: StreamBuilder(
              stream: APIss.getMyUsersId() ,
              builder: (context, snapshot)
              {
            switch (snapshot.connectionState) {
              case ConnectionState.waiting:
              case ConnectionState.none:
                //return const Center(child: CircularProgressIndicator());

              case ConnectionState.active:
              case ConnectionState.done:


                return StreamBuilder(
                  stream: APIss.getAllUsers(
                      snapshot.data?.docs.map((e) => e.id).toList() ?? []),
                  builder: (context, snapshot) {
                    switch (snapshot.connectionState) {
                      case ConnectionState.waiting:
                      case ConnectionState.none:
                        return const Center(child: CircularProgressIndicator());

                      case ConnectionState.active:
                      case ConnectionState.done:
                        final data = snapshot.data?.docs;
                        _list = data?.map((e) => ChatUserr2.fromJson(e.data()))
                            .toList() ?? [];

                        if (_list.isNotEmpty) {
                          return ListView.builder(
                            itemCount: _isSearching ? _searchList.length : _list
                                .length,
                            physics: const BouncingScrollPhysics(),
                            itemBuilder: (context, index) {
                              return ChatUserCard(
                                user: _isSearching
                                    ? _searchList[index]
                                    : _list[index],
                              );
                            },
                          );
                        } else {
                          return Center(
                            child: Stack(
                              children: [
                                const Text(
                                  'NO Connections Found!!',
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                    letterSpacing: 1.5,
                                    shadows: [
                                      Shadow(
                                        offset: Offset(3.0, 3.0),
                                        blurRadius: 5.0,
                                        color: Colors.black38,
                                      ),
                                    ],
                                  ),
                                ),
                                ShaderMask(
                                  shaderCallback: (bounds) =>
                                      const LinearGradient(
                                        colors: [Colors.blue, Colors.purple],
                                        tileMode: TileMode.mirror,
                                      ).createShader(bounds),
                                  child: const Text(
                                    'NO Connections Found!!',
                                    style: TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                    }
                  },
                );
            }

          })
        ),
      ),
    );
  }

  void _addChatUserDialog() {
    Size mq = MediaQuery.of(context).size;

    String email = '';

    showDialog(
        context: context,
        builder: (_) => AlertDialog(
          contentPadding: const EdgeInsets.only(
              left: 24, right: 24, top: 20, bottom: 10),

          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20))),

          //title
          title: const Row(
            children: const [
              Icon(
                Icons.person_add,
                color: Colors.blue,
                size: 28,
              ),
              Text(' Add User')
            ],
          ),

          //content
          content: TextFormField(

            maxLines: null,
            onChanged: (value) => email = value,
            decoration: const InputDecoration(
                hintText: 'Email Id',
                prefixIcon: Icon(Icons.email, color: Colors.blue),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(15)))),
          ),

          //actions
          actions: [
            //cancel button
            MaterialButton(
                onPressed: () {
                  //hide alert dialog
                  Navigator.pop(context);
                },
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.blue, fontSize: 16),
                )),

            //add button
            MaterialButton(
                onPressed: () async {
                  //hide alert dialog
                  Navigator.pop(context);
                  if (email.trim().isNotEmpty) {
                    await APIss.addChatUser(email).then((value) {
                      if (!value) {
                        Dialogs.showSnackbar(
                            context, 'User does not Exists!');
                      }
                    });
                  }
                },
                child: const Text(
                  'Add',
                  style: TextStyle(color: Colors.blue, fontSize: 16),
                ))
          ],
        ));
  }
}