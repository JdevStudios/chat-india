//*************   © Copyrighted by Thinkcreative_Technologies. An Exclusive item of Envato market. Make sure you have purchased a Regular License OR Extended license for the Source Code from Envato to use this product. See the License Defination attached with source code. *********************

import 'package:admob_flutter/admob_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:fiberchat/Configs/app_constants.dart';
import 'package:fiberchat/Screens/Groups/GroupDetails.dart';
import 'package:fiberchat/Screens/Groups/widget/groupChatBubble.dart';
import 'package:fiberchat/Screens/calling_screen/pickup_layout.dart';
import 'package:fiberchat/Screens/chat_screen/chat.dart';
import 'package:fiberchat/Screens/chat_screen/utils/uploadMediaWithProgress.dart';
import 'package:fiberchat/Services/Providers/AvailableContactsProvider.dart';
import 'package:fiberchat/Services/Providers/GroupChatProvider.dart';
import 'package:fiberchat/Services/Admob/admob.dart';
import 'package:fiberchat/Services/Providers/Observer.dart';
import 'package:fiberchat/Services/localization/language_constants.dart';
import 'package:fiberchat/Utils/utils.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:media_info/media_info.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart' as emojipic;
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:fiberchat/Configs/Dbkeys.dart';
import 'package:fiberchat/Configs/Dbpaths.dart';
import 'package:fiberchat/Screens/privacypolicy&TnC/PdfViewFromCachedUrl.dart';
import 'package:fiberchat/widgets/SoundPlayer/SoundPlayerPro.dart';
import 'package:flutter/foundation.dart';
import 'package:fiberchat/Services/Providers/currentchat_peer.dart';
import 'package:fiberchat/Screens/call_history/callhistory.dart';
import 'package:fiberchat/Screens/chat_screen/utils/downloadMedia.dart';
import 'package:fiberchat/Screens/contact_screens/ContactsSelect.dart';
import 'package:fiberchat/Models/DataModel.dart';
import 'package:fiberchat/Screens/chat_screen/utils/photo_view.dart';
import 'package:fiberchat/Utils/save.dart';
import 'package:fiberchat/widgets/AudioRecorder/Audiorecord.dart';
import 'package:fiberchat/widgets/DocumentPicker/documentPicker.dart';
import 'package:fiberchat/widgets/ImagePicker/image_picker.dart';
import 'package:fiberchat/widgets/VideoPicker/VideoPicker.dart';
import 'package:fiberchat/widgets/VideoPicker/VideoPreview.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:geolocator/geolocator.dart';
import 'package:giphy_get/giphy_get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:fiberchat/Configs/Enum.dart';
import 'package:fiberchat/Utils/unawaited.dart';

class GroupChatPage extends StatefulWidget {
  final String currentUserno;
  final String groupID;
  final int joinedTime;
  final DataModel model;
  final SharedPreferences prefs;

  GroupChatPage({
    Key? key,
    required this.currentUserno,
    required this.groupID,
    required this.joinedTime,
    required this.model,
    required this.prefs,
  }) : super(key: key);

