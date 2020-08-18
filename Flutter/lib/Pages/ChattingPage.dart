import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:image_downloader/image_downloader.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:telegramchatapp/Widgets/FullImageWidget.dart';
import 'package:telegramchatapp/Widgets/ProgressWidget.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tflite/tflite.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_downloader/flutter_downloader.dart';


class Chat extends StatelessWidget {
  final String receiverId;
  final String receiverAvatar;
  final String receiverName;

  Chat({
    Key key,
    @required this.receiverId,
    @required this.receiverAvatar,
    @required this.receiverName,
});
  @override
  Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      actions: <Widget>[
        Padding(
          padding: EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.black,
            backgroundImage: CachedNetworkImageProvider(receiverAvatar),
          ),
        )
      ],
      iconTheme: IconThemeData(
        color: Colors.white,
      ),
      backgroundColor: Colors.lightBlueAccent,
      title: Text(
        receiverName,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold
        ),
      ),
      centerTitle: true,
    ),
    body: ChatScreen(receiverId: receiverId, receiverAvatar: receiverAvatar),
  );
  }
}

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverAvatar;
  ChatScreen({
   Key key,
   @required this.receiverId,
    @required this.receiverAvatar
}) : super(key: key);
  @override
  State createState() => ChatScreenState(receiverId: receiverId, receiverAvatar: receiverAvatar);
}



class ChatScreenState extends State<ChatScreen> {
  final String receiverId;
  final String receiverAvatar;
  ChatScreenState({
    Key key,
    @required this.receiverId,
    @required this.receiverAvatar
  });

  final TextEditingController textEditingController = TextEditingController();
  final ScrollController listScrollController = ScrollController();
  final FocusNode focusNode = FocusNode();
  bool isDisplaySticker;
  bool isLoading;
  File imageFile;
  String imageUrl;
  File image;
  
  String chatId;
  SharedPreferences preferences;
  String id;

  var listMessage;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    
    focusNode.addListener(onFocusChange);
    loadFlutterDownloader();

    isDisplaySticker = false;
    isLoading = false;

    chatId = "";

    readLocal();

