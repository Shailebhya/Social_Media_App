import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter14app/models/user.dart';
import 'package:flutter14app/pages/search.dart';
import 'package:flutter14app/widgets/header.dart';
import 'package:flutter14app/widgets/progress.dart';
import 'package:flutter14app/widgets/post.dart';
import 'package:flutter14app/pages/home.dart';

final usersRef = Firestore.instance.collection('users');

class Timeline extends StatefulWidget {
  final User currentUser;
  Timeline({this.currentUser});

  @override
  _TimelineState createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> {
  List<Post> posts;
  List<String> followingList=[];
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getTimeline();
    getFollowing();
  }
  getTimeline()async{
   QuerySnapshot snapshot= await timelineRef
        .document(widget.currentUser.id)
        .collection('timelinePosts')
        .orderBy('timestamp',descending: true)
        .getDocuments();
  List<Post> posts=snapshot.documents.map((doc)=> Post.fromDocument(doc)).toList();

  setState(() {
    this.posts=posts;
  });

  }
  getFollowing()async{
    QuerySnapshot snapshot =await followingRef
        .document(currentUser.id)
        .collection('userFollowing')
        .getDocuments();
    setState(() {
      followingList=snapshot.documents.map((doc)=> doc.documentID)
          .toList();
    });

  }
  buildUsersToFollow(){
    return StreamBuilder(
      stream: usersRef.orderBy('timestamp',descending:true).limit(30).snapshots(),
      builder: (context,snapshot){
        List<UserResult> userResults =[];
        snapshot.data.documents.forEach((doc){
          User user= User.fromDocument(doc);
          final bool isAuthUser=currentUser.id ==user.id;
          final bool isFollowingUser =followingList.contains(user.id);
        if(!snapshot.hasData){
          return circularProgress();
        }

          if(isAuthUser){
            return null;
          }else if(isFollowingUser){
            return null;
          }else{
            UserResult userResult =UserResult(user);
            userResults.add(userResult);
          }
          return Container(
            color: Theme.of(context).accentColor.withOpacity(0.2),
            child: Column(
              children: <Widget>[
                Container(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        Icons.person_add,
                        color: Theme.of(context).primaryColor,
                        size: 30,
                      ),
                      SizedBox(width: 8,),
                      Text("Users to follow",
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                         fontSize: 30
                      ),)
                    ],
                  ),
                ),
                Column(
                  children: userResults,
                )
              ],
            ),
          );
        });
      },
    );
  }
//  List<dynamic> users = [];
//
//  @override
//  void initState() {
////    getUsers();
////    createUser();
//    //    getUsersById();
////    updateUser();
//  updateUser()   ;
//  super.initState();
//  }
//  deleteUser() async{
//
//    final DocumentSnapshot doc= await usersRef.document("NbuCZ91tvfrdCKlvTBVG").get();
//    if(doc.exists){
//      doc.reference.delete();
//    }
//  }
//updateUser()async{
//  final doc =await usersRef.document("NbuCZ91tvfrdCKlvTBVG").get();
//  if (doc.exists){
//    doc.reference.updateData({
//      'username': 'Johny',
//      'postsCount': 3,
//      'isAdmin': false,
//    });
//  }
//
//}
//  createUser() {
//    usersRef.document("asf").setData({
//      'username': 'Jeff',
//      'postsCount': 0,
//      'isAdmin': false,
//    });
//  }
//
////  getUsersById() async{
////    final String id = 'z1CwWN4z2puAzXJs2cNA';
////      final DocumentSnapshot doc =await usersRef.document(id).get();
////    print(doc.data);
////        print(doc.documentID);
////        print(doc.exists);
////  }
//
//  getUsers() async {
//    final QuerySnapshot snapshot = await usersRef.getDocuments();
//
//    setState(() {
//      users = snapshot.documents;
//    });
//
////      .where('isAdmin',isEqualTo:true)
////      .where('postsCount',isLessThan: 3).getDocuments();
////    .orderBy('postsCount',descending: false).getDocuments();
////    .limit(1).getDocuments();
////    usersRef.getDocuments().then((QuerySnapshot snapshot) {
////      snapshot.documents.forEach((DocumentSnapshot doc) {
////        print(doc.data);
////        print(doc.documentID);
////        print(doc.exists);
////      });
//  }
buildTimeline(){
   if(posts == null){
     return circularProgress();
   }
   else if(posts.isEmpty){
     return buildUsersToFollow();
   }
   else{ return ListView(children: posts);}

}
  @override
  Widget build(context) {
//    return Scaffold(
//        appBar: header(context, isAppTitle: true),
//        body: StreamBuilder<QuerySnapshot>(
//          stream: usersRef.snapshots(),
//          builder: (context, snapshot) {
//            if (!snapshot.hasData) {
//              return circularProgress();
//            } else {
//              final List<Text> children = snapshot.data.documents
//                  .map((doc) => Text(doc['username'] ?? ''))
//                  .toList();
//              return Container(
//                child: ListView(
//                  children: children,
//                ),
//              );
//            }
//          },
//        ));
//  }
  return Scaffold(
    appBar: header(context,isAppTitle: true),
    body:RefreshIndicator(
      onRefresh: ()=> getTimeline(),
      child: buildTimeline()
    )
  );
  }
}