  @override
  _GroupChatPageState createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage>
    with WidgetsBindingObserver {
  bool isgeneratingThumbnail = false;
  late AdmobReward rewardAd;
  late AdmobInterstitial interstitialAd;
  late Stream<QuerySnapshot> groupChatMessages;
  GlobalKey<ScaffoldState> _scaffold = new GlobalKey<ScaffoldState>();
  GlobalKey<State> _keyLoader =
      new GlobalKey<State>(debugLabel: 'qqqeqeqsssaadqeqe');
  final ScrollController realtime = new ScrollController();
  @override
  void initState() {
    super.initState();
    groupChatMessages = FirebaseFirestore.instance
        .collection(DbPaths.collectiongroups)
        .doc(widget.groupID)
        .collection(DbPaths.collectiongroupChats)
        .where(Dbkeys.groupmsgTIME, isGreaterThanOrEqualTo: widget.joinedTime)
        .orderBy(Dbkeys.groupmsgTIME, descending: false)
        .snapshots();
    setLastSeen(false, false);

    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      var currentpeer =
          Provider.of<CurrentChatPeer>(this.context, listen: false);
      final observer = Provider.of<Observer>(this.context, listen: false);
      currentpeer.setpeer(
          newgroupChatId: widget.groupID.replaceAll(RegExp('-'), '').substring(
              1, widget.groupID.replaceAll(RegExp('-'), '').toString().length));

      if (IsVideoAdShow == true && observer.isadmobshow == true) {
        rewardAd = AdmobReward(
            adUnitId: getRewardBasedVideoAdUnitId()!,
            listener: (AdmobAdEvent event, Map<String, dynamic>? args) {
              if (event == AdmobAdEvent.closed) {
                rewardAd.load();
              }
            });
        rewardAd.load();
      }

      if (IsInterstitialAdShow == true &&
          observer.isadmobshow == true &&
          ((IsVideoAdShow == false || observer.isadmobshow == false))) {
        interstitialAd = AdmobInterstitial(
          adUnitId: getInterstitialAdUnitId()!,
          listener: (AdmobAdEvent event, Map<String, dynamic>? args) {
            if (event == AdmobAdEvent.closed) interstitialAd.load();
            // handleEvent(event, args, 'Interstitial');
          },
        );
        interstitialAd.load();
      }
    });
  }

  void setStateIfMounted(f) {
    if (mounted) setState(f);
  }

  setLastSeen(bool iswillpop, isemojikeyboardopen) {
    FirebaseFirestore.instance
        .collection(DbPaths.collectiongroups)
        .doc(widget.groupID)
        .update(
      {
        widget.currentUserno: DateTime.now().millisecondsSinceEpoch,
      },
    );
    if (iswillpop == true && isemojikeyboardopen == false) {
      Navigator.of(this.context).pop();
    }
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance!.removeObserver(this);
    setLastSeen(false, isemojiShowing);
  }

  File? imageFile;
  File? thumbnailFile;

  getImage(File image) {
    final observer = Provider.of<Observer>(this.context, listen: false);
    // ignore: unnecessary_null_comparison
    if (image != null) {
      setStateIfMounted(() {
        imageFile = image;
      });
    }
    return observer.isPercentProgressShowWhileUploading
        ? uploadFileWithProgressIndicator(false)
        : uploadFile(false);
  }

  getFileName(groupid, timestamp) {
    return "${widget.currentUserno}-$timestamp";
  }

  getThumbnail(String url) async {
    final observer = Provider.of<Observer>(this.context, listen: false);
    // ignore: unnecessary_null_comparison
    setStateIfMounted(() {
      isgeneratingThumbnail = true;
    });
    String? path = await VideoThumbnail.thumbnailFile(
        video: url,
        thumbnailPath: (await getTemporaryDirectory()).path,
        imageFormat: ImageFormat.PNG,
        quality: 30);

    thumbnailFile = File(path!);
    setStateIfMounted(() {
      isgeneratingThumbnail = false;
    });
    return observer.isPercentProgressShowWhileUploading
        ? uploadFileWithProgressIndicator(true)
        : uploadFile(true);
  }

  String? videometadata;
  int? uploadTimestamp;
  int? thumnailtimestamp;
  Future uploadFile(bool isthumbnail) async {
    uploadTimestamp = DateTime.now().millisecondsSinceEpoch;
    String fileName = getFileName(
        widget.groupID,
        isthumbnail == false
            ? '$uploadTimestamp'
            : '${thumnailtimestamp}Thumbnail');
    Reference reference = FirebaseStorage.instance
        .ref("+00_GROUP_MEDIA/${widget.groupID}/")
        .child(fileName);
    TaskSnapshot uploading = await reference
        .putFile(isthumbnail == true ? thumbnailFile! : imageFile!);
    if (isthumbnail == false) {
      setStateIfMounted(() {
        thumnailtimestamp = uploadTimestamp;
      });
    }
    if (isthumbnail == true) {
      MediaInfo _mediaInfo = MediaInfo();

      await _mediaInfo.getMediaInfo(thumbnailFile!.path).then((mediaInfo) {
        setStateIfMounted(() {
          videometadata = jsonEncode({
            "width": mediaInfo['width'],
            "height": mediaInfo['height'],
            "orientation": null,
            "duration": mediaInfo['durationMs'],
            "filesize": null,
            "author": null,
            "date": null,
            "framerate": null,
            "location": null,
            "path": null,
            "title": '',
            "mimetype": mediaInfo['mimeType'],
          }).toString();
        });
      }).catchError((onError) {
        Fiberchat.toast('Sending failed !');
        print('ERROR SENDING MEDIA: $onError');
      });
    } else {
      FirebaseFirestore.instance
          .collection(DbPaths.collectionusers)
          .doc(widget.currentUserno)
          .set({
        Dbkeys.mssgSent: FieldValue.increment(1),
      }, SetOptions(merge: true));
      FirebaseFirestore.instance
          .collection(DbPaths.collectiondashboard)
          .doc(DbPaths.docchatdata)
          .set({
        Dbkeys.mediamessagessent: FieldValue.increment(1),
      }, SetOptions(merge: true));
    }

    return uploading.ref.getDownloadURL();
  }

  Future uploadFileWithProgressIndicator(bool isthumbnail) async {
    uploadTimestamp = DateTime.now().millisecondsSinceEpoch;
    String fileName = getFileName(
        widget.currentUserno,
        isthumbnail == false
            ? '$uploadTimestamp'
            : '${thumnailtimestamp}Thumbnail');
    Reference reference = FirebaseStorage.instance
        .ref("+00_GROUP_MEDIA/${widget.groupID}/")
        .child(fileName);
    UploadTask uploading =
        reference.putFile(isthumbnail == true ? thumbnailFile! : imageFile!);

    showDialog<void>(
        context: this.context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return new WillPopScope(
              onWillPop: () async => false,
              child: SimpleDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                  // side: BorderSide(width: 5, color: Colors.green)),
                  key: _keyLoader,
                  backgroundColor: Colors.white,
                  children: <Widget>[
                    Center(
                      child: StreamBuilder(
                          stream: uploading.snapshotEvents,
                          builder: (BuildContext context, snapshot) {
                            if (snapshot.hasData) {
                              final TaskSnapshot snap = uploading.snapshot;

                              return openUploadDialog(
                                context: context,
                                percent: bytesTransferred(snap) / 100,
                                title: isthumbnail == true
                                    ? getTranslated(
                                        context, 'generatingthumbnail')
                                    : getTranslated(context, 'uploading'),
                                subtitle:
                                    "${((((snap.bytesTransferred / 1024) / 1000) * 100).roundToDouble()) / 100}/${((((snap.totalBytes / 1024) / 1000) * 100).roundToDouble()) / 100} MB",
                              );
                            } else {
                              return openUploadDialog(
                                context: context,
                                percent: 0.0,
                                title: isthumbnail == true
                                    ? getTranslated(
                                        context, 'generatingthumbnail')
                                    : getTranslated(context, 'uploading'),
                                subtitle: '',
                              );
                            }
                          }),
                    ),
                  ]));
        });

    TaskSnapshot downloadTask = await uploading;
    String downloadedurl = await downloadTask.ref.getDownloadURL();

    if (isthumbnail == false) {
      setStateIfMounted(() {
        thumnailtimestamp = uploadTimestamp;
      });
    }
    if (isthumbnail == true) {
      MediaInfo _mediaInfo = MediaInfo();

      await _mediaInfo.getMediaInfo(thumbnailFile!.path).then((mediaInfo) {
        setStateIfMounted(() {
          videometadata = jsonEncode({
            "width": mediaInfo['width'],
            "height": mediaInfo['height'],
            "orientation": null,
            "duration": mediaInfo['durationMs'],
            "filesize": null,
            "author": null,
            "date": null,
            "framerate": null,
            "location": null,
            "path": null,
            "title": '',
            "mimetype": mediaInfo['mimeType'],
          }).toString();
        });
      }).catchError((onError) {
        Fiberchat.toast('Sending failed !');
        print('ERROR SENDING FILE: $onError');
      });
    } else {
      FirebaseFirestore.instance
          .collection(DbPaths.collectionusers)
          .doc(widget.currentUserno)
          .set({
        Dbkeys.mssgSent: FieldValue.increment(1),
      }, SetOptions(merge: true));
      FirebaseFirestore.instance
          .collection(DbPaths.collectiondashboard)
          .doc(DbPaths.docchatdata)
          .set({
        Dbkeys.mediamessagessent: FieldValue.increment(1),
      }, SetOptions(merge: true));
    }
    Navigator.of(_keyLoader.currentContext!, rootNavigator: true).pop(); //
    return downloadedurl;
  }

  void onSendMessage({
    required BuildContext context,
    required String content,
    required MessageType type,
  }) async {
    final observer = Provider.of<Observer>(this.context, listen: false);
    final List<GroupModel> groupList =
        Provider.of<List<GroupModel>>(context, listen: false);

    Map<dynamic, dynamic> groupDoc = groupList.indexWhere(
                (element) => element.docmap[Dbkeys.groupID] == widget.groupID) <
            0
        ? {}
        : groupList
            .lastWhere(
                (element) => element.docmap[Dbkeys.groupID] == widget.groupID)
            .docmap;
    int timestamp = DateTime.now().millisecondsSinceEpoch;
    if (content.trim() != '') {
      content = content.trim();
      textEditingController.clear();
      FirebaseFirestore.instance
          .collection(DbPaths.collectiongroups)
          .doc(widget.groupID)
          .collection(DbPaths.collectiongroupChats)
          .doc(timestamp.toString() + '--' + widget.currentUserno)
          .set({
        Dbkeys.groupmsgCONTENT: content,
        Dbkeys.groupmsgISDELETED: false,
        Dbkeys.groupmsgLISToptional: [],
        Dbkeys.groupmsgTIME: timestamp,
        Dbkeys.groupmsgSENDBY: widget.currentUserno,
        Dbkeys.groupmsgISDELETED: false,
        Dbkeys.groupmsgTYPE: type.index,
        Dbkeys.groupNAME: groupDoc[Dbkeys.groupNAME],
        Dbkeys.groupID: groupDoc[Dbkeys.groupNAME],
        Dbkeys.sendername: widget.model.currentUser![Dbkeys.nickname],
        Dbkeys.groupIDfiltered: groupDoc[Dbkeys.groupIDfiltered]
      }, SetOptions(merge: true));

      unawaited(realtime.animateTo(0.0,
          duration: Duration(milliseconds: 300), curve: Curves.easeOut));
      // _playPopSound();
      FirebaseFirestore.instance
          .collection(DbPaths.collectiongroups)
          .doc(widget.groupID)
          .update(
        {Dbkeys.groupLATESTMESSAGETIME: timestamp},
      );

      if (type == MessageType.doc ||
          type == MessageType.audio ||
          (type == MessageType.image && !content.contains('giphy')) ||
          type == MessageType.video ||
          type == MessageType.location ||
          type == MessageType.contact) {
        if (IsVideoAdShow == true && observer.isadmobshow == true) {
          Future.delayed(const Duration(milliseconds: 800), () {
            rewardAd.show();
          });
        }

        if (IsInterstitialAdShow == true &&
            observer.isadmobshow == true &&
            ((IsVideoAdShow == false || observer.isadmobshow == false))) {
          interstitialAd.show();
          Future.delayed(const Duration(milliseconds: 400), () {
            interstitialAd.load();
          });
        }
      }
    }
  }

  _onEmojiSelected(Emoji emoji) {
    textEditingController
      ..text += emoji.emoji
      ..selection = TextSelection.fromPosition(
          TextPosition(offset: textEditingController.text.length));
    setStateIfMounted(() {});
    if (textEditingController.text.isNotEmpty &&
        textEditingController.text.length == 1) {
      setStateIfMounted(() {});
    }
    if (textEditingController.text.isEmpty) {
      setStateIfMounted(() {});
    }
  }

  _onBackspacePressed() {
    textEditingController
      ..text = textEditingController.text.characters.skipLast(1).toString()
      ..selection = TextSelection.fromPosition(
          TextPosition(offset: textEditingController.text.length));
    if (textEditingController.text.isNotEmpty &&
        textEditingController.text.length == 1) {
      setStateIfMounted(() {});
    }
    if (textEditingController.text.isEmpty) {
      setStateIfMounted(() {});
    }
  }

  final TextEditingController textEditingController =
      new TextEditingController();
  FocusNode keyboardFocusNode = new FocusNode();
  Widget buildInputAndroid(
    BuildContext context,
    bool isemojiShowing,
    Function refreshThisInput,
    bool keyboardVisible,
  ) {
    final observer = Provider.of<Observer>(context, listen: false);

    return Column(children: [
      Container(
        margin: EdgeInsets.only(bottom: Platform.isIOS == true ? 20 : 0),
        child: Row(
          children: <Widget>[
            Flexible(
              child: Container(
                margin: EdgeInsets.only(
                  left: 10,
                ),
                decoration: BoxDecoration(
                    color: fiberchatWhite,
                    // border: Border.all(
                    //   color: Colors.red[500],
                    // ),
                    borderRadius: BorderRadius.all(Radius.circular(30))),
                child: Row(
                  children: [
                    isemojiShowing == true && keyboardVisible == false
                        ? SizedBox(
                            width: 50,
                            child: IconButton(
                              onPressed: () {
                                refreshThisInput();
                              },
                              icon: Icon(
                                Icons.keyboard,
                                color: fiberchatGrey,
                              ),
                            ),
                          )
                        : SizedBox(
                            width: textEditingController.text.isNotEmpty
                                ? 50
                                : 110,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox(
                                  width: 30,
                                  child: IconButton(
                                    onPressed: () {
                                      refreshThisInput();
                                    },
                                    icon: Icon(
                                      Icons.emoji_emotions,
                                      color: fiberchatGrey,
                                    ),
                                  ),
                                ),
                                textEditingController.text.isNotEmpty == true
                                    ? SizedBox(
                                        width: 0,
                                      )
                                    : SizedBox(
                                        width: 50,
                                        child: IconButton(
                                            color: fiberchatWhite,
                                            padding: EdgeInsets.all(0.0),
                                            icon: Icon(
                                              Icons.gif,
                                              size: 40,
                                              color: fiberchatGrey,
                                            ),
                                            onPressed: observer
                                                        .ismediamessagingallowed ==
                                                    false
                                                ? () {
                                                    Fiberchat.showRationale(
                                                        getTranslated(
                                                            this.context,
                                                            'mediamssgnotallowed'));
                                                  }
                                                : () async {
                                                    GiphyGif? gif =
                                                        await GiphyGet.getGif(
                                                      tabColor: fiberchatgreen,
                                                      context: context,
                                                      apiKey:
                                                          GiphyAPIKey, //YOUR API KEY HERE
                                                      lang:
                                                          GiphyLanguage.english,
                                                    );
                                                    if (gif != null &&
                                                        mounted) {
                                                      onSendMessage(
                                                        context: context,
                                                        content: gif.images!
                                                            .original!.url,
                                                        type: MessageType.image,
                                                      );
                                                      hidekeyboard(context);
                                                      setStateIfMounted(() {});
                                                    }
                                                  }),
                                      ),
                                textEditingController.text.isNotEmpty == true
                                    ? SizedBox()
                                    : SizedBox(
                                        width: 30,
                                        child: IconButton(
                                          icon: new Icon(
                                            Icons.attachment_outlined,
                                            color: fiberchatGrey,
                                          ),
                                          padding: EdgeInsets.all(0.0),
                                          onPressed:
                                              observer.ismediamessagingallowed ==
                                                      false
                                                  ? () {
                                                      Fiberchat.showRationale(
                                                          getTranslated(
                                                              this.context,
                                                              'mediamssgnotallowed'));
                                                    }
                                                  : () {
                                                      hidekeyboard(context);
                                                      shareMedia(context);
                                                    },
                                          color: fiberchatWhite,
                                        ),
                                      )
                              ],
                            ),
                          ),
                    Flexible(
                      child: TextField(
                        textCapitalization: TextCapitalization.sentences,
                        onTap: () {
                          if (isemojiShowing == true) {
                          } else {
                            keyboardFocusNode.requestFocus();
                          }
                        },
                        onChanged: (f) {
                          if (textEditingController.text.isNotEmpty &&
                              textEditingController.text.length == 1) {
                            setStateIfMounted(() {});
                          }
                          if (textEditingController.text.isEmpty) {
                            setStateIfMounted(() {});
                          }
                        },
                        showCursor: true,
                        focusNode: keyboardFocusNode,
                        maxLines: null,
                        style: TextStyle(fontSize: 16.0, color: fiberchatBlack),
                        controller: textEditingController,
                        decoration: InputDecoration(
                          enabledBorder: OutlineInputBorder(
                            // width: 0.0 produces a thin "hairline" border
                            borderRadius: BorderRadius.circular(1),
                            borderSide: BorderSide(
                                color: Colors.transparent, width: 1.5),
                          ),
                          hoverColor: Colors.transparent,
                          focusedBorder: OutlineInputBorder(
                            // width: 0.0 produces a thin "hairline" border
                            borderRadius: BorderRadius.circular(1),
                            borderSide: BorderSide(
                                color: Colors.transparent, width: 1.5),
                          ),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(1),
                              borderSide:
                                  BorderSide(color: Colors.transparent)),
                          contentPadding: EdgeInsets.fromLTRB(10, 4, 7, 4),
                          hintText: getTranslated(this.context, 'typmsg'),
                          hintStyle:
                              TextStyle(color: Colors.grey, fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              height: 47,
              width: 47,
              // alignment: Alignment.center,
              margin: EdgeInsets.only(left: 6, right: 10),
              decoration: BoxDecoration(
                  color: DESIGN_TYPE == Themetype.whatsapp
                      ? fiberchatgreen
                      : fiberchatLightGreen,
                  // border: Border.all(
                  //   color: Colors.red[500],
                  // ),
                  borderRadius: BorderRadius.all(Radius.circular(30))),
              child: Padding(
                padding: const EdgeInsets.all(2.0),
                child: IconButton(
                  icon: new Icon(
                    textEditingController.text.isNotEmpty == true
                        ? Icons.send
                        : Icons.mic,
                    color: fiberchatWhite.withOpacity(0.99),
                  ),
                  onPressed: observer.ismediamessagingallowed == true
                      ? textEditingController.text.isNotEmpty == false
                          ? () {
                              hidekeyboard(context);

                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => AudioRecord(
                                            title: getTranslated(
                                                this.context, 'record'),
                                            callback: getImage,
                                          ))).then((url) {
                                if (url != null) {
                                  onSendMessage(
                                    context: context,
                                    content: url +
                                        '-BREAK-' +
                                        uploadTimestamp.toString(),
                                    type: MessageType.audio,
                                  );
                                } else {}
                              });
                            }
                          : observer.istextmessagingallowed == false
                              ? () {
                                  Fiberchat.showRationale(getTranslated(
                                      this.context, 'textmssgnotallowed'));
                                }
                              : () => onSendMessage(
                                    context: context,
                                    content:
                                        textEditingController.value.text.trim(),
                                    type: MessageType.text,
                                  )
                      : () {
                          Fiberchat.showRationale(getTranslated(
                              this.context, 'mediamssgnotallowed'));
                        },
                  color: fiberchatWhite,
                ),
              ),
            ),
            // Button send message
          ],
        ),
        width: double.infinity,
        height: 60.0,
        decoration: new BoxDecoration(
          // border: new Border(top: new BorderSide(color: Colors.grey, width: 0.5)),
          color: Colors.transparent,
        ),
      ),
      isemojiShowing == true && keyboardVisible == false
          ? Offstage(
              offstage: !isemojiShowing,
              child: SizedBox(
                height: 300,
                child: EmojiPicker(
                    onEmojiSelected: (emojipic.Category category, Emoji emoji) {
                      _onEmojiSelected(emoji);
                    },
                    onBackspacePressed: _onBackspacePressed,
                    config: Config(
                        columns: 7,
                        emojiSizeMax: 32.0,
                        verticalSpacing: 0,
                        horizontalSpacing: 0,
                        initCategory: emojipic.Category.RECENT,
                        bgColor: Color(0xFFF2F2F2),
                        indicatorColor: fiberchatgreen,
                        iconColor: Colors.grey,
                        iconColorSelected: fiberchatgreen,
                        progressIndicatorColor: Colors.blue,
                        backspaceColor: fiberchatgreen,
                        showRecentsTab: true,
                        recentsLimit: 28,
                        noRecentsText: 'No Recents',
                        noRecentsStyle:
                            TextStyle(fontSize: 20, color: Colors.black26),
                        categoryIcons: CategoryIcons(),
                        buttonMode: ButtonMode.MATERIAL)),
              ),
            )
          : SizedBox(),
    ]);
  }

  Widget buildInputIos(BuildContext context) {
    return Consumer<Observer>(
        builder: (context, observer, _child) => Container(
              margin: EdgeInsets.only(bottom: Platform.isIOS == true ? 20 : 0),
              child: Row(
                children: <Widget>[
                  Flexible(
                    child: Container(
                      margin: EdgeInsets.only(
                        left: 10,
                      ),
                      decoration: BoxDecoration(
                          color: fiberchatWhite,
                          borderRadius: BorderRadius.all(Radius.circular(30))),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 100,
                            child: Row(
                              children: [
                                IconButton(
                                    color: fiberchatWhite,
                                    padding: EdgeInsets.all(0.0),
                                    icon: Icon(
                                      Icons.gif,
                                      size: 40,
                                      color: fiberchatGrey,
                                    ),
                                    onPressed: observer
                                                .ismediamessagingallowed ==
                                            false
                                        ? () {
                                            Fiberchat.showRationale(
                                                getTranslated(this.context,
                                                    'mediamssgnotallowed'));
                                          }
                                        : () async {
                                            GiphyGif? gif =
                                                await GiphyGet.getGif(
                                              tabColor: fiberchatgreen,
                                              context: context,
                                              apiKey:
                                                  GiphyAPIKey, //YOUR API KEY HERE
                                              lang: GiphyLanguage.english,
                                            );
                                            if (gif != null && mounted) {
                                              onSendMessage(
                                                context: context,
                                                content:
                                                    gif.images!.original!.url,
                                                type: MessageType.image,
                                              );
                                              hidekeyboard(context);
                                              setStateIfMounted(() {});
                                            }
                                          }),
                                IconButton(
                                  icon: new Icon(
                                    Icons.attachment_outlined,
                                    color: fiberchatGrey,
                                  ),
                                  padding: EdgeInsets.all(0.0),
                                  onPressed: observer.ismediamessagingallowed ==
                                          false
                                      ? () {
                                          Fiberchat.showRationale(getTranslated(
                                              this.context,
                                              'mediamssgnotallowed'));
                                        }
                                      : () {
                                          hidekeyboard(context);
                                          shareMedia(context);
                                        },
                                  color: fiberchatWhite,
                                ),
                              ],
                            ),
                          ),
                          Flexible(
                            child: TextField(
                              textCapitalization: TextCapitalization.sentences,
                              onChanged: (v) {},
                              maxLines: null,
                              style: TextStyle(
                                  fontSize: 18.0, color: fiberchatBlack),
                              controller: textEditingController,
                              decoration: InputDecoration(
                                enabledBorder: OutlineInputBorder(
                                  // width: 0.0 produces a thin "hairline" border
                                  borderRadius: BorderRadius.circular(1),
                                  borderSide: BorderSide(
                                      color: Colors.transparent, width: 1.5),
                                ),
                                hoverColor: Colors.transparent,
                                focusedBorder: OutlineInputBorder(
                                  // width: 0.0 produces a thin "hairline" border
                                  borderRadius: BorderRadius.circular(1),
                                  borderSide: BorderSide(
                                      color: Colors.transparent, width: 1.5),
                                ),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(1),
                                    borderSide:
                                        BorderSide(color: Colors.transparent)),
                                contentPadding: EdgeInsets.fromLTRB(7, 4, 7, 4),
                                hintText: getTranslated(this.context, 'typmsg'),
                                hintStyle:
                                    TextStyle(color: Colors.grey, fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Button send message
                  Container(
                    height: 47,
                    width: 47,
                    // alignment: Alignment.center,
                    margin: EdgeInsets.only(left: 6, right: 10),
                    decoration: BoxDecoration(
                        color: DESIGN_TYPE == Themetype.whatsapp
                            ? fiberchatgreen
                            : fiberchatLightGreen,
                        // border: Border.all(
                        //   color: Colors.red[500],
                        // ),
                        borderRadius: BorderRadius.all(Radius.circular(30))),
                    child: Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: IconButton(
                        icon: new Icon(
                          Icons.send,
                          color: fiberchatWhite.withOpacity(0.99),
                        ),
                        onPressed: observer.istextmessagingallowed == false
                            ? () {
                                Fiberchat.showRationale(getTranslated(
                                    this.context, 'textmssgnotallowed'));
                              }
                            : () {
                                onSendMessage(
                                  context: context,
                                  content:
                                      textEditingController.value.text.trim(),
                                  type: MessageType.text,
                                );
                              },
                        color: fiberchatWhite,
                      ),
                    ),
                  ),
                ],
              ),
              width: double.infinity,
              height: 60.0,
              decoration: new BoxDecoration(
                // border: new Border(top: new BorderSide(color: Colors.grey, width: 0.5)),
                color: Colors.transparent,
              ),
            ));
  }

  buildEachMessage(Map<String, dynamic> doc, GroupModel groupData) {
    if (doc[Dbkeys.groupmsgTYPE] == Dbkeys.groupmsgTYPEnotificationAddedUser) {
      return Center(
          child: Chip(
        backgroundColor: Colors.blueGrey[50],
        label: Text(
          doc[Dbkeys.groupmsgLISToptional].contains(widget.currentUserno) &&
                  doc[Dbkeys.groupmsgLISToptional].length > 1
              ? doc[Dbkeys.groupmsgLISToptional]
                      .contains(groupData.docmap[Dbkeys.groupCREATEDBY])
                  ? widget.currentUserno ==
                          groupData.docmap[Dbkeys.groupCREATEDBY]
                      ? '${getTranslated(this.context, 'uhaveadded')} ${doc[Dbkeys.groupmsgLISToptional].length - 1} ${getTranslated(this.context, 'users')} '
                      : '${getTranslated(this.context, 'adminahasadded')} ${getTranslated(this.context, 'youandother')} ${doc[Dbkeys.groupmsgLISToptional].length - 1} ${getTranslated(this.context, 'users')}'
                  : '${doc[Dbkeys.groupmsgSENDBY]} ${getTranslated(this.context, 'added')} ${getTranslated(this.context, 'youandother')} ${doc[Dbkeys.groupmsgLISToptional].length - 1} ${getTranslated(this.context, 'users')}'
              : doc[Dbkeys.groupmsgLISToptional]
                          .contains(widget.currentUserno) &&
                      doc[Dbkeys.groupmsgLISToptional].length == 1
                  ? '${getTranslated(this.context, 'youareaddedtothisgrp')}'
                  : !doc[Dbkeys.groupmsgLISToptional]
                              .contains(widget.currentUserno) &&
                          doc[Dbkeys.groupmsgLISToptional].length == 1
                      ? doc[Dbkeys.groupmsgSENDBY] ==
                              groupData.docmap[Dbkeys.groupCREATEDBY]
                          ? widget.currentUserno ==
                                  groupData.docmap[Dbkeys.groupCREATEDBY]
                              ? '${getTranslated(this.context, 'uhaveadded')} ${doc[Dbkeys.groupmsgLISToptional][0]}'
                              : '${getTranslated(this.context, 'adminhasadded')} ${doc[Dbkeys.groupmsgLISToptional][0]}'
                          : '${doc[Dbkeys.groupmsgSENDBY]} ${getTranslated(this.context, 'adminhasadded')} ${doc[Dbkeys.groupmsgLISToptional][0]}'
                      : doc[Dbkeys.groupmsgSENDBY] ==
                              groupData.docmap[Dbkeys.groupCREATEDBY]
                          ? '${getTranslated(this.context, 'adminahasadded')} ${doc[Dbkeys.groupmsgLISToptional].length} ${getTranslated(this.context, 'users')}'
                          : '${doc[Dbkeys.groupmsgSENDBY]} ${getTranslated(this.context, 'added')} ${doc[Dbkeys.groupmsgLISToptional].length} ${getTranslated(this.context, 'users')}',
          style: TextStyle(fontSize: 13),
        ),
      ));
    } else if (doc[Dbkeys.groupmsgTYPE] ==
        Dbkeys.groupmsgTYPEnotificationCreatedGroup) {
      return Center(
          child: Chip(
        backgroundColor: Colors.blueGrey[50],
        label: Text(
          groupData.docmap[Dbkeys.groupCREATEDBY].contains(widget.currentUserno)
              ? getTranslated(this.context, 'youcreatedthisgroup')
              : '${groupData.docmap[Dbkeys.groupCREATEDBY]} ${getTranslated(this.context, 'hascreatedthisgroup')}',
          style: TextStyle(fontSize: 13),
        ),
      ));
    } else if (doc[Dbkeys.groupmsgTYPE] ==
        Dbkeys.groupmsgTYPEnotificationUpdatedGroupDetails) {
      return Center(
          child: Chip(
        backgroundColor: Colors.blueGrey[50],
        label: Text(
          doc[Dbkeys.groupmsgSENDBY] == widget.currentUserno
              ? getTranslated(this.context, 'uhvupdatedgrpdetails')
              : '${doc[Dbkeys.groupmsgSENDBY]} ${getTranslated(this.context, 'hasupdatedgrpdetails')}'
                      .contains(groupData.docmap[Dbkeys.groupCREATEDBY])
                  ? getTranslated(this.context, 'grpdetailsupdatebyadmin')
                  : '${doc[Dbkeys.groupmsgSENDBY]} ${getTranslated(this.context, 'hasupdatedgrpdetails')}',
          style: TextStyle(fontSize: 13),
        ),
      ));
    } else if (doc[Dbkeys.groupmsgTYPE] ==
        Dbkeys.groupmsgTYPEnotificationUserSetAsAdmin) {
      return Center(
          child: Chip(
        backgroundColor: Colors.blueGrey[50],
        label: Text(
          doc[Dbkeys.groupmsgSENDBY] == widget.currentUserno
              ? '${doc[Dbkeys.groupmsgLISToptional][0]} ${getTranslated(this.context, 'hasbeensetasadminbyu')}'
              : doc[Dbkeys.groupmsgLISToptional][0] == widget.currentUserno
                  ? '${doc[Dbkeys.groupmsgSENDBY]} ${getTranslated(this.context, 'hvsetuasadmin')}'
                  : '${doc[Dbkeys.groupmsgSENDBY]} ${getTranslated(this.context, 'set')} ${doc[Dbkeys.groupmsgLISToptional][0]} ${getTranslated(this.context, 'asadmin')}',
          style: TextStyle(fontSize: 13),
        ),
      ));
    } else if (doc[Dbkeys.groupmsgTYPE] ==
        Dbkeys.groupmsgTYPEnotificationUserRemovedAsAdmin) {
      return Center(
          child: Chip(
        backgroundColor: Colors.blueGrey[50],
        label: Text(
          doc[Dbkeys.groupmsgSENDBY] == widget.currentUserno
              ? '${getTranslated(this.context, 'youhaveremoved')} ${doc[Dbkeys.groupmsgLISToptional][0]} ${getTranslated(this.context, 'fromadmin')}'
              : doc[Dbkeys.groupmsgLISToptional][0] == widget.currentUserno
                  ? '${doc[Dbkeys.groupmsgSENDBY]} ${getTranslated(this.context, 'theyremoveduasadmin')}'
                  : '${doc[Dbkeys.groupmsgSENDBY]} ${getTranslated(this.context, 'hasremoved')} ${doc[Dbkeys.groupmsgLISToptional][0]} ${getTranslated(this.context, 'fromadmin')}',
          style: TextStyle(fontSize: 13),
        ),
      ));
    } else if (doc[Dbkeys.groupmsgTYPE] ==
        Dbkeys.groupmsgTYPEnotificationUpdatedGroupicon) {
      return Center(
          child: Chip(
        backgroundColor: Colors.blueGrey[50],
        label: Text(
          doc[Dbkeys.groupmsgSENDBY] == widget.currentUserno
              ? getTranslated(this.context, 'youupdatedgrpicon')
              : '${doc[Dbkeys.groupmsgSENDBY]} ${getTranslated(this.context, 'hasupdatedgrpicon')}',
          style: TextStyle(fontSize: 13),
        ),
      ));
    } else if (doc[Dbkeys.groupmsgTYPE] ==
        Dbkeys.groupmsgTYPEnotificationDeletedGroupicon) {
      return Center(
          child: Chip(
        backgroundColor: Colors.blueGrey[50],
        label: Text(
          doc[Dbkeys.groupmsgSENDBY] == widget.currentUserno
              ? getTranslated(this.context, 'youremovedgrpicon')
              : '${doc[Dbkeys.groupmsgSENDBY]} ${getTranslated(this.context, 'hasremovedgrpicon')}',
          style: TextStyle(fontSize: 13),
        ),
      ));
    } else if (doc[Dbkeys.groupmsgTYPE] ==
        Dbkeys.groupmsgTYPEnotificationRemovedUser) {
      return Center(
          child: Chip(
        backgroundColor: Colors.blueGrey[50],
        label: Text(
          doc[Dbkeys.groupmsgCONTENT].contains('by ' + widget.currentUserno)
              ? '${getTranslated(this.context, 'youhaveremoved')} ${doc[Dbkeys.groupmsgLISToptional][0]}'
              : doc[Dbkeys.groupmsgSENDBY] ==
                      groupData.docmap[Dbkeys.groupCREATEDBY]
                  ? '${doc[Dbkeys.groupmsgLISToptional][0]} ${getTranslated(this.context, 'removedbyadmin')}'
                  : '${doc[Dbkeys.groupmsgSENDBY]} ${getTranslated(this.context, 'hasremoved')} ${doc[Dbkeys.groupmsgLISToptional][0]}',
          style: TextStyle(fontSize: 13),
        ),
      ));
    } else if (doc[Dbkeys.groupmsgTYPE] ==
        Dbkeys.groupmsgTYPEnotificationUserLeft) {
      return Center(
          child: Chip(
        backgroundColor: Colors.blueGrey[50],
        label: Text(
          doc[Dbkeys.groupmsgCONTENT].contains(widget.currentUserno)
              ? getTranslated(this.context, 'youleftthegroup')
              : '${doc[Dbkeys.groupmsgCONTENT]}',
          style: TextStyle(fontSize: 13),
        ),
      ));
    } else if (doc[Dbkeys.groupmsgTYPE] == MessageType.image.index ||
        doc[Dbkeys.groupmsgTYPE] == MessageType.doc.index ||
        doc[Dbkeys.groupmsgTYPE] == MessageType.text.index ||
        doc[Dbkeys.groupmsgTYPE] == MessageType.video.index ||
        doc[Dbkeys.groupmsgTYPE] == MessageType.audio.index ||
        doc[Dbkeys.groupmsgTYPE] == MessageType.contact.index ||
        doc[Dbkeys.groupmsgTYPE] == MessageType.location.index) {
      return buildMediaMessages(doc, groupData);
    }

    return Text(doc[Dbkeys.groupmsgCONTENT]);
  }

  contextMenu(BuildContext context, Map<String, dynamic> doc,
      {bool saved = false}) {
    List<Widget> tiles = List.from(<Widget>[]);

    if (doc[Dbkeys.groupmsgSENDBY] == widget.currentUserno) {
      tiles.add(ListTile(
          dense: true,
          leading: Icon(Icons.delete),
          title: Text(
            getTranslated(context, 'dltforeveryone'),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          onTap: () async {
            Navigator.of(this.context).pop();
            if (doc[Dbkeys.messageType] == MessageType.image.index &&
                !doc[Dbkeys.groupmsgCONTENT].contains('giphy')) {
              FirebaseStorage.instance
                  .refFromURL(doc[Dbkeys.groupmsgCONTENT])
                  .delete();
            } else if (doc[Dbkeys.messageType] == MessageType.doc.index) {
              FirebaseStorage.instance
                  .refFromURL(doc[Dbkeys.groupmsgCONTENT].split('-BREAK-')[0])
                  .delete();
            } else if (doc[Dbkeys.messageType] == MessageType.audio.index) {
              FirebaseStorage.instance
                  .refFromURL(doc[Dbkeys.groupmsgCONTENT].split('-BREAK-')[0])
                  .delete();
            } else if (doc[Dbkeys.messageType] == MessageType.video.index) {
              FirebaseStorage.instance
                  .refFromURL(doc[Dbkeys.groupmsgCONTENT].split('-BREAK-')[0])
                  .delete();
              FirebaseStorage.instance
                  .refFromURL(doc[Dbkeys.groupmsgCONTENT].split('-BREAK-')[1])
                  .delete();
            }

            FirebaseFirestore.instance
                .collection(DbPaths.collectiongroups)
                .doc(widget.groupID)
                .collection(DbPaths.collectiongroupChats)
                .doc(
                    '${doc[Dbkeys.groupmsgTIME]}--${doc[Dbkeys.groupmsgSENDBY]}')
                .update({
              Dbkeys.groupmsgISDELETED: true,
              Dbkeys.groupmsgCONTENT: '',
            });
          }));
    }

    showDialog(
        context: this.context,
        builder: (context) {
          return SimpleDialog(children: tiles);
        });
  }

  Widget buildMediaMessages(Map<String, dynamic> doc, GroupModel groupData) {
    bool isMe = widget.currentUserno == doc[Dbkeys.groupmsgSENDBY];
    bool saved = false;
    final observer = Provider.of<Observer>(this.context, listen: false);
    return Consumer<AvailableContactsProvider>(
        builder: (context, contactsProvider, _child) => InkWell(
              onLongPress: doc[Dbkeys.groupmsgISDELETED] == true ||
                      doc[Dbkeys.groupmsgSENDBY] != widget.currentUserno
                  ? () {}
                  : () {
                      contextMenu(context, doc);
                      hidekeyboard(context);
                    },
              child: GroupChatBubble(
                is24hrsFormat: observer.is24hrsTimeformat,
                prefs: widget.prefs,
                currentUserNo: widget.currentUserno,
                model: widget.model,
                savednameifavailable: contactsProvider.filtered!.entries
                            .toList()
                            .indexWhere((element) =>
                                element.key == doc[Dbkeys.groupmsgSENDBY]) >=
                        0
                    ? contactsProvider.filtered!.entries
                        .toList()[contactsProvider.filtered!.entries
                            .toList()
                            .indexWhere((element) =>
                                element.key == doc[Dbkeys.groupmsgSENDBY])]
                        .value
                    : null,
                postedbyname: contactsProvider.joinedUserPhoneStringAsInServer
                            .indexWhere((element) =>
                                element.phone == doc[Dbkeys.groupmsgSENDBY]) >=
                        0
                    ? contactsProvider
                            .joinedUserPhoneStringAsInServer[contactsProvider
                                .joinedUserPhoneStringAsInServer
                                .indexWhere((element) =>
                                    element.phone ==
                                    doc[Dbkeys.groupmsgSENDBY])]
                            .name ??
                        doc[Dbkeys.groupmsgSENDBY]
                    : '',
                postedbyphone: doc[Dbkeys.groupmsgSENDBY],
                messagetype: doc[Dbkeys.groupmsgISDELETED] == true
                    ? MessageType.text
                    : doc[Dbkeys.messageType] == MessageType.text.index
                        ? MessageType.text
                        : doc[Dbkeys.messageType] == MessageType.contact.index
                            ? MessageType.contact
                            : doc[Dbkeys.messageType] ==
                                    MessageType.location.index
                                ? MessageType.location
                                : doc[Dbkeys.messageType] ==
                                        MessageType.image.index
                                    ? MessageType.image
                                    : doc[Dbkeys.messageType] ==
                                            MessageType.video.index
                                        ? MessageType.video
                                        : doc[Dbkeys.messageType] ==
                                                MessageType.doc.index
                                            ? MessageType.doc
                                            : doc[Dbkeys.messageType] ==
                                                    MessageType.audio.index
                                                ? MessageType.audio
                                                : MessageType.text,
                child: doc[Dbkeys.groupmsgISDELETED] == true
                    ? Text(
                        getTranslated(context, 'msgdeleted'),
                        style: TextStyle(
                            color: fiberchatBlack.withOpacity(0.6),
                            fontSize: 15,
                            fontStyle: FontStyle.italic),
                      )
                    : doc[Dbkeys.messageType] == MessageType.text.index
                        ? getTextMessage(isMe, doc, saved)
                        : doc[Dbkeys.messageType] == MessageType.location.index
                            ? getLocationMessage(doc[Dbkeys.content],
                                saved: false)
                            : doc[Dbkeys.messageType] == MessageType.doc.index
                                ? getDocmessage(context, doc[Dbkeys.content],
                                    saved: false)
                                : doc[Dbkeys.messageType] ==
                                        MessageType.audio.index
                                    ? getAudiomessage(
                                        context, doc[Dbkeys.content],
                                        isMe: isMe, saved: false)
                                    : doc[Dbkeys.messageType] ==
                                            MessageType.video.index
                                        ? getVideoMessage(
                                            context, doc[Dbkeys.content],
                                            saved: false)
                                        : doc[Dbkeys.messageType] ==
                                                MessageType.contact.index
                                            ? getContactMessage(
                                                context, doc[Dbkeys.content],
                                                saved: false)
                                            : getImageMessage(
                                                doc,
                                                saved: saved,
                                              ),
                isMe: isMe,
                delivered: true,
                isContinuing: true,
                timestamp: doc[Dbkeys.groupmsgTIME],
              ),
            ));
  }

  Widget getVideoMessage(BuildContext context, String message,
      {bool saved = false}) {
    Map<dynamic, dynamic>? meta =
        jsonDecode((message.split('-BREAK-')[2]).toString());
    return Container(
      child: InkWell(
        onTap: () {
          Navigator.push(
              this.context,
              new MaterialPageRoute(
                  builder: (context) => new PreviewVideo(
                        isdownloadallowed: true,
                        filename: message.split('-BREAK-')[1],
                        id: null,
                        videourl: message.split('-BREAK-')[0],
                        aspectratio: meta!["width"] / meta["height"],
                      )));
        },
        child: Container(
          color: Colors.blueGrey,
          width: 230.0,
          height: 230.0,
          child: Stack(
            children: [
              CachedNetworkImage(
                placeholder: (context, url) => Container(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(fiberchatBlue),
                  ),
                  width: 230.0,
                  height: 230.0,
                  padding: EdgeInsets.all(80.0),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey,
                    borderRadius: BorderRadius.all(
                      Radius.circular(0.0),
                    ),
                  ),
                ),
                errorWidget: (context, str, error) => Material(
                  child: Image.asset(
                    'assets/images/img_not_available.jpeg',
                    width: 230.0,
                    height: 230.0,
                    fit: BoxFit.cover,
                  ),
                  borderRadius: BorderRadius.all(
                    Radius.circular(0.0),
                  ),
                  clipBehavior: Clip.hardEdge,
                ),
                imageUrl: message.split('-BREAK-')[1],
                width: 230.0,
                height: 230.0,
                fit: BoxFit.cover,
              ),
              Container(
                color: Colors.black.withOpacity(0.4),
                width: 230.0,
                height: 230.0,
              ),
              Center(
                child: Icon(Icons.play_circle_fill_outlined,
                    color: Colors.white70, size: 65),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget getContactMessage(BuildContext context, String message,
      {bool saved = false}) {
    return SizedBox(
      width: 210,
      height: 75,
      child: Column(
        children: [
          ListTile(
            isThreeLine: false,
            leading: customCircleAvatar(url: null, radius: 20),
            title: Text(
              message.split('-BREAK-')[0],
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                  color: Colors.blue[400]),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                message.split('-BREAK-')[1],
                style: TextStyle(
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87),
              ),
            ),
          ),

          // ignore: deprecated_member_use
        ],
      ),
    );
  }

  Widget getTextMessage(bool isMe, Map<String, dynamic> doc, bool saved) {
    return selectablelinkify(
        doc[Dbkeys.content], 15.5, isMe ? TextAlign.right : TextAlign.left);
  }

  Widget getLocationMessage(String? message, {bool saved = false}) {
    return InkWell(
      onTap: () {
        launch(message!);
      },
      child: Image.asset(
        'assets/images/mapview.jpg',
        width: MediaQuery.of(this.context).size.width / 1.7,
        height: (MediaQuery.of(this.context).size.width / 1.7) * 0.6,
      ),
    );
  }

  Widget getAudiomessage(BuildContext context, String message,
      {bool saved = false, bool isMe = true}) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      // width: 250,
      // height: 116,
      child: Column(
        children: [
          SizedBox(
            width: 200,
            height: 80,
            child: MultiPlayback(
              isMe: isMe,
              onTapDownloadFn: Platform.isIOS
                  ? () {
                      launch(message.split('-BREAK-')[0]);
                    }
                  : () async {
                      await downloadFile(
                        context: _scaffold.currentContext!,
                        fileName:
                            'Recording_' + message.split('-BREAK-')[1] + '.mp3',
                        isonlyview: false,
                        keyloader: _keyLoader,
                        uri: message.split('-BREAK-')[0],
                      );
                    },
              url: message.split('-BREAK-')[0],
            ),
          )
        ],
      ),
    );
  }

  Widget getDocmessage(BuildContext context, String message,
      {bool saved = false}) {
    return SizedBox(
      width: 220,
      height: 116,
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.all(4),
            isThreeLine: false,
            leading: Container(
              decoration: BoxDecoration(
                color: message.split('-BREAK-')[1].endsWith('.pdf')
                    ? Colors.red[400]
                    : Colors.cyan[700],
                borderRadius: BorderRadius.circular(7.0),
              ),
              padding: EdgeInsets.all(12),
              child: Icon(
                Icons.attach_file_rounded,
                size: 25,
                color: Colors.white,
              ),
            ),
            title: Text(
              message.split('-BREAK-')[1],
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: TextStyle(
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87),
            ),
          ),
          Divider(
            height: 3,
          ),
          message.split('-BREAK-')[1].endsWith('.pdf')
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // ignore: deprecated_member_use
                    FlatButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<dynamic>(
                              builder: (_) => PDFViewerCachedFromUrl(
                                title: message.split('-BREAK-')[1],
                                url: message.split('-BREAK-')[0],
                              ),
                            ),
                          );
                        },
                        child: Text(getTranslated(context, 'preview'),
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Colors.blue[400]))),
                    // ignore: deprecated_member_use
                    FlatButton(
                        onPressed: Platform.isIOS
                            ? () {
                                launch(message.split('-BREAK-')[0]);
                              }
                            : () async {
                                await downloadFile(
                                  context: _scaffold.currentContext!,
                                  fileName: message.split('-BREAK-')[1],
                                  isonlyview: false,
                                  keyloader: _keyLoader,
                                  uri: message.split('-BREAK-')[0],
                                );
                              },
                        child: Text(getTranslated(context, 'download'),
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Colors.blue[400]))),
                  ],
                )
              // ignore: deprecated_member_use
              : FlatButton(
                  onPressed: Platform.isIOS
                      ? () {
                          launch(message.split('-BREAK-')[0]);
                        }
                      : () async {
                          await downloadFile(
                            context: _scaffold.currentContext!,
                            fileName: message.split('-BREAK-')[1],
                            isonlyview: false,
                            keyloader: _keyLoader,
                            uri: message.split('-BREAK-')[0],
                          );
                        },
                  child: Text(getTranslated(context, 'download'),
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.blue[400]))),
        ],
      ),
    );
  }

  Widget getImageMessage(Map<String, dynamic> doc, {bool saved = false}) {
    return Container(
      child: saved
          ? Material(
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                      image: Save.getImageFromBase64(doc[Dbkeys.content]).image,
                      fit: BoxFit.cover),
                ),
                width: doc[Dbkeys.content].contains('giphy') ? 160 : 230.0,
                height: doc[Dbkeys.content].contains('giphy') ? 160 : 230.0,
              ),
              borderRadius: BorderRadius.all(
                Radius.circular(8.0),
              ),
              clipBehavior: Clip.hardEdge,
            )
          : InkWell(
              onTap: () => Navigator.push(
                  this.context,
                  MaterialPageRoute(
                    builder: (context) => PhotoViewWrapper(
                      message: doc[Dbkeys.content],
                      tag: doc[Dbkeys.groupmsgTIME].toString(),
                      imageProvider:
                          CachedNetworkImageProvider(doc[Dbkeys.content]),
                    ),
                  )),
              child: CachedNetworkImage(
                placeholder: (context, url) => Container(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(fiberchatBlue),
                  ),
                  width: doc[Dbkeys.content].contains('giphy') ? 160 : 230.0,
                  height: doc[Dbkeys.content].contains('giphy') ? 160 : 230.0,
                  padding: EdgeInsets.all(80.0),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey,
                    borderRadius: BorderRadius.all(
                      Radius.circular(8.0),
                    ),
                  ),
                ),
                errorWidget: (context, str, error) => Material(
                  child: Image.asset(
                    'assets/images/img_not_available.jpeg',
                    width: doc[Dbkeys.content].contains('giphy') ? 160 : 230.0,
                    height: doc[Dbkeys.content].contains('giphy') ? 160 : 230.0,
                    fit: BoxFit.cover,
                  ),
                  borderRadius: BorderRadius.all(
                    Radius.circular(8.0),
                  ),
                  clipBehavior: Clip.hardEdge,
                ),
                imageUrl: doc[Dbkeys.content],
                width: doc[Dbkeys.content].contains('giphy') ? 160 : 230.0,
                height: doc[Dbkeys.content].contains('giphy') ? 160 : 230.0,
                fit: BoxFit.cover,
              ),
            ),
    );
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      Fiberchat.toast(
          'Location permissions are denied. Please go to settings & allow location tracking permission.');
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        // Permissions are denied forever, handle appropriately.
        Fiberchat.toast(
            'Location permissions are denied. Please go to settings & allow location tracking permission.');
        return Future.error(
            'Location permissions are permanently denied, we cannot request permissions.');
      }

      if (permission == LocationPermission.denied) {
        Fiberchat.toast(
            'Location permissions are pdenied. Please go to settings & allow location tracking permission.');
        return Future.error('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      Fiberchat.toast(
        getTranslated(this.context, 'detectingloc'),
      );
    }
    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }

  Widget buildMessages(
    BuildContext context,
  ) {
    return Consumer<List<GroupModel>>(
        builder: (context, groupList, _child) => Flexible(
            child: StreamBuilder(
                stream: groupChatMessages,
                builder:
                    (context, AsyncSnapshot<QuerySnapshot<dynamic>> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              fiberchatLightGreen)),
                    );
                  } else if (snapshot.hasData &&
                      snapshot.data!.docs.length > 0) {
                    return ListView(
                      // shrinkWrap: true,
                      physics: AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.all(10.0),
                      children: [
                        ListView.builder(
                            physics: NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: snapshot.data!.docs.length,
                            itemBuilder: (context, int i) {
                              return buildEachMessage(
                                  snapshot.data!.docs[i].data(),
                                  groupList.lastWhere((element) =>
                                      element.docmap[Dbkeys.groupID] ==
                                      widget.groupID));
                            }),
                      ],
                      controller: realtime,
                      reverse: true,
                    );
                  }
                  return SizedBox();
                })));
  }

  Widget buildLoadingThumbnail() {
    return Positioned(
      child: isgeneratingThumbnail
          ? Container(
              child: Center(
                child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(fiberchatBlue)),
              ),
              color: DESIGN_TYPE == Themetype.whatsapp
                  ? fiberchatBlack.withOpacity(0.6)
                  : fiberchatWhite.withOpacity(0.6),
            )
          : Container(),
    );
  }

  shareMedia(BuildContext context) {
    showModalBottomSheet(
        context: context,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
        ),
        builder: (BuildContext context) {
          // return your layout
          return Container(
            padding: EdgeInsets.all(12),
            height: 250,
            child: Column(children: [
              SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  SizedBox(
                    child: Column(
                      children: [
                        RawMaterialButton(
                          disabledElevation: 0,
                          onPressed: () {
                            hidekeyboard(context);
                            Navigator.of(context).pop();
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => HybridDocumentPicker(
                                          title: getTranslated(
                                              this.context, 'pickdoc'),
                                          callback: getImage,
                                        ))).then((url) async {
                              if (url != null) {
                                Fiberchat.toast(
                                  getTranslated(this.context, 'plswait'),
                                );

                                onSendMessage(
                                  context: this.context,
                                  content: url +
                                      '-BREAK-' +
                                      basename(imageFile!.path).toString(),
                                  type: MessageType.doc,
                                );
                                // Fiberchat.toast(
                                //     getTranslated(this.context, 'sent'));
                              } else {}
                            });
                          },
                          elevation: .5,
                          fillColor: Colors.indigo,
                          child: Icon(
                            Icons.file_copy,
                            size: 25.0,
                            color: Colors.white,
                          ),
                          padding: EdgeInsets.all(15.0),
                          shape: CircleBorder(),
                        ),
                        SizedBox(
                          height: 8,
                        ),
                        Text(
                          getTranslated(this.context, 'doc'),
                          style:
                              TextStyle(color: Colors.grey[700], fontSize: 14),
                        )
                      ],
                    ),
                  ),
                  SizedBox(
                    child: Column(
                      children: [
                        RawMaterialButton(
                          disabledElevation: 0,
                          onPressed: () {
                            hidekeyboard(context);
                            Navigator.of(context).pop();
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => HybridVideoPicker(
                                          title: getTranslated(
                                              this.context, 'pickvideo'),
                                          callback: getImage,
                                        ))).then((url) async {
                              if (url != null) {
                                Fiberchat.toast(
                                  getTranslated(this.context, 'plswait'),
                                );
                                String thumbnailurl = await getThumbnail(url);
                                onSendMessage(
                                  context: this.context,
                                  content: url +
                                      '-BREAK-' +
                                      thumbnailurl +
                                      '-BREAK-' +
                                      videometadata,
                                  type: MessageType.video,
                                );
                                Fiberchat.toast(
                                    getTranslated(this.context, 'sent'));
                              } else {}
                            });
                          },
                          elevation: .5,
                          fillColor: Colors.pink[600],
                          child: Icon(
                            Icons.video_collection_sharp,
                            size: 25.0,
                            color: Colors.white,
                          ),
                          padding: EdgeInsets.all(15.0),
                          shape: CircleBorder(),
                        ),
                        SizedBox(
                          height: 8,
                        ),
                        Text(
                          getTranslated(this.context, 'video'),
                          style:
                              TextStyle(color: Colors.grey[700], fontSize: 14),
                        )
                      ],
                    ),
                  ),
                  SizedBox(
                    child: Column(
                      children: [
                        RawMaterialButton(
                          disabledElevation: 0,
                          onPressed: () {
                            hidekeyboard(context);
                            Navigator.of(context).pop();
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => HybridImagePicker(
                                          title: getTranslated(
                                              this.context, 'pickimage'),
                                          callback: getImage,
                                        ))).then((url) {
                              if (url != null) {
                                onSendMessage(
                                  context: this.context,
                                  content: url,
                                  type: MessageType.image,
                                );
                              } else {}
                            });
                          },
                          elevation: .5,
                          fillColor: Colors.purple,
                          child: Icon(
                            Icons.image_rounded,
                            size: 25.0,
                            color: Colors.white,
                          ),
                          padding: EdgeInsets.all(15.0),
                          shape: CircleBorder(),
                        ),
                        SizedBox(
                          height: 8,
                        ),
                        Text(
                          getTranslated(this.context, 'image'),
                          style:
                              TextStyle(color: Colors.grey[700], fontSize: 14),
                        )
                      ],
                    ),
                  )
                ],
              ),
              SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  SizedBox(
                    child: Column(
                      children: [
                        RawMaterialButton(
                          disabledElevation: 0,
                          onPressed: () {
                            hidekeyboard(context);

                            Navigator.of(context).pop();
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => AudioRecord(
                                          title: getTranslated(
                                              this.context, 'record'),
                                          callback: getImage,
                                        ))).then((url) {
                              if (url != null) {
                                onSendMessage(
                                  context: this.context,
                                  content: url +
                                      '-BREAK-' +
                                      uploadTimestamp.toString(),
                                  type: MessageType.audio,
                                );
                              } else {}
                            });
                          },
                          elevation: .5,
                          fillColor: Colors.yellow[900],
                          child: Icon(
                            Icons.mic_rounded,
                            size: 25.0,
                            color: Colors.white,
                          ),
                          padding: EdgeInsets.all(15.0),
                          shape: CircleBorder(),
                        ),
                        SizedBox(
                          height: 8,
                        ),
                        Text(
                          getTranslated(this.context, 'audio'),
                          style: TextStyle(color: Colors.grey[700]),
                        )
                      ],
                    ),
                  ),
                  SizedBox(
                    child: Column(
                      children: [
                        RawMaterialButton(
                          disabledElevation: 0,
                          onPressed: () async {
                            hidekeyboard(context);
                            Navigator.of(context).pop();
                            await _determinePosition().then(
                              (location) async {
                                var locationstring =
                                    'https://www.google.com/maps/search/?api=1&query=${location.latitude},${location.longitude}';
                                onSendMessage(
                                  context: context,
                                  content: locationstring,
                                  type: MessageType.location,
                                );
                                setStateIfMounted(() {});
                                Fiberchat.toast(
                                  getTranslated(this.context, 'sent'),
                                );
                              },
                            );
                          },
                          elevation: .5,
                          fillColor: Colors.cyan[700],
                          child: Icon(
                            Icons.location_on,
                            size: 25.0,
                            color: Colors.white,
                          ),
                          padding: EdgeInsets.all(15.0),
                          shape: CircleBorder(),
                        ),
                        SizedBox(
                          height: 8,
                        ),
                        Text(
                          getTranslated(this.context, 'location'),
                          style: TextStyle(color: Colors.grey[700]),
                        )
                      ],
                    ),
                  ),
                  SizedBox(
                    child: Column(
                      children: [
                        RawMaterialButton(
                          disabledElevation: 0,
                          onPressed: () async {
                            hidekeyboard(context);
                            Navigator.of(context).pop();
                            await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => ContactsSelect(
                                        currentUserNo: widget.currentUserno,
                                        model: widget.model,
                                        biometricEnabled: false,
                                        prefs: widget.prefs,
                                        onSelect: (name, phone) {
                                          onSendMessage(
                                            context: context,
                                            content: '$name-BREAK-$phone',
                                            type: MessageType.contact,
                                          );
                                        })));
                          },
                          elevation: .5,
                          fillColor: Colors.blue[800],
                          child: Icon(
                            Icons.person,
                            size: 25.0,
                            color: Colors.white,
                          ),
                          padding: EdgeInsets.all(15.0),
                          shape: CircleBorder(),
                        ),
                        SizedBox(
                          height: 8,
                        ),
                        Text(
                          getTranslated(this.context, 'contact'),
                          style: TextStyle(color: Colors.grey[700]),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ]),
          );
        });
  }

  Future<bool> onWillPop() {
    if (isemojiShowing == true) {
      setState(() {
        isemojiShowing = false;
      });
      Future.value(false);
    } else {
      setLastSeen(true, isemojiShowing);
      return Future.value(true);
    }
    return Future.value(false);
  }

  bool isemojiShowing = false;
  refreshInput() {
    setStateIfMounted(() {
      if (isemojiShowing == false) {
        keyboardFocusNode.unfocus();
        isemojiShowing = true;
      } else {
        isemojiShowing = false;
        keyboardFocusNode.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var _keyboardVisible = MediaQuery.of(context).viewInsets.bottom != 0;

    return PickupLayout(
        scaffold: Fiberchat.getNTPWrappedWidget(Consumer<List<GroupModel>>(
            builder: (context, groupList, _child) => WillPopScope(
                  onWillPop: isgeneratingThumbnail == true
                      ? () async {
                          return Future.value(false);
                        }
                      : isemojiShowing == true
                          ? () {
                              setState(() {
                                isemojiShowing = false;
                                keyboardFocusNode.unfocus();
                              });
                              return Future.value(false);
                            }
                          : () async {
                              WidgetsBinding.instance!
                                  .addPostFrameCallback((timeStamp) {
                                var currentpeer = Provider.of<CurrentChatPeer>(
                                    this.context,
                                    listen: false);
                                currentpeer.setpeer(newgroupChatId: '');
                              });
                              setLastSeen(false, false);

                              return Future.value(true);
                            },
                  child: Stack(
                    children: [
                      Scaffold(
                          key: _scaffold,
                          appBar: AppBar(
                            titleSpacing: -5,
                            leading: Container(
                              margin: EdgeInsets.only(right: 0),
                              width: 10,
                              child: IconButton(
                                icon: Icon(
                                  Icons.arrow_back,
                                  size: 24,
                                  color: DESIGN_TYPE == Themetype.whatsapp
                                      ? fiberchatWhite
                                      : fiberchatBlack,
                                ),
                                onPressed: onWillPop,
                              ),
                            ),
                            backgroundColor: DESIGN_TYPE == Themetype.whatsapp
                                ? fiberchatDeepGreen
                                : fiberchatWhite,
                            title: InkWell(
                              onTap: () {
                                Navigator.push(
                                    context,
                                    new MaterialPageRoute(
                                        builder: (context) => new GroupDetails(
                                            model: widget.model,
                                            prefs: widget.prefs,
                                            currentUserno: widget.currentUserno,
                                            groupID: widget.groupID)));
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Padding(
                                      padding:
                                          const EdgeInsets.fromLTRB(0, 7, 0, 7),
                                      child: customCircleAvatarGroup(
                                          radius: 20,
                                          url: groupList
                                              .lastWhere((element) =>
                                                  element
                                                      .docmap[Dbkeys.groupID] ==
                                                  widget.groupID)
                                              .docmap[Dbkeys.groupPHOTOURL])),
                                  SizedBox(
                                    width: 7,
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        groupList
                                            .lastWhere((element) =>
                                                element
                                                    .docmap[Dbkeys.groupID] ==
                                                widget.groupID)
                                            .docmap[Dbkeys.groupNAME],
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            color: DESIGN_TYPE ==
                                                    Themetype.whatsapp
                                                ? fiberchatWhite
                                                : fiberchatBlack,
                                            fontSize: 17.0,
                                            fontWeight: FontWeight.w500),
                                      ),
                                      SizedBox(
                                        height: 6,
                                      ),
                                      Text(
                                        getTranslated(
                                            context, 'tapherefrgrpinfo'),
                                        style: TextStyle(
                                            color: DESIGN_TYPE ==
                                                    Themetype.whatsapp
                                                ? fiberchatWhite
                                                : fiberchatGrey,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w400),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          body: Stack(children: <Widget>[
                            new Container(
                              decoration: new BoxDecoration(
                                color: DESIGN_TYPE == Themetype.whatsapp
                                    ? fiberchatChatbackground
                                    : fiberchatWhite,
                                image: new DecorationImage(
                                    image: AssetImage(
                                        "assets/images/background.png"),
                                    fit: BoxFit.cover),
                              ),
                            ),
                            PageView(children: <Widget>[
                              Column(children: [
                                buildMessages(context),
                                groupList
                                                .lastWhere((element) =>
                                                    element.docmap[
                                                        Dbkeys.groupID] ==
                                                    widget.groupID)
                                                .docmap[Dbkeys.groupTYPE] ==
                                            Dbkeys
                                                .groupTYPEallusersmessageallowed ||
                                        groupList
                                            .lastWhere((element) =>
                                                element
                                                    .docmap[Dbkeys.groupID] ==
                                                widget.groupID)
                                            .docmap[Dbkeys.groupADMINLIST]
                                            .contains(widget.currentUserno)
                                    ? Platform.isAndroid
                                        ? buildInputAndroid(
                                            context,
                                            isemojiShowing,
                                            refreshInput,
                                            _keyboardVisible,
                                          )
                                        : buildInputIos(context)
                                    : Container(
                                        alignment: Alignment.center,
                                        padding:
                                            EdgeInsets.fromLTRB(14, 7, 14, 7),
                                        color: Colors.white,
                                        height: 70,
                                        width:
                                            MediaQuery.of(context).size.width,
                                        child: Text(
                                          getTranslated(
                                              context, 'onlyadminsend'),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(height: 1.3),
                                        ),
                                      ),
                              ])
                            ]),
                          ])),
                      buildLoadingThumbnail()
                    ],
                  ),
                ))));
  }

  Widget selectablelinkify(
      String? text, double? fontsize, TextAlign? textalign) {
    return SelectableLinkify(
      style: TextStyle(
          fontSize: fontsize,
          color: Colors.black87,
          height: 1.3,
          fontStyle: FontStyle.normal),
      text: text ?? "",
      textAlign: textalign,
      onOpen: (link) async {
        if (await canLaunch(link.url)) {
          await launch(link.url);
        } else {
          throw 'Could not launch $link';
        }
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed)
      setLastSeen(false, false);
    else
      setLastSeen(false, false);
  }
}

deletedGroupWidget(BuildContext context) {
  return Scaffold(
    appBar: AppBar(),
    body: Container(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Text(
            getTranslated(context, 'deletedgroup'),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
  );
}
