import 'dart:io';
import 'package:catchup/helper/dialogs.dart';
import 'package:catchup/screens/auth/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../apis/apiss.dart';
import '../models1/chat_user.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfileScreen extends StatefulWidget {
  final ChatUserr2 user;
  const ProfileScreen({super.key, required this.user});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _image;
  final ImagePicker picker = ImagePicker();

  Future<void> pickImage(ImageSource source) async {
    final XFile? image = await picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _image = image.path;
      });
      Navigator.pop(context);
    }
  }

  Future<void> uploadImage() async {
    if (_image == null) return;
    final fileName = DateTime
        .now()
        .millisecondsSinceEpoch
        .toString();
    final path = 'uploads/$fileName';
    try {
      await Supabase.instance.client.storage
          .from('images')
          .upload(path, File(_image!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Image uploaded successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload failed: \$e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Size mq = MediaQuery
        .of(context)
        .size;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          elevation: 1,
          centerTitle: true,
          title: const Text('Profile Screen'),
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: FloatingActionButton.extended(
            backgroundColor: Colors.redAccent,
            onPressed: () async {
              Dialogs.showPorgressBar(context);

              await APIss.updateActiveStatus(false);

              await APIss.auth.signOut().then((value) async {
                await GoogleSignIn().signOut().then((value) {
                  Navigator.pop(context);
                  Navigator.pop(context);

                  APIss.auth = FirebaseAuth.instance;


                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                  );
                });
              });
            },
            icon: const Icon(Icons.logout, color: Colors.white),
            label: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ),
        body: Form(
          key: _formKey,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: mq.width * .05),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: mq.height * 0.03),
                  Stack(
                    children: [
                      _image != null ?
                      ClipRRect(
                        borderRadius: BorderRadius.circular(mq.height * .1),
                        child: Image.file(
                          File(_image!),
                          width: mq.height * .2,
                          height: mq.height * .2,
                          fit: BoxFit.cover,
                        ),
                      ) :
                      ClipRRect(
                        borderRadius: BorderRadius.circular(mq.height * .1),
                        child: CachedNetworkImage(
                          width: mq.height * .2,
                          height: mq.height * .2,
                          fit: BoxFit.cover,
                          imageUrl: widget.user.image.isNotEmpty
                              ? widget.user.image
                              : "https://via.placeholder.com/150",
                          errorWidget: (context, url, error) =>
                          const CircleAvatar(
                              child: Icon(CupertinoIcons.person)),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: MaterialButton(
                          elevation: 1,
                          onPressed: _showBottomSheet,
                          shape: const CircleBorder(),
                          color: Colors.white,
                          child: const Icon(Icons.edit, color: Colors.blue),
                        ),
                      )
                    ],
                  ),
                  SizedBox(height: mq.height * 0.03),
                  Text(widget.user.email,
                      style: const TextStyle(
                          color: Colors.black54, fontSize: 16)),
                  SizedBox(height: mq.height * 0.05),
                  TextFormField(
                    initialValue: widget.user.name,
                    onSaved: (val) => APIss.mee.name = val ?? '',
                    validator: (val) =>
                    val != null && val.isNotEmpty ? null : 'Required Field',
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.person, color: Colors.blue),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      hintText: 'eg. Happy Singh',
                      label: const Text('Name'),
                    ),
                  ),
                  SizedBox(height: mq.height * 0.02),
                  TextFormField(
                    initialValue: widget.user.about,
                    onSaved: (val) => APIss.mee.about = val ?? '',
                    validator: (val) =>
                    val != null && val.isNotEmpty ? null : 'Required Field',
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                          Icons.info_outline, color: Colors.blue),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      hintText: 'eg. Feeling Happy',
                      label: const Text('About'),
                    ),
                  ),
                  SizedBox(height: mq.height * 0.03),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      shape: const StadiumBorder(),
                      minimumSize: Size(mq.width * .5, mq.height * .06),
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        APIss.updateUserInfo().then((value) {
                          Dialogs.showSnackbar(
                              context, 'Profile Updated Successfully');
                        });
                      }
                    },
                    icon: const Icon(Icons.edit, size: 28),
                    label: const Text('UPDATE', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showBottomSheet() {
    Size mq = MediaQuery
        .of(context)
        .size;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (_) {
        return ListView(
          shrinkWrap: true,
          padding: EdgeInsets.only(
              top: mq.height * .03, bottom: mq.height * .05),
          children: [
            const Text('Pick Profile Picture',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
            SizedBox(height: mq.height * .02),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                    style : ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: const CircleBorder(),
                          fixedSize: Size(mq.width * .3, mq.height * .15)),
                          onPressed: () async {

                              //image picker, used from google - pub.dev

                                final ImagePicker picker = ImagePicker();
                              // Pick an image.
                                final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);

                              if(image != null){
                                //for updating
                                setState(() {
                                  _image = image.path;
                                });

                                APIss.updateProfilePicture(File(_image!));
                                
                                //for hiding bottom sheet
                                Navigator.pop(context);
                        }
                      },
                      child: Image.asset('images/gallery.png')),


                      ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                shape: const CircleBorder(),
                                fixedSize: Size(mq.width * .3, mq.height * .15)),
                            onPressed: () async {
                              final ImagePicker picker = ImagePicker();
                              // Pick an image.
                              final XFile? image = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);

                              if(image != null){
                                setState(() {
                                  _image = image.path;
                                });

                                APIss.updateProfilePicture(File(_image!));

                                //for hiding botton sheet
                                Navigator.pop(context);
                              }
                            },
                            child: Image.asset('images/camera.png')),


                ],
              )],);});

  }
}









