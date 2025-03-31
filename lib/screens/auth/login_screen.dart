import 'dart:io';

import '../../apis/apiss.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:developer';

import '../../helper/dialogs.dart';
import '../home_screens.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late Size mq;

  bool _isAnimate = false;

  @override
  void initState() {
    super.initState();
    // Trigger the fade animation after 500ms delay
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _isAnimate = true;
      });
    });
  }

  //handles google login button click
  void _handleGoogleBtnClick() async {
    Dialogs.showPorgressBar(context); // Progress bar
    UserCredential? user = await _signInWithGoogle();
    Navigator.pop(context); // Hide progress bar

    if (user != null) {
      log('\nUser: ${user.user}');
      log('\nUserAdditionalInfo: ${user.additionalUserInfo}');

      if (await APIss.userExists()) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        await APIss.createUser().then((value) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        });
      }
    }
  }


  Future<UserCredential?> _signInWithGoogle() async {
    try{
      await InternetAddress.lookup('google.com');
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      // Obtain the auth details from the request
      final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      // Once signed in, return the UserCredential
      return await APIss.auth.signInWithCredential(credential);
    }
    catch(e){
      log('_signInWithGoogle: $e');
      Dialogs.showSnackbar(context, 'Something Went Wrong(Check Internet!)');
      return null;
    }
  }

//   sign-out function
//   _signOut() aysnc{
//     await FirebaseAuth.instance.signOut();
//     await GoogleSignIn().signOut();
//
// }



  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Welcome to CatchUp'),
      ),
      body: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(seconds: 1),
            top: mq.height * 0.15,
            right: _isAnimate ? mq.width * .25 : -mq.width * 0.5,
            left: mq.width * 0.25,
            child: Image.asset('images/icoon.png'),
          ),
          Positioned(
            bottom: mq.height * 0.15,
            height: mq.height * 0.06,
            width: mq.width * 0.9,
            left: mq.width * 0.05,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 219, 255, 178),
                shape: const StadiumBorder(),
                elevation: 1,
              ),
              onPressed: () {
                _handleGoogleBtnClick();
              },
              icon: Image.asset(
                'images/google.png',
                height: mq.height * 0.04,
              ),
              label: RichText(
                text: const TextSpan(
                  text: 'Sign In With ', // First part of text
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                    fontSize: 18,
                  ),
                  children: [
                    TextSpan(
                      text: 'Google', // Second part of text
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
