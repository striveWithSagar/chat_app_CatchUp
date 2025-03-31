import 'dart:io';
import 'package:catchup/helper/dialogs.dart';
import 'package:catchup/screens/auth/login_screen.dart';
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
  String? _imagePath;
  File? _imageFile;

  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
        _imagePath = image.path;
      });
    }
  }

  Future<void> uploadImage() async {
    if (_imageFile == null) return;

    final String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final String path = 'uploads/$fileName';

    try {
      await Supabase.instance.client.storage
          .from('images')
          .upload(path, _imageFile!);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Image uploaded successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Size mq = MediaQuery.of(context).size;

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
              await APIss.auth.signOut().then((value) async {
                await GoogleSignIn().signOut().then((value) {
                  Navigator.pop(context);
                  Navigator.pop(context);
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
                      _imageFile != null
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(mq.height * .1),
                        child: Image.file(
                          _imageFile!,
                          width: mq.height * .2,
                          height: mq.height * .2,
                          fit: BoxFit.cover,
                        ),
                      )
                          : ClipRRect(
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
                          onPressed: () => _showBottomSheet(),
                          shape: const CircleBorder(),
                          color: Colors.white,
                          child: const Icon(Icons.edit, color: Colors.blue),
                        ),
                      )
                    ],
                  ),
                  SizedBox(height: mq.height * 0.03),
                  Text(widget.user.email,
                      style: const TextStyle(color: Colors.black54, fontSize: 16)),
                  SizedBox(height: mq.height * 0.05),
                  TextFormField(
                    initialValue: widget.user.name,
                    onSaved: (val) => APIss.mee.name = val ?? '',
                    validator: (val) =>
                    val != null && val.isNotEmpty ? null : 'Required Field',
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.person, color: Colors.blue),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                      prefixIcon: const Icon(Icons.info_outline, color: Colors.blue),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                          Dialogs.showSnackbar(context, 'Profile Updated Successfully');
                        });
                      }
                    },
                    icon: const Icon(Icons.edit, size: 28),
                    label: const Text('UPDATE', style: TextStyle(fontSize: 16)),
                  ),
                  SizedBox(height: mq.height * 0.02),
                  ElevatedButton.icon(
                    onPressed: uploadImage,
                    icon: const Icon(Icons.upload, size: 28),
                    label: const Text('UPLOAD IMAGE', style: TextStyle(fontSize: 16)),
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
    Size mq = MediaQuery.of(context).size;
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
          padding: EdgeInsets.only(top: mq.height * .03, bottom: mq.height * .05),
          children: [
            const Text(
              'Pick Profile Picture',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: mq.height * .02),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: const CircleBorder(),
                    fixedSize: Size(mq.width * .3, mq.height * .15),
                  ),
                  onPressed: () async {
                    await pickImage();
                    Navigator.pop(context);
                  },
                  child: Image.asset('images/gallery.png'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}














// import 'dart:io';
// import 'package:catchup/helper/dialogs.dart';
// import 'package:catchup/screens/auth/login_screen.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import '../apis/apiss.dart';
// import '../models1/chat_user.dart';
// import 'package:cached_network_image/cached_network_image.dart';
//
// // ProfileScreen Class
// class ProfileScreen extends StatefulWidget {
//   final ChatUserr user;
//   const ProfileScreen({super.key, required this.user});
//   @override
//   State<ProfileScreen> createState() => _ProfileScreenState();
// }
//
// class _ProfileScreenState extends State<ProfileScreen> {
//
//
//
//
//   @override
//   Widget build(BuildContext context) {
//     Size mq = MediaQuery.of(context).size;
//
//     //to hide the keyboard
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
//
//
//           child: FloatingActionButton.extended(
//             backgroundColor: Colors.redAccent,
//             onPressed: () async {
//               Dialogs.showPorgressBar(context);  // Corrected typo here
//                 await APIss.auth.signOut().then((value) async {
//                 await GoogleSignIn().signOut().then((value) {
//
//                   Navigator.pop(context);
//                   Navigator.pop(context);
//
//                   Navigator.pushAndRemoveUntil(
//                     context,
//                     MaterialPageRoute(builder: (_) => const LoginScreen()),
//                         (route) => false,
//                   );
//                 });
//               });
//             },
//             //logout button
//             icon: const Icon(Icons.logout, color: Colors.white),
//             label: const Text('Logout', style: TextStyle(color: Colors.white)),
//           ),
//         ),
//
//         body: Form(
//           key: _formKey,
//           child: Padding(
//             //to put the image in center we are using padding
//             padding: EdgeInsets.symmetric(horizontal: mq.width * .05),
//
//             //scrolling facility to the screen
//             child: SingleChildScrollView(
//
//               child: Column(
//                 children: [
//                   //for adding some space between objects
//                   SizedBox(height: mq.height * 0.03),
//                   //we are using stack to put the widget on other widget
//                   Stack(
//                     children: [
//                       //profile picture
//                       _image != null ?
//
//                       //local image
//                       ClipRRect(
//                         borderRadius: BorderRadius.circular(mq.height * .1),
//                         child: Image.file(
//                           File(_image!),
//
//                           width: mq.height * .2,
//                           height: mq.height * .2,
//                           fit: BoxFit.cover,
//                         ),
//                       ) :
//
//                       // image from server
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
//                       //edit image button
//                       Positioned(
//                         bottom: 0,
//                         right: 0,
//                         //material button so as to make something good
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
//                   //showing email
//                   Text(widget.user.email,
//                       style: const TextStyle(color: Colors.black54, fontSize: 16)),
//
//                   SizedBox(height: mq.height * 0.05),
//
//                   //for showing uesr image
//                   TextFormField(
//                     initialValue: widget.user.name,
//                     //storing in API, if null it empty
//                     onSaved: (val) => APIss.me.name = val ?? '',
//                     //validation system
//                     validator: (val) =>
//                     val != null && val.isNotEmpty ? null : 'Required Field',
//
//                     //decorating
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
//                   //decorating
//                   TextFormField(
//                     initialValue: widget.user.about,
//                     onSaved: (val) => APIss.me.about = val ?? '',
//                     validator: (val) =>
//                     val != null && val.isNotEmpty ? null : 'Required Field',
//                     decoration: InputDecoration(
//                       //for icon
//                       prefixIcon: const Icon(Icons.info_outline, color: Colors.blue),
//                       border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//                       hintText: 'eg. Feeling Happy',
//                       label: const Text('About'),
//                     ),
//                   ),
//
//                   SizedBox(height: mq.height * 0.03),
//
//                   //for UPDATE Button - for editing the information
//                   ElevatedButton.icon(
//                     //providing styling
//                     style: ElevatedButton.styleFrom(
//                       shape: const StadiumBorder(),
//                       minimumSize: Size(mq.width * .5, mq.height * .06),
//                     ),
//                     onPressed: () {
//                       //API function
//                       if (_formKey.currentState!.validate()) {
//                         //saving the data by calling save()
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
//
//   //for showing up options to pick the image
//   void _showBottomSheet() {
//
//     Size mq = MediaQuery.of(context).size;
//
//     showModalBottomSheet(
//         context: context,
//         //pop-up box
//         shape: const RoundedRectangleBorder(
//             borderRadius: BorderRadius.only(
//                 topLeft: Radius.circular(20),
//                 topRight: Radius.circular(20)
//             )),
//
//         builder: (_) {
//           return ListView(
//             shrinkWrap: true,
//             padding:
//             EdgeInsets.only(top: mq.height * .03, bottom: mq.height * .05),
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
//                       style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.white,
//                           shape: const CircleBorder(),
//                           fixedSize: Size(mq.width * .3, mq.height * .15)),
//                           onPressed: () async {
//
//                               //image picker, used from google - pub.dev
//
//                                 final ImagePicker picker = ImagePicker();
//                               // Pick an image.
//                                 final XFile? image = await picker.pickImage(source: ImageSource.gallery);
//
//                               if(image != null){
//                                 //for updating
//                                 setState(() {
//                                   _image = image.path;
//                                 });
//                                 //for hiding bottom sheet
//                                 Navigator.pop(context);
//                         }
//                       },
//                       child: Image.asset('images/gallery.png')),
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
