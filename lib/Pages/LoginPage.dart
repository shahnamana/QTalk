import 'dart:async';
import 'dart:ffi';


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutt'
    'er/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:telegramchatapp/Pages/HomePage.dart';
import 'package:telegramchatapp/Widgets/ProgressWidget.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';


class LoginScreen extends StatefulWidget {
  LoginScreen({Key key}):super(key:key);
  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final GoogleSignIn googleSignIn=GoogleSignIn();
  final FirebaseAuth firebaseAuth=FirebaseAuth.instance;
  SharedPreferences preferences;
  bool isLogged=false;
  bool isLoading=false;
  FirebaseUser currentUser;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    isSignedIn();
  }
  void isSignedIn() async{
    this.setState(() { 
      isLogged=true;
    });
    preferences=await SharedPreferences.getInstance();
    isLogged=await googleSignIn.isSignedIn();
    if(isLogged){
      Navigator.push(context, MaterialPageRoute(builder: (context)=>HomeScreen(currentUserId:preferences.getString("id"))));
    }
    this.setState(() {
      isLoading=false;
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Colors.lightGreenAccent,Colors.lightBlueAccent]
          )
        ),
        alignment: Alignment.center,
        child:Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              "Boycott China",
              style: TextStyle(fontSize: 82.0,color:Colors.red.withOpacity(0.8),fontFamily: "Signatra"),
            ),
            GestureDetector(
              onTap: controlSignIn,
              child: Center(
                child: Column(
                  children: <Widget>[
                    Container(
                      width: 270.0,
                      height: 65.0,
                      decoration:BoxDecoration(
                        image:DecorationImage(
                          image: AssetImage("assets/images/google_signin_button.png"),
                          fit:BoxFit.cover
                        )
                      )
                    ),
                    Padding(
                      padding: EdgeInsets.all(1.0),
                      child: isLoading ? circularProgress():Container(),
                    )
                  ],
                ),
              )
            )
          ],
        )
      ),
    );
  }

  Future<Null> controlSignIn() async
  {
    preferences =await SharedPreferences.getInstance();
    this.setState(() {
      isLoading=true;
    });
    GoogleSignInAccount googleUser=await googleSignIn.signIn();
    GoogleSignInAuthentication googleSignInAuthentication=await googleUser.authentication;
    final AuthCredential credential=GoogleAuthProvider.getCredential(idToken: googleSignInAuthentication.idToken, accessToken: googleSignInAuthentication.accessToken);
    FirebaseUser firebaseUser=(await firebaseAuth.signInWithCredential(credential)).user;
    if(firebaseUser!=null){
      final QuerySnapshot resultQuery=await Firestore.instance.collection("users").where("id",isEqualTo: firebaseUser.uid).getDocuments();
      final List<DocumentSnapshot> documentSnapshot=resultQuery.documents;
      if(documentSnapshot.length==0){
        Firestore.instance.collection("users").document(firebaseUser.uid).setData({
          "nickname":firebaseUser.displayName,
          "photoUrl":firebaseUser.photoUrl,
          "id":firebaseUser.uid,
          "aboutMe":"I am using my app",
          "createdAt":DateTime.now().millisecondsSinceEpoch.toString(),
          "chattingWith":null,
        });

        currentUser=firebaseUser;
        await preferences.setString("id",currentUser.uid);
        await preferences.setString("nickname",currentUser.displayName);
        await preferences.setString("photoUrl",currentUser.photoUrl);
      }
      else{
        currentUser=firebaseUser;
        await preferences.setString("id",documentSnapshot[0]["id"]);
        await preferences.setString("nickname",documentSnapshot[0]["nickname"]);
        await preferences.setString("photoUrl",documentSnapshot[0]["photoUrl"]);
        await preferences.setString("aboutMe",documentSnapshot[0]["aboutMe"]);
      }
      Fluttertoast.showToast(msg: " Congratulation, Sign In Successful");
      this.setState(() {
        isLoading=false;
      });
      Navigator.push(context,MaterialPageRoute(builder: (context)=>HomeScreen(currentUserId:firebaseUser.uid)));
    }
    else{
      Fluttertoast.showToast(msg: "Try Again,Sign in Failed");
      this.setState(() {
        isLoading=false;
      });
    }
  }
}