    loadModel().then((value) {
      setState(() {
        isLoading = false;
      });
    });
  }

  loadFlutterDownloader() async{
    WidgetsFlutterBinding.ensureInitialized();
    await FlutterDownloader.initialize(
        debug: true // optional: set false to disable printing logs to console
    );
  }


  loadModel() async {
    await Tflite.loadModel(
      model: "assets/model.tflite",
      labels: "assets/labels.txt",
    );
  }

  readLocal() async{
    preferences = await SharedPreferences.getInstance();
    id = preferences.getString("id") ?? "";

    if(id.hashCode <= receiverId.hashCode){
      chatId = '$id-$receiverId';
    }else{
      chatId = '$receiverId-$id';
    }

    Firestore.instance.collection("users").document(id).updateData({'chattingWith': receiverId});

    setState(() {

    });

  }

  onFocusChange(){
    if(focusNode.hasFocus){
      //hide stickers when keyboard appears
      setState(() {
        isDisplaySticker = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Stack(
        children: <Widget>[
          Column(
            children: <Widget>[
              //create lst of messages
              createListMessages(),

              //Show Stickers
              (isDisplaySticker ? createSticker(): Container()),

              //Input Controllers
              createInput(),
            ],
          ),

          createLoading(),
        ],
      ),
      onWillPop: onBackPress,
    );
  }

  createLoading(){
    return Positioned(
      child: isLoading ? circularProgress(): Container(),
    ) ;
  }

  Future<bool> onBackPress(){
  if (isDisplaySticker){
    setState(() {
      isDisplaySticker = false;
    });
  }
  else{
    Navigator.pop(context);
  }

  return Future.value(false);
  }

  createSticker(){
    return Container(
      child: Column(
        children: <Widget>[

          Row(
            children: <Widget>[
              FlatButton(
              onPressed: ()=> onSendMessage("mimi1", 2),
                child: Image.asset(
                  "images/mimi1.gif",
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),

              FlatButton(
                onPressed: ()=> onSendMessage("mimi2", 2),
                child: Image.asset(
                  "images/mimi2.gif",
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),

              FlatButton(
                onPressed: ()=> onSendMessage("mimi3", 2),
                child: Image.asset(
                  "images/mimi3.gif",
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              )
            ],
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          ),

          Row(
            children: <Widget>[
              FlatButton(
              onPressed: ()=> onSendMessage("mimi4", 2),
                child: Image.asset(
                  "images/mimi4.gif",
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),

              FlatButton(
                onPressed: ()=> onSendMessage("mimi5", 2),
                child: Image.asset(
                  "images/mimi5.gif",
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),

              FlatButton(
                onPressed: ()=> onSendMessage("mimi6", 2),
                child: Image.asset(
                  "images/mimi6.gif",
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              )
            ],
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          ),

          Row(
            children: <Widget>[
              FlatButton(
              onPressed: ()=> onSendMessage("mimi7", 2),
                child: Image.asset(
                  "images/mimi7.gif",
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),

              FlatButton(
                onPressed: ()=> onSendMessage("mimi8", 2),
                child: Image.asset(
                  "images/mimi8.gif",
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),

              FlatButton(
                onPressed: ()=> onSendMessage("mimi9", 2),
                child: Image.asset(
                  "images/mimi9.gif",
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              )
            ],
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          ),

        ],
      ),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey, width: 0.5)),
        color: Colors.white
      ),
      padding: EdgeInsets.all(5.0),
      height: 180.0,
    );
  }

  void getSticker()
  {
    focusNode.unfocus();
    setState(() {
      isDisplaySticker = !isDisplaySticker;
    });
}
  createListMessages(){
    return Flexible(
      child: chatId == ""
      ? Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.lightBlueAccent),
          ),
        )
        : StreamBuilder(
          stream: Firestore.instance.collection("messages")
              .document(chatId)
              .collection(chatId).orderBy("timeStamp", descending: true).limit(20).snapshots(),

        builder: (context, snapshot){
            if(!snapshot.hasData){
//              print(snapshot.data.documents);
              return Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.lightBlueAccent),
                ),
              );
            }else{
              listMessage = snapshot.data.documents;
              print(listMessage);
              return ListView.builder(
                padding: EdgeInsets.all(10.0),
                itemBuilder: (context, index)=> createItem(index, snapshot.data.documents[index]),
                itemCount: snapshot.data.documents.length,
                reverse: true,
                controller: listScrollController,
              );
            }
        },
      ),

    );
  }


  bool isLastMsgRight(int index){
    if((index>0 && listMessage!= null && listMessage[index-1]["idFrom"] != id) || index==0){
      return true;
    }else{
      return false;
    }
  }

  bool isLastMsgLeft(int index){
    if((index>0 && listMessage!= null && listMessage[index-1]["idFrom"] == id) || index==0){
      return true;
    }else{
      return false;
    }
  }

  getData(String queryInput) async {
    var data;
    var _outputs;
    var tempUrl = 'http://namanshah008.pythonanywhere.com/predict?news=';
    List q = queryInput.split(' ');
    String finalUrl = tempUrl + q.join("+");
    var response = await get(
      Uri.parse(finalUrl),
    );
    data = json.decode(response.body);
    _outputs = data['result'].toString();
    print(_outputs);
    Fluttertoast.showToast(msg: _outputs);
    fakeNewsAlert(_outputs);
  }

  Future<void> fakeNewsAlert(String result) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Fake News Detection'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Container(
                  width: 120.0,
                  height: 1.0,
                  color: Colors.grey,
                  margin: EdgeInsets.only(bottom: 10.0),
                ),
                Text(
                    result,
                  style: TextStyle(
                    color: (result.contains("True"))?Colors.green:(result.contains("False"))?Colors.orange:Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 20.0,
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

    Future<void> downloadImage(String imageUrl) async {
    final externalDir = await getExternalStorageDirectory();
    final id = await FlutterDownloader.enqueue(
        url: imageUrl,
        savedDir: externalDir.path,
        fileName: "download.jpg",
        showNotification: true,
        openFileFromNotification: true,
    );

    String finalPath = externalDir.path + "/download.jpg";
    image = File(finalPath);
    sleep(Duration(milliseconds: 3000));
    extractText(image);
  }


  Future extractText(File imageFile) async {
//    File imageFile = await getImageFileFromAssets('assets/images/TEST.jpg');
//    sleep(Duration(milliseconds: 3000));
    FirebaseVisionImage ourImage = FirebaseVisionImage.fromFile(imageFile);
    TextRecognizer recognizeText = FirebaseVision.instance.textRecognizer();
    VisionText readText = await recognizeText.processImage(ourImage);
    List sentence = [];

    for (TextBlock block in readText.blocks) {
      for (TextLine line in block.lines) {
        for (TextElement word in line.elements) {
          sentence.add(word.text);
        }
      }
    }
    String finalSentence = sentence.join(" ");
    showDialog(
        context: context,
        builder: (BuildContext context){
          return AlertDialog(
            title: Text('Extracted Text'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Container(
                    width: 120.0,
                    height: 1.0,
                    color: Colors.grey,
                    margin: EdgeInsets.only(bottom: 10.0),
                  ),
                  SelectableText(
                    finalSentence,
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 15.0,
                    ),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              FlatButton(
                child: Text('Close'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        }
    );
  }

  messageOptions(int index, DocumentSnapshot document) {
    showDialog(
        context: context,
        builder: (BuildContext context){
          return SimpleDialog(
            children: <Widget>[
              SimpleDialogOption(
                child: Text(
                  "Unsend Message",
                  style: TextStyle(
                    fontSize: 17.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                onPressed: () async {
                  await Firestore.instance.runTransaction((Transaction myTransaction) async {
                    await myTransaction.delete(document.reference);
                  });

                  Navigator.pop(context);
                  setState(() {

                  });
                },
              ),
              document["type"]==0 ? SimpleDialogOption(
                child: Text(
                    "Check if fake",
                  style: TextStyle(
                    fontSize: 17.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: (){
                  getData(document["content"]);

                },
              ): Container(),
              document["type"]==1 ? SimpleDialogOption(
                child: Text(
                  "Extract text from image",
                  style: TextStyle(
                    fontSize: 17.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: ()async{
                  final status = await Permission.storage.request();

                  if(status.isGranted){
                    downloadImage(document["content"]);
                  }else{
                    Fluttertoast.showToast(msg: "Permission denied");
                  }
          }
              ):Container()
//              document["type"]==1 ? SimpleDialogOption(
//                child: Text(
//                  "Download image",
//                  style: TextStyle(
//                    fontSize: 17.0,
//                    fontWeight: FontWeight.bold,
//                  ),
//                ),
//                onPressed:() async{
//                  var imageId;
//                  StorageReference storageReference=FirebaseStorage.instance.ref().child("chat Images").child(document["fileName"]);
//                  storageReference.getDownloadURL().then((downloadUrl) {
//
//                  }
//
//                  );
//                  Navigator.pop(context);
//                  },
//              ): Container()
            ],
          );
        }
    );
  }

  Widget createItem(int index, DocumentSnapshot document) {
    //These are user m
    if (document["idFrom"] == id){
      return Row(
        children: <Widget>[
          document["type"] == 0
              //Text messages
              ? FlatButton(
            child: Container(
              child: Text(
                document["content"],
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
              padding: EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 10.0),
              width: 200.0,
              decoration: BoxDecoration(color: Colors.lightBlueAccent, borderRadius: BorderRadius.circular(8.0)),
              margin: EdgeInsets.only(bottom: isLastMsgRight(index) ? 20.0 : 10.0, right: 10.0),
            ),
            onLongPress: (){
              messageOptions(index, document);
            },
          )

              : document["type"] == 1
              //Gallery Images
              ? Container(
                child: FlatButton(
                  child: Material(
                    child: CachedNetworkImage(
                      placeholder: (context, url)=>Container(
                        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.lightBlueAccent),),
                        width: 200.0,
                        height: 200.0,
                        padding: EdgeInsets.all(70.0),
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.all(Radius.circular(8.0)),
                        ),
                      ),
                      errorWidget: (context, url, error)=> Material(
                        child: Image.asset("images/img_not_available.jpeg", width: 200.0,height: 200.0, fit: BoxFit.cover,),
                        borderRadius: BorderRadius.all(Radius.circular(8.0)),
                        clipBehavior: Clip.hardEdge,
                      ),
                      imageUrl: document["content"],
                      width: 200.0,
                      height: 200.0,
                      fit: BoxFit.cover,
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(8.0)),
                    clipBehavior: Clip.hardEdge,
                  ),
                  onPressed: ()
                  {
                    Navigator.push(context, MaterialPageRoute(
                        builder: (context) => FullPhoto(url: document["content"])
                    ));
                  },
                  onLongPress: (){
                    messageOptions(index, document);
                  },
                ),
            margin: EdgeInsets.only(bottom: isLastMsgRight(index) ? 20.0 : 10.0, right: 10.0),
          )
              //Emojis and GIFs
              :FlatButton(
            child: Container(
              child: Image.asset(
                "images/${document["content"]}.gif",
                width: 100.0,
                height: 100.0,
                fit: BoxFit.cover,
              ),
              margin: EdgeInsets.only(bottom: isLastMsgRight(index) ? 20.0 : 10.0, right: 10.0),
            ),
            onLongPress: (){
              messageOptions(index, document);
            },
          )

        ],
        mainAxisAlignment: MainAxisAlignment.end,
      );
    }else{
      return Container(
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                isLastMsgLeft(index)
                    ? Material(
                  //Display receiver profile image
                  child: CachedNetworkImage(
                    placeholder: (context, url)=>Container(
                      child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.lightBlueAccent),),
                      width: 35.0,
                      height: 35.0,
                      padding: EdgeInsets.all(10.0),
                    ),
                    imageUrl: receiverAvatar,
                    width: 35.0,
                    height: 35.0,
                    fit: BoxFit.cover,
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(18.0)),
                  clipBehavior: Clip.hardEdge,
                )
                    : Container(width: 35.0,),

                //display Messages
                document["type"] == 0
                //Text messages
                    ? FlatButton(
                  child: Container(
                    child: Text(
                      document["content"],
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.w400),
                    ),
                    padding: EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 10.0),
                    width: 200.0,
                    decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8.0)),
                    margin: EdgeInsets.only(left: 10.0),
                  ),
                  onLongPress: (){
                    messageOptions(index, document);
                  },
                )

                    : document["type"] == 1
                //Gallery Images
                    ? Container(
                  child: FlatButton(
                    child: Material(
                      child: CachedNetworkImage(
                        placeholder: (context, url)=>Container(
                          child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.lightBlueAccent),),
                          width: 200.0,
                          height: 200.0,
                          padding: EdgeInsets.all(70.0),
                          decoration: BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.all(Radius.circular(8.0)),
                          ),
                        ),
                        errorWidget: (context, url, error)=> Material(
                          child: Image.asset("images/img_not_available.jpeg", width: 200.0,height: 200.0, fit: BoxFit.cover,),
                          borderRadius: BorderRadius.all(Radius.circular(8.0)),
                          clipBehavior: Clip.hardEdge,
                        ),
                        imageUrl: document["content"],
                        width: 200.0,
                        height: 200.0,
                        fit: BoxFit.cover,
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(8.0)),
                      clipBehavior: Clip.hardEdge,
                    ),
                    onPressed: ()
                    {
                      Navigator.push(context, MaterialPageRoute(
                          builder: (context) => FullPhoto(url: document["content"])
                      ));
                    },
                    onLongPress: (){
                      messageOptions(index, document);
                    },
                  ),
                  margin: EdgeInsets.only(left: 10.0),
                )
                //Emojis and GIFs
                    : FlatButton(
                  child: Container(
                    child: Image.asset(
                      "images/${document["content"]}.gif",
                      width: 100.0,
                      height: 100.0,
                      fit: BoxFit.cover,
                    ),
                    margin: EdgeInsets.only(bottom: isLastMsgRight(index) ? 20.0 : 10.0, right: 10.0),
                  ),
                  onLongPress: (){
                    messageOptions(index, document);
                  },
                )
              ],
            ),

            //Last Message Time
            isLastMsgLeft(index)
                ? Container(
              child: Text(
                DateFormat("dd MMMM, yyyy - hh:mm:aa")
                    .format(DateTime.fromMillisecondsSinceEpoch(int.parse(document["timeStamp"]))),
                style: TextStyle(color: Colors.grey, fontSize: 12.0, fontStyle: FontStyle.italic),
              ),
              margin: EdgeInsets.only(left: 50.0, top: 10.0, bottom: 5.0),
            )
                : Container()
          ],
          crossAxisAlignment: CrossAxisAlignment.start,
        ),
        margin: EdgeInsets.only(bottom: 10.0),
      );
    }
  }

  createInput(){
    return Container(
      child: Row(
        children: <Widget>[

          //Gallery
          Material(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 1.0),
              child: IconButton(
                icon: Icon(Icons.image),
                color: Colors.lightBlueAccent,
                onPressed: ()=> getImage(),
              ),
            ),
            color: Colors.white,
          ),

          //Emojis
          Material(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 1.0),
              child: IconButton(
                icon: Icon(Icons.tag_faces),
                color: Colors.lightBlueAccent,
                onPressed: ()=> getSticker(),
              ),
            ),
            color: Colors.white,
          ),

          //Text Field
          Flexible(
            child: Container(
              child: TextField(
                style: TextStyle(color: Colors.black, fontSize: 15.0),
                controller: textEditingController,
                decoration: InputDecoration.collapsed(
                    hintText: "Write here...",
                    hintStyle: TextStyle(
                      color: Colors.grey,
                    )
                ),
                focusNode: focusNode,
              ),
            ),
          ),

          //Send message button
          Material(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 8.0),
              child: IconButton(
                icon: Icon(Icons.send),
                color: Colors.lightBlueAccent,
                onPressed: ()=> onSendMessage(textEditingController.text, 0),
              ),
            ),
            color: Colors.white,
          )
        ],
      ),
      width: double.infinity,
      height: 50.0,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.grey,
            width: 0.5
          )
        ),
        color: Colors.white,
      ),
    );
  }

  onSendMessage(String contentMsg, int type, [fileName = ""]){
    //type=0 for textMsg
    //type=1 for imageFile
    //type=2 for GIF, emojis
    int count = 0;

    if(contentMsg != null){
      if((type == 0 && contentMsg != "") || type==1 || type==2){
        if(type==0){
          RegExp exp = new RegExp(
              r"^4r5e$|^5h1t$|^5hit$|^a55$|^anal$|^anus$|^ar5e$|^arrse$|^arse$|^ass$|^ass-fucker$|^asses$|^assfucker$|^assfukka$|^asshole$|^assholes$|^asswhole$|^a_s_s$|^b!tch$|^b00bs$|^b17ch$|^b1tch$|^ballbag$|^balls$|^ballsack$|^bastard$|^beastial$|^beastiality$|^bellend$|^bestial$|^bestiality$|^bi+ch$|^biatch$|^bitch$|^bitcher$|^bitchers$|^bitches$|^bitchin$|^bitching$|^bloody$|^blow$|^job$|^blowjob$|^blowjobs$|^boiolas$|^bollock$|^bollok$|^boner$|^boob$|^boobs$|^booobs$|^boooobs$|^booooobs$|^booooooobs$|^breasts$|^buceta$|^bugger$|^bum$|^bunny$|^fucker$|^butt$|^butthole$|^buttmunch$|^buttplug$|^c0ck$|^c0cksucker$|^carpet$|^muncher$|^cawk$|^chink$|^cipa$|^cl1t$|^clit$|^clitoris$|^clits$|^cnut$|^cock$|^cock-sucker$|^cockface$|^cockhead$|^cockmunch$|^cockmuncher$|^cocks$|^cocksuck$|^cocksucked$|^cocksucker$|^cocksucking$|^cocksucks$|^cocksuka$|^cocksukka$|^cok$|^cokmuncher$|^coksucka$|^coon$|^cox$|^crap$|^cum$|^cummer$|^cumming$|^cums$|^cumshot$|^cunilingus$|^cunillingus$|^cunnilingus$|^cunt$|^cuntlick$|^cuntlicker$|^cuntlicking$|^cunts$|^cyalis$|^cyberfuc$|^cyberfuck$|^cyberfucked$|^cyberfucker$|^cyberfuckers$|^cyberfucking$|^d1ck$|^damn$|^dick$|^dickhead$|^dildo$|^dildos$|^dink$|^dinks$|^dirsa$|^dlck$|^dog-fucker$|^doggin$|^dogging$|^donkeyribber$|^doosh$|^duche$|^dyke$|^ejaculate$|^ejaculated$|^ejaculates$|^ejaculating$|^ejaculatings$|^ejaculation$|^ejakulate$|^f4nny$|^fag$|^fagging$|^faggitt$|^faggot$|^faggs$|^fagot$|^fagots$|^fags$|^fanny$|^fannyflaps$|^fannyfucker$|^fanyy$|^fatass$|^fcuk$|^fcuker$|^fcuking$|^feck$|^fecker$|^felching$|^fellate$|^fellatio$|^fingerfuck$|^fingerfucked$|^fingerfucker$|^fingerfuckers$|^fingerfucking$|^fingerfucks$|^fistfuck$|^fistfucked$|^fistfucker$|^fistfuckers$|^fistfucking$|^fistfuckings$|^fistfucks$|^flange$|^fook$|^fooker$|^fuck$|^fucka$|^fucked$|^fucker$|^fuckers$|^fuckhead$|^fuckheads$|^fuckin$|^fucking$|^fuckings$|^fuckingshitmotherfucker$|^fuckme$|^fucks$|^fuckwhit$|^fuckwit$|^fudge$|^packer$|^fudgepacker$|^fuk$|^fuker$|^fukker$|^fukkin$|^fuks$|^fukwhit$|^fukwit$|^fux$|^fux0r$|^f_u_c_k$|^gangbang$|^gangbanged$|^gangbangs$|^gaylord$|^gaysex$|^goatse$|^God$|^god-dam$|^god-damned$|^goddamn$|^goddamned$|^hardcoresex$|^hell$|^heshe$|^hoar$|^hoare$|^hoer$|^homo$|^hore$|^horniest$|^horny$|^hotsex$|^jack-off$|^jackoff$|^jap$|^jerk-off$|^jism$|^jiz$|^jizm$|^jizz$|^kawk$|^knob$|^knobead$|^knobed$|^knobend$|^knobhead$|^knobjocky$|^knobjokey$|^kock$|^kondum$|^kondums$|^kum$|^kummer$|^kumming$|^kums$|^kunilingus$|^l3i+ch$|^l3itch$|^labia$|^lmfao$|^lust$|^lusting$|^m0f0$|^m0fo$|^m45terbate$|^ma5terb8$|^ma5terbate$|^masochist$|^master-bate$|^masterb8$|^masterbat*$|^masterbat3$|^masterbate$|^masterbation$|^masterbations$|^masturbate$|^mo-fo$|^mof0$|^mofo$|^mothafuck$|^mothafucka$|^mothafuckas$|^mothafuckaz$|^mothafucked$|^mothafucker$|^mothafuckers$|^mothafuckin$|^mothafucking$|^mothafuckings$|^mothafucks$|^mother$|^fucker$|^motherfuck$|^motherfucked$|^motherfucker$|^motherfuckers$|^motherfuckin$|^motherfucking$|^motherfuckings$|^motherfuckka$|^motherfucks$|^muff$|^mutha$|^muthafecker$|^muthafuckker$|^muther$|^mutherfucker$|^n1gga$|^n1gger$|^nazi$|^nigg3r$|^nigg4h$|^nigga$|^niggah$|^niggas$|^niggaz$|^nigger$|^niggers$|^nob$|^nob$|^jokey$|^nobhead$|^nobjocky$|^nobjokey$|^numbnuts$|^nutsack$|^orgasim$|^orgasims$|^orgasm$|^orgasms$|^p0rn$|^pawn$|^pecker$|^penis$|^penisfucker$|^phonesex$|^phuck$|^phuk$|^phuked$|^phuking$|^phukked$|^phukking$|^phuks$|^phuq$|^pigfucker$|^pimpis$|^piss$|^pissed$|^pisser$|^pissers$|^pisses$|^pissflaps$|^pissin$|^pissing$|^pissoff$|^poop$|^porn$|^porno$|^pornography$|^pornos$|^prick$|^pricks$|^pron$|^pube$|^pusse$|^pussi$|^pussies$|^pussy$|^pussys$|^rectum$|^retard$|^rimjaw$|^rimming$|^s$|^hit$|^s.o.b.$|^sadist$|^schlong$|^screwing$|^scroat$|^scrote$|^scrotum$|^semen$|^sex$|^sh!+$|^sh!t$|^sh1t$|^shag$|^shagger$|^shaggin$|^shagging$|^shemale$|^shi+$|^shit$|^shitdick$|^shite$|^shited$|^shitey$|^shitfuck$|^shitfull$|^shithead$|^shiting$|^shitings$|^shits$|^shitted$|^shitter$|^shitters$|^shitting$|^shittings$|^shitty$|^skank$|^slut$|^sluts$|^smegma$|^smut$|^snatch$|^son-of-a-bitch$|^spac$|^spunk$|^s_h_i_t$|^t1tt1e5$|^t1tties$|^teets$|^teez$|^testical$|^testicle$|^tit$|^titfuck$|^tits$|^titt$|^tittie5$|^tittiefucker$|^titties$|^tittyfuck$|^tittywank$|^titwank$|^tosser$|^turd$|^tw4t$|^twat$|^twathead$|^twatty$|^twunt$|^twunter$|^v14gra$|^v1gra$|^vagina$|^viagra$|^vulva$|^w00se$|^wang$|^wank$|^wanker$|^wanky$|^whoar$|^whore$|^willies$|^willy$|^xrated$|^xxx$");
          List checkTest2 = contentMsg.split(' ');
          int i = 0;
          while (i < checkTest2.length) {
            if (exp.hasMatch(checkTest2[i].toLowerCase())) {
              checkTest2[i] = "****";
              count = count + 1;
            }
            i = i + 1;
          }
          contentMsg = checkTest2.join(" ");
        }
        textEditingController.clear();

        if(count<=4){
          var docRef = Firestore.instance.collection("messages").document(chatId)
              .collection(chatId).document(DateTime.now().millisecondsSinceEpoch.toString());

          if(type!=1){
            Firestore.instance.runTransaction((transaction) async{
              await transaction.set(docRef, {
                "idFrom": id,
                "idTo": receiverId,
                "timeStamp": DateTime.now().millisecondsSinceEpoch.toString(),
                "content": contentMsg,
                "type": type,
              });
            });
          }else{
            Firestore.instance.runTransaction((transaction) async{
              await transaction.set(docRef, {
                "idFrom": id,
                "idTo": receiverId,
                "timeStamp": DateTime.now().millisecondsSinceEpoch.toString(),
                "content": contentMsg,
                "type": type,
                "fileName": fileName,
              });
            });
          }
        }else{
          Fluttertoast.showToast(msg: "Sorry, could not send such message");
        }

        listScrollController.animateTo(0.0, duration: Duration(milliseconds: 300), curve: Curves.easeOut);

      }

    }else{
      Fluttertoast.showToast(msg: "Empty Message. Cannot be sent.");
    }
  }

  Future getImage() async{
    imageFile = await ImagePicker.pickImage(source: ImageSource.gallery);

    if(imageFile != null){
      isLoading = true;
    }

    uploadImageFile();
  }
