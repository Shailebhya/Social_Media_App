import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter14app/models/user.dart';
import 'package:flutter14app/pages/activity_feed.dart';
import 'package:flutter14app/pages/create_account.dart';
import 'package:flutter14app/pages/profile.dart';
import 'package:flutter14app/pages/search.dart';
import 'package:flutter14app/pages/timeline.dart';
import 'package:flutter14app/pages/upload.dart';
import 'package:google_sign_in/google_sign_in.dart';
//import 'package:cloud_firestore/cloud_firestore.dart';


final GoogleSignIn googleSignIn =GoogleSignIn();
final StorageReference storageRef= FirebaseStorage.instance.ref();
final usersRef = Firestore.instance.collection('users');
final postsRef = Firestore.instance.collection('posts');
final commentsRef=Firestore.instance.collection('comments');
final followersRef= Firestore.instance.collection('followers');
final followingRef= Firestore.instance.collection('following');
final timelineRef= Firestore.instance.collection('timeline');
final activityFeedRef= Firestore.instance.collection('feed');
final timestamp = DateTime.now();
User currentUser;
class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _scaffoldKey=GlobalKey<ScaffoldState>();
  FirebaseMessaging _firebaseMessaging=FirebaseMessaging();
  bool isAuth = false;
  PageController pageController;
  int pageIndex =0;

  @override
  void initState(){
    super.initState();
    pageController = PageController();

    googleSignIn.onCurrentUserChanged.listen((account) {
     handleSignIn(account);
    },
      onError: (err){
      print('Error signing in : $err');
      }
    );//Reauthenticate when app is opened!!
    googleSignIn.signInSilently(suppressErrors: false)
    .then((account){
      handleSignIn(account);

    }).catchError((err){
      print('Error signing in : $err');
    });
  }
  handleSignIn(GoogleSignInAccount account)async{
    if(account!= null) {
      //print('User Signed in!:$account');
      await createUserInFirestore();
      setState(() {
        isAuth =true;
      });
      configurePushNotifications();
    }
    else{
      setState(() {
        isAuth = false;
      },
      );
    }
  }
  configurePushNotifications(){
    final GoogleSignInAccount user = googleSignIn.currentUser;
    if(Platform.isIOS)getiOSPermission();

    _firebaseMessaging.getToken().then((token){
      print("firebase messaging token:$token\n");
      usersRef
      .document(user.id)
      .updateData({'androidNotificationToken':token});
    });
    _firebaseMessaging.configure(
//      onLaunch: (Map<String,dynamic>message)async{},
//      onResume: (Map<String,dynamic>message)async{},
      onMessage: (Map<String,dynamic>message)async{
        print("on message :$message\n");
        final String recipientId = message['data']['recipient'];
        final String body = message['notification']['body'];
        if(recipientId==user.id){
          print("Notification Shown!");
          SnackBar snackbar=SnackBar(content:Text(body,overflow:TextOverflow.ellipsis));
          _scaffoldKey.currentState.showSnackBar(snackbar);
        }
        print("Notifications not showm");
      }
      );
  }
  getiOSPermission(){
    _firebaseMessaging.requestNotificationPermissions(IosNotificationSettings(alert: true,badge: true,sound: true));
_firebaseMessaging.onIosSettingsRegistered.listen((settings) {
  print("Settings Registered:$settings");
});
  }
createUserInFirestore()async {
  //check if user exists in users collection in database according to their id
  final GoogleSignInAccount user = googleSignIn.currentUser;
   DocumentSnapshot doc =await usersRef.document(user.id).get();

    if(!doc.exists){
      // if the ussr doesnt exist then we want to tske them to create account page

    final username =await Navigator.push(context, MaterialPageRoute(builder: (context)=> CreateAccount()));

  //get username from create account , use it to make new user doc.
    //in user collection
  usersRef.document(user.id).setData({
    "id": user.id,
    "username": username,
    "photoUrl":user.photoUrl,
    "email": user.email,
    'displayName': user.displayName,
    "bio":"",
    "timestamp":timestamp
  });
   await followersRef
    .document(user.id)
    .collection('userFollwers')
    .document(user.id)
    .setData({});
    doc =await usersRef.document(user.id).get();
  }
    currentUser = User.fromDocument(doc);
    print(currentUser);
    print(currentUser.username);

}
  @override
  void dispose(){
    pageController.dispose();
    super.dispose();
  }

  login(){
    googleSignIn.signIn();
  }

  logout(){
    googleSignIn.signOut();
  }
  onPageChanged(int pageIndex){
    setState(() {
      this.pageIndex = pageIndex;
    });
  }
    onTap(int pageIndex){
    pageController.animateToPage(
      pageIndex,
      duration: Duration(milliseconds: 250),
      curve: Curves.easeInOut
    );
    
    }
  Widget buildAuthScreen() {
    return Scaffold(
      key: _scaffoldKey,
      body: PageView(
        children: <Widget>[
          Timeline(currentUser:currentUser),
          ActivityFeed(),
          Upload(currentUser:currentUser),
          Search(),
          Profile(profileId: currentUser?.id),
        ],
        controller: pageController,
        onPageChanged: onPageChanged,
        physics: NeverScrollableScrollPhysics(),

      ),
      bottomNavigationBar: CupertinoTabBar(
        currentIndex: pageIndex,
        onTap: onTap,
        activeColor: Theme.of(context).primaryColor,
        items: [
          BottomNavigationBarItem(icon: Icon(
            Icons.whatshot
          ),
          ),
          BottomNavigationBarItem(icon: Icon(
              Icons.notifications_active
          ),
          ),
          BottomNavigationBarItem(icon: Icon(
              Icons.photo_camera,
            size: 35,
          ),
          ),
          BottomNavigationBarItem(icon: Icon(
              Icons.search
          ),
          ),
          BottomNavigationBarItem(icon: Icon(
              Icons.account_circle
          ),
          ),
        ],
      ),
    );
  }

  Scaffold buildUnAuthScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
         gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Theme.of(context).accentColor,
              Theme.of(context).primaryColor,


            ]
          )
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text("FLutterShare", style: TextStyle(
              fontFamily: 'Signatra',
              fontSize: 90,
              color: Colors.white,
            ),
            ),
            GestureDetector(
              onTap: () => login(),
              child: Container(
                width: 260,
                  height: 60,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/images/google_signin_button.png"),
                    fit: BoxFit.cover,
                  )
                ),
              ),
            )
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return isAuth ? buildAuthScreen() : buildUnAuthScreen();
  }
}