// import 'dart:developer';
// import 'dart:io';
// import 'package:catchup/helper/dialogs.dart';
// import 'package:catchup/screens/auth/login_screen.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:image_picker/image_picker.dart';
// import '../apis/apiss.dart';
// import '../models1/chat_user.dart';
// import 'package:cached_network_image/cached_network_image.dart';
//
// // ProfileScreen Class
// class ProfileScreen extends StatefulWidget {
//   final ChatUserr user;
//
//   const ProfileScreen({super.key, required this.user});
//
//   @override
//   State<ProfileScreen> createState() => _ProfileScreenState();
// }
//
// class _ProfileScreenState extends State<ProfileScreen> {
//   final _formKey = GlobalKey<FormState>();
//   String? _image;
//
//   @override
//   Widget build(BuildContext context) {
//
//     Size mq = MediaQuery.of(context).size;
//     return GestureDetector(
//       //for hiding keyboard
//       onTap: () => FocusScope.of(context).unfocus(),
//       child: Scaffold(
//         appBar: AppBar(
//           elevation: 1,
//           centerTitle: true,
//           title: const Text('Profile Screen'),
//         ),
//
//         //floating action button to add new user
//         floatingActionButton: Padding(
//           padding: const EdgeInsets.only(bottom: 10),
//           child: FloatingActionButton.extended(
//             backgroundColor: Colors.redAccent,
//             onPressed: () async {
//               Dialogs.showPorgressBar(context);  // Corrected typo here
//               await APIss.auth.signOut().then((value) async {
//                 await GoogleSignIn().signOut().then((value) {
//                   Navigator.pushAndRemoveUntil(
//                     context,
//                     MaterialPageRoute(builder: (_) => const LoginScreen()),
//                         (route) => false,
//                   );
//                 });
//               });
//             },
//             icon: const Icon(Icons.logout, color: Colors.white),
//             label: const Text('Logout', style: TextStyle(color: Colors.white)),
//           ),
//         ),
//
//         body: Form(
//           key: _formKey,
//           child: Padding(
//             padding: EdgeInsets.symmetric(horizontal: mq.width * .05),
//             child: SingleChildScrollView(
//               child: Column(
//                 children: [
//                   SizedBox(height: mq.height * 0.03),
//
//                   Stack(
//                     children: [
//                       //profile picture
//                       _image != null ?
//
//                       //local image
//                       ClipRRect(
//                   borderRadius: BorderRadius.circular(mq.height * .1),
//               child: Image.file(
//                 File(_image!),
//
//                 width: mq.height * .2,
//                 height: mq.height * .2,
//                 fit: BoxFit.cover,
//
//
//               ),
//             ) :
//
//                           // image from server
//                       ClipRRect(
//                         borderRadius: BorderRadius.circular(mq.height * .1),
//                         child: CachedNetworkImage(
//                           width: mq.height * .2,
//                           height: mq.height * .2,
//                           fit: BoxFit.cover,
//                           imageUrl: widget.user.image.isNotEmpty
//                               ? widget.user.image
//                               : "https://via.placeholder.com/150",
//                           errorWidget: (context, url, error) =>
//                           const CircleAvatar(child: Icon(CupertinoIcons.person)),
//                         ),
//                       ),
//
//
//                       Positioned(
//                         bottom: 0,
//                         right: 0,
//                         child: MaterialButton(
//                           elevation: 1,
//                           onPressed: () {
//                             _showBottomSheet();
//                           },
//                           shape: const CircleBorder(),
//                           color: Colors.white,
//                           child: const Icon(Icons.edit, color: Colors.blue),
//                         ),
//                       )
//                     ],
//                   ),
//
//                   SizedBox(height: mq.height * 0.03),
//
//                   Text(widget.user.email,
//                       style: const TextStyle(color: Colors.black54, fontSize: 16)),
//
//                   SizedBox(height: mq.height * 0.05),
//
//                   TextFormField(
//                     initialValue: widget.user.name,
//                     onSaved: (val) => APIss.me.name = val ?? '',
//                     validator: (val) =>
//                     val != null && val.isNotEmpty ? null : 'Required Field',
//                     decoration: InputDecoration(
//                       prefixIcon: const Icon(Icons.person, color: Colors.blue),
//                       border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//                       hintText: 'eg. Happy Singh',
//                       label: const Text('Name'),
//                     ),
//                   ),
//
//                   SizedBox(height: mq.height * 0.02),
//
//                   TextFormField(
//                     initialValue: widget.user.about,
//                     onSaved: (val) => APIss.me.about = val ?? '',
//                     validator: (val) =>
//                     val != null && val.isNotEmpty ? null : 'Required Field',
//                     decoration: InputDecoration(
//                       prefixIcon: const Icon(Icons.info_outline, color: Colors.blue),
//                       border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//                       hintText: 'eg. Feeling Happy',
//                       label: const Text('About'),
//                     ),
//                   ),
//
//                   SizedBox(height: mq.height * 0.03),
//
//                   ElevatedButton.icon(
//                     style: ElevatedButton.styleFrom(
//                       shape: const StadiumBorder(),
//                       minimumSize: Size(mq.width * .5, mq.height * .06),
//                     ),
//                     onPressed: () {
//                       if (_formKey.currentState!.validate()) {
//                         _formKey.currentState!.save();
//                         APIss.updateUserInfo().then((value) {
//                           Dialogs.showSnackbar(context, 'Profile Updated Successfully');
//                         });
//                       }
//                     },
//                     icon: const Icon(Icons.edit, size: 28),
//                     label: const Text('UPDATE', style: TextStyle(fontSize: 16)),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   void _showBottomSheet() {
//
//     Size mq = MediaQuery.of(context).size;
//
//
//     showModalBottomSheet(
//         context: context,
//         shape: const RoundedRectangleBorder(
//             borderRadius: BorderRadius.only(
//                 topLeft: Radius.circular(20),
//                 topRight: Radius.circular(20)
//             )),
//         builder: (_) {
//           return ListView(
//             shrinkWrap: true,
//             padding:
//                   EdgeInsets.only(top: mq.height * .03, bottom: mq.height * .05),
//             children: [
//               const Text('Pick Profile Picture',
//                   textAlign: TextAlign.center,
//                   style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
//
//               SizedBox(height: mq.height * .02,),
//
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   //pick from gallery button
//
//                   ElevatedButton(
//                     style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.white,
//                         shape: const CircleBorder(),
//                         fixedSize: Size(mq.width * .3, mq.height * .15)),
//                         onPressed: () async {
//                           final ImagePicker picker = ImagePicker();
//                           // Pick an image.
//                           final XFile? image = await picker.pickImage(source: ImageSource.gallery);
//
//                           if(image != null){
//                             setState(() {
//                               _image = image.path;
//                             });
//                             //for hiding botton sheet
//                             Navigator.pop(context);
//                           }
//                         },
//                         child: Image.asset('images/gallery.png')),
//
//                   ElevatedButton(
//                       style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.white,
//                           shape: const CircleBorder(),
//                           fixedSize: Size(mq.width * .3, mq.height * .15)),
//                       onPressed: () async {
//                         final ImagePicker picker = ImagePicker();
//                         // Pick an image.
//                         final XFile? image = await picker.pickImage(source: ImageSource.camera);
//
//                         if(image != null){
//                           setState(() {
//                             _image = image.path;
//                           });
//                           //for hiding botton sheet
//                           Navigator.pop(context);
//                         }
//                       },
//                       child: Image.asset('images/camera.png')),
//
//
//                 ],
//               )
//             ],
//
//           );
//         });
//   }
// }