//
//  Future uploadImageFile() async{
//    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
//
//    StorageReference storageReference = FirebaseStorage.instance.ref().child("Chat Images").child(fileName);
//
//    StorageUploadTask storageUploadTask = storageReference.putFile(imageFile);
//    StorageTaskSnapshot storageTaskSnapshot = await storageUploadTask.onComplete;
//
//    storageTaskSnapshot.ref.getDownloadURL().then((downloadUrl){
//      imageUrl = downloadUrl;
//      setState(() {
//        isLoading = false;
//
//        onSendMessage(imageUrl, 1);
//      });
//    }, onError: (error){
//      setState(() {
//       isLoading = false;
//      });
//      Fluttertoast.showToast(msg: "Error: " + error);
//    });
//  }

  Future uploadImageFile() async{

    var output = await Tflite.runModelOnImage(
      path: imageFile.path,
      numResults: 2,
      threshold: 0.5,
      imageMean: 127.5,
      imageStd: 127.5,
    );

    print(output);
    print("hello");
    var t = output[0];
    String x = t['label'];
    print(x);
    setState(() {
      isLoading = false;
//      _outputs = x;
    });

    if (x == "1 Safe")
    {
      String fileName=DateTime.now().millisecondsSinceEpoch.toString();
      StorageReference storageReference=FirebaseStorage.instance.ref().child("chat Images").child(fileName);

      StorageUploadTask storageUploadTask=storageReference.putFile(imageFile);
      StorageTaskSnapshot storageTaskSnapshot= await storageUploadTask.onComplete;

      storageTaskSnapshot.ref.getDownloadURL().then((downloadUrl){
        imageUrl=downloadUrl;
        setState(() {
          isLoading=false;
          onSendMessage(imageUrl,1, fileName);

        });
      },onError: (error){
        setState(() {
          isLoading=false;
        });
        Fluttertoast.showToast(msg: error);
      });
    }

    else
    {
      Fluttertoast.showToast(msg: "Cannot share an unsafe image.");

    }
  }

}
