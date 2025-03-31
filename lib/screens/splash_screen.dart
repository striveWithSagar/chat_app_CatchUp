

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dart:io';import 'dart:developer';


import '../apis/apiss.dart';
import 'auth/login_screen.dart';
import 'home_screens.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  //late Size mq;
  //this method is used to instantiate the animaiton
  @override
  void initState(){
    super.initState();

    Future.delayed(const Duration(seconds: 2), () {

      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(systemNavigationBarColor: Colors.white, statusBarColor: Colors.white));

      if(APIss.auth.currentUser != null){
        log('\nUser: ${APIss.auth.currentUser}');
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      }
      else{
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    //initializing media query (for getting device screen size)
    Size mq = MediaQuery.of(context).size;

    return Scaffold(
      //app bar
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Welcome to VibeChat'), //actino button
      ),
      body: Stack(children: [
        //App Logo
        Positioned(
            top: mq.height * .15,
            width: mq.width * .5,
            right: mq.width * .25,
            child: Image.asset('images/VibeChat.png')),
        //Google login Button
        Positioned(
            bottom: mq.height * .15,
            width: mq.width * .9,
            right: mq.width * .05,
            height: mq.height * .07,
            //child: Image.asset('images/splash_Screen.png')),
          child: Text(
            'Welcome to VibeChat ❤️',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 30.0,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cursive', // Ensure you have this font added in pubspec.yaml
              shadows: [
                Shadow(
                  blurRadius: 10.0,
                  color: Colors.black.withOpacity(0.5),
                  offset: const Offset(3.0, 3.0),
                ),
              ],
            ),
          ),
        ),
      ],
      ),
    );
  }
}