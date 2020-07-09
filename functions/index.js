const functions = require('firebase-functions');
const admin=require('firebase-admin');
admin.initializeApp();

// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//
// exports.helloWorld = functions.https.onRequest((request, response) => {
//  response.send("Hello from Firebase!");
// });
exports.onCreateFollower= functions.firestore
         .document("/followers/{userId}/userFollowers/{followerId}")
         .onCreate(async(snapshot,context)=>{
         console.log("FollowerCreated",snapshot.id)
         const userId= context.params.userId;
         const followerId=context.params.followerId;


         //get followed user posts
         const followedUserPostsRef=admin
             .firestore()
             .collection('posts')
             .doc(userId)
             .collection('userPosts');

             //Get following users timeline
             const timelinePostsRef= admin
               .firestore()
               .collection('timeline')
               .doc(followerId)
               .collection('timelinePosts');

             //get followed user posts
             const querySnapshot=await followedUserPostsRef.get();
              //add each user post to following user's timeline
             querySnapshot.forEach(doc => {
             if(doc.exists){
             const postId=doc.id;
             const postData=doc.data();
             timelinePostsRef.doc(postId).set(postData);
            }
             })
         });

exports.onDeleteFollower=functions.firestore
  .document("/followers/{userId}/userFollowers/{followerId}")
  .onDelete(async(snapshot,context)=>{
  console.log("Follower Deleted",snapshot.id);

   const userId= context.params.userId;
   const followerId=context.params.followerId;

  const timelinePostsRef= admin
               .firestore()
               .collection('timeline')
               .doc(followerId)
               .collection('timelinePosts')
               .where('ownerId','==',userId);

               const querySnapshot=await timelinePostsRef.get();
               querySnapshot.forEach(doc=>{
               if(doc.exists){
               doc.ref.delete();
               }});

  });


//when a post is created we want to update the timelie of each follower of post owner
 exports.onCreatePost = functions.firestore
 .document('/posts/{userId}/userPosts/{postId}')
 .onCreate(async(snapshot,context)=> {
 const postCreated=snapshot.data();
 const userId=context.params.userId;
 const postId=context.params.postId;

 //get all teh followers of the user who made thwe post
 const userFollowersRef=admin.firestore()
 .collection('followers')
 .doc(userId)
 .collection('userFollowers');

 const querySnapshot=await userFollowersRef.get();

 //add new post to each followers timeline
 querySnapshot.forEach(doc=>{
 const followerId=doc.id;


 admin
 .firestore()
 .collection('timeline')
 .doc(followerId)
 .collection('timelinePosts')
 .doc(postId)
 .set(postCreated);

 });
 });


 exports.onUpdatePost=functions.firestore
 .document('/posts/{userId}/userPosts/{postId}')
 .onUpdate(async(change,context)=>{
 const postUpdated=change.after.data();
 const userId=context.params.userId;
 const postId=context.params.postId;

  const userFollowersRef=admin.firestore()
  .collection('followers')
  .doc(userId)
  .collection('userFollowers');

 const querySnapshot=await userFollowersRef.get();
  //update post to each followers timeline
  querySnapshot.forEach(doc=>{
  const followerId=doc.id;


  admin.firestore()
  .collection('timeline')
  .doc(followerId)
  .collection('timelinePosts')
  .doc(postId)
   .get().then(doc => {
   if(doc.exists){
   doc.ref.update(postUpdated);
   }
   });

  });
 });


  exports.onDeletePost=functions.firestore
  .document('/posts/{userId}/userPosts/{postId}')
  .onDelete(async(snapshot,context)=>{
 const userId=context.params.userId;
 const postId=context.params.postId;

   const userFollowersRef=admin.firestore()
   .collection('followers')
   .doc(userId)
   .collection('userFollowers');

  const querySnapshot=await userFollowersRef.get();
   //Delete post to each followers timeline
   querySnapshot.forEach(doc=>{
   const followerId=doc.id;


   admin.firestore()
   .collection('timeline')
   .doc(followerId)
   .collection('timelinePosts')
   .doc(postId)
    .get().then(doc => {
    if(doc.exists){
    doc.ref.delete();
    }
    });

   });

  });
exports.onCreateActivityFeedItem=functions.firestore
.document('/feed/{userId}/feedItems/{activityFeedItem}')
.onCreate(async(snapshot,context)=>{
console.log('Activity Feed Item Created',snapshot.data());


const userId=context.params.userId;
const usersRef=admin.firestore().doc('users/${userId}');
const doc= await usersRef.get();
// Once we have users check if we have a notification token
const androidNotificationToken= doc.data().androidNotificationToken;
const createdActivityFeedItem=snapshot.data();
if(androidNotificationToken){
//send notification
sendNotification(androidNotificationToken,createdActivityFeedItem);
}
else{
console.log("no notification for user,cannot send notification");
}

function sendNotification(androidNotificationToken,activityFeedItem){
let body;
switch(activityFeedItem.type){
case "comment":
body='${activityFeedItem.username} replied: ${activityFeedItem.commentData}';
break;
case "like":
body='${activityFeedItem.username} liked your post';
break;
case "follow":
body='${activityFeedItem.username} started following you';
break;

default:
break;
}
//..create message for push notification
const message={
notification:{body},
token:androidNotificationToken,
data:{recipient:userId}
};
//send the message with adin.messagig
admin
.messaging()
.send(message)
.then(response=>{
//response is a messaging strin
console.log("Successfully sent message",response);
})
.catch(error=>{
console.log("ERROR sending message",error);
})
}
});
