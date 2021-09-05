//*************   © Copyrighted by Thinkcreative_Technologies. An Exclusive item of Envato market. Make sure you have purchased a Regular License OR Extended license for the Source Code from Envato to use this product. See the License Defination attached with source code. *********************

import 'dart:async';
import 'dart:core';
import 'dart:io';
import 'package:admob_flutter/admob_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fiberchat/Configs/Dbkeys.dart';
import 'package:fiberchat/Configs/Dbpaths.dart';
import 'package:fiberchat/Configs/app_constants.dart';
import 'package:fiberchat/Services/Providers/Observer.dart';
import 'package:fiberchat/Services/localization/language_constants.dart';
import 'package:fiberchat/Services/Admob/admob.dart';
import 'package:fiberchat/Screens/chat_screen/utils/messagedata.dart';
import 'package:fiberchat/Screens/call_history/callhistory.dart';
import 'package:fiberchat/Screens/chat_screen/chat.dart';
import 'package:fiberchat/Models/DataModel.dart';
import 'package:fiberchat/Services/Providers/user_provider.dart';
import 'package:fiberchat/Utils/alias.dart';
import 'package:fiberchat/Utils/chat_controller.dart';
import 'package:fiberchat/Utils/unawaited.dart';
import 'package:fiberchat/Utils/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scoped_model/scoped_model.dart';

class SearchChats extends StatefulWidget {
  SearchChats(
      {required this.currentUserNo,
      required this.isSecuritySetupDone,
      required this.prefs,
      key})
      : super(key: key);
  final String? currentUserNo;
  final SharedPreferences prefs;
  final bool isSecuritySetupDone;
  @override
  State createState() =>
      new SearchChatsState(currentUserNo: this.currentUserNo);
}

class SearchChatsState extends State<SearchChats> {
  SearchChatsState({Key? key, this.currentUserNo}) {
    _filter.addListener(() {
      _userQuery.add(_filter.text.isEmpty ? '' : _filter.text);
    });
  }
  GlobalKey<ScaffoldState> scaffoldState = GlobalKey();
  final TextEditingController _filter = new TextEditingController();
  bool isAuthenticating = false;

  List<StreamSubscription> unreadSubscriptions =
      List.from(<StreamSubscription>[]);

  List<StreamController> controllers = new List.from(<StreamController>[]);
  late AdmobBannerSize bannerSize;
  late AdmobInterstitial interstitialAd;
  late AdmobReward rewardAd;
  @override
  void initState() {
    super.initState();

    Fiberchat.internetLookUp();
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      final observer = Provider.of<Observer>(this.context, listen: false);
      if (IsBannerAdShow == true && observer.isadmobshow == true) {
        bannerSize = AdmobBannerSize.BANNER;
        rewardAd = AdmobReward(
          adUnitId: getRewardBasedVideoAdUnitId()!,
          listener: (AdmobAdEvent event, Map<String, dynamic>? args) {
            if (event == AdmobAdEvent.closed) rewardAd.load();
            // handleEvent(event, args, 'Reward');
          },
        );
        // interstitialAd.load();
        rewardAd.load();
      }
    });
  }

  void showSnackBar(String content) {
    // ignore: deprecated_member_use
    scaffoldState.currentState!.showSnackBar(
      SnackBar(
        content: Text(content),
        duration: Duration(milliseconds: 1500),
      ),
    );
  }

  getuid(BuildContext context) {
    final UserProvider userProvider =
        Provider.of<UserProvider>(context, listen: false);
    userProvider.getUserDetails(currentUserNo);
  }

  void cancelUnreadSubscriptions() {
    unreadSubscriptions.forEach((subscription) {
      subscription.cancel();
    });
  }

  DataModel? _cachedModel;
  bool showHidden = false, biometricEnabled = false;

  String? currentUserNo;

  bool isLoading = false;

  Widget buildItem(BuildContext context, Map<String, dynamic> user) {
    if (user[Dbkeys.phone] == currentUserNo) {
      return Container(width: 0, height: 0);
    } else {
      return StreamBuilder(
        stream: getUnread(user).asBroadcastStream(),
        builder: (context, AsyncSnapshot<MessageData> unreadData) {
          int unread = unreadData.hasData &&
                  unreadData.data!.snapshot.docs.isNotEmpty
              ? unreadData.data!.snapshot.docs
                  .where((t) => t[Dbkeys.timestamp] > unreadData.data!.lastSeen)
                  .length
              : 0;
          return Theme(
              data: ThemeData(
                  splashColor: fiberchatBlue,
                  highlightColor: Colors.transparent),
              child: Column(
                children: [
                  ListTile(
                      onLongPress: () {
                        unawaited(showDialog(
                            context: context,
                            builder: (context) {
                              return AliasForm(user, _cachedModel);
                            }));
                      },
                      leading:
                          customCircleAvatar(url: user['photoUrl'], radius: 22),
                      title: Text(
                        Fiberchat.getNickname(user)!,
                        style: TextStyle(
                          color: fiberchatBlack,
                          fontSize: 16,
                        ),
                      ),
                      onTap: () {
                        if (_cachedModel!.currentUser![Dbkeys.locked] != null &&
                            _cachedModel!.currentUser![Dbkeys.locked]
                                .contains(user[Dbkeys.phone])) {
                          NavigatorState state = Navigator.of(context);
                          ChatController.authenticate(_cachedModel!,
                              getTranslated(context, 'auth_neededchat'),
                              state: state,
                              shouldPop: false,
                              type: Fiberchat.getAuthenticationType(
                                  biometricEnabled, _cachedModel),
                              prefs: widget.prefs, onSuccess: () {
                            state.pushReplacement(new MaterialPageRoute(
                                builder: (context) => new ChatScreen(
                                    prefs: widget.prefs,
                                    unread: unread,
                                    model: _cachedModel,
                                    currentUserNo: currentUserNo,
                                    peerNo: user[Dbkeys.phone] as String?)));
                          });
                        } else {
                          Navigator.push(
                              context,
                              new MaterialPageRoute(
                                  builder: (context) => new ChatScreen(
                                      prefs: widget.prefs,
                                      unread: unread,
                                      model: _cachedModel,
                                      currentUserNo: currentUserNo,
                                      peerNo: user[Dbkeys.phone] as String?)));
                        }
                      },
                      trailing: unread != 0
                          ? Container(
                              child: Text(unread.toString(),
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                              padding: const EdgeInsets.all(7.0),
                              decoration: new BoxDecoration(
                                shape: BoxShape.circle,
                                color: user[Dbkeys.lastSeen] == true
                                    ? Colors.green[400]
                                    : Colors.blue[300],
                              ),
                            )
                          : Container(
                              child: Container(width: 0, height: 0),
                              padding: const EdgeInsets.all(7.0),
                              decoration: new BoxDecoration(
                                shape: BoxShape.circle,
                                color: user[Dbkeys.lastSeen] == true
                                    ? Colors.green[400]
                                    : Colors.grey,
                              ),
                            )),
                  Divider(),
                ],
              ));
        },
      );
    }
  }

  Stream<MessageData> getUnread(Map<String, dynamic> user) {
    String chatId = Fiberchat.getChatId(currentUserNo, user[Dbkeys.phone]);
    var controller = StreamController<MessageData>.broadcast();
    unreadSubscriptions.add(FirebaseFirestore.instance
        .collection(DbPaths.collectionmessages)
        .doc(chatId)
        .snapshots()
        .listen((doc) {
      if (doc[currentUserNo!] != null && doc[currentUserNo!] is int) {
        unreadSubscriptions.add(FirebaseFirestore.instance
            .collection(DbPaths.collectionmessages)
            .doc(chatId)
            .collection(chatId)
            .snapshots()
            .listen((snapshot) {
          controller.add(
              MessageData(snapshot: snapshot, lastSeen: doc[currentUserNo!]));
        }));
      }
    }));
    controllers.add(controller);
    return controller.stream;
  }

  _isHidden(phoneNo) {
    Map<String, dynamic> _currentUser = _cachedModel!.currentUser!;
    return _currentUser[Dbkeys.hidden] != null &&
        _currentUser[Dbkeys.hidden].contains(phoneNo);
  }

  StreamController<String> _userQuery =
      new StreamController<String>.broadcast();

  List<Map<String, dynamic>> _users = List.from(<Map<String, dynamic>>[]);

  _chats(Map<String?, Map<String, dynamic>?> _userData,
      Map<String, dynamic>? currentUser) {
    final observer = Provider.of<Observer>(this.context, listen: false);
    _users = Map.from(_userData)
        .values
        .where((_user) => _user.keys.contains(Dbkeys.chatStatus))
        .toList()
        .cast<Map<String, dynamic>>();
    Map<String?, int?> _lastSpokenAt = _cachedModel!.lastSpokenAt;
    List<Map<String, dynamic>> filtered = List.from(<Map<String, dynamic>>[]);

    _users.sort((a, b) {
      int aTimestamp = _lastSpokenAt[a[Dbkeys.phone]] ?? 0;
      int bTimestamp = _lastSpokenAt[b[Dbkeys.phone]] ?? 0;
      return bTimestamp - aTimestamp;
    });

    if (!showHidden) {
      _users.removeWhere((_user) => _isHidden(_user[Dbkeys.phone]));
    }

    return Stack(
      children: <Widget>[
        RefreshIndicator(
            onRefresh: () {
              isAuthenticating = false;
              setState(() {
                showHidden = true;
              });
              return Future.value(false);
            },
            child: Container(
                child: _users.isNotEmpty
                    ? StreamBuilder(
                        stream: _userQuery.stream.asBroadcastStream(),
                        builder: (context, snapshot) {
                          if (_filter.text.isNotEmpty || snapshot.hasData) {
                            filtered = this._users.where((user) {
                              return user[Dbkeys.nickname]
                                  .toLowerCase()
                                  .trim()
                                  .contains(new RegExp(r'' +
                                      _filter.text.toLowerCase().trim() +
                                      ''));
                            }).toList();
                            if (filtered.isNotEmpty)
                              return ListView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                padding: EdgeInsets.all(0.0),
                                itemBuilder: (context, index) => buildItem(
                                    context, filtered.elementAt(index)),
                                itemCount: filtered.length,
                              );
                            else
                              return ListView(shrinkWrap: true, children: [
                                Padding(
                                    padding: EdgeInsets.only(
                                        top:
                                            MediaQuery.of(context).size.height /
                                                3.5),
                                    child: Center(
                                      child: Text(
                                          getTranslated(
                                              context, 'nosearchresult'),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: fiberchatGrey,
                                          )),
                                    ))
                              ]);
                          }
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.fromLTRB(0, 10, 0, 30),
                            itemBuilder: (context, index) =>
                                buildItem(context, _users.elementAt(index)),
                            itemCount: _users.length,
                          );
                        })
                    : ListView(
                        shrinkWrap: true,
                        padding: EdgeInsets.all(0),
                        children: [
                            Padding(
                                padding: EdgeInsets.only(
                                    top: MediaQuery.of(context).size.height /
                                        10.5),
                                child: Center(
                                  child: Padding(
                                      padding: EdgeInsets.all(30.0),
                                      child: Text(
                                          getTranslated(context, 'nochats'),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 16,
                                            height: 1.59,
                                            color: fiberchatGrey,
                                          ))),
                                )),
                            IsBannerAdShow == true &&
                                    observer.isadmobshow == true
                                ? Container(
                                    margin:
                                        EdgeInsets.only(bottom: 30.0, top: 30),
                                    child: AdmobBanner(
                                      adUnitId: getBannerAdUnitId()!,
                                      adSize: AdmobBannerSize.MEDIUM_RECTANGLE,
                                      listener: (AdmobAdEvent event,
                                          Map<String, dynamic>? args) {
                                        // handleEvent(event, args, 'Banner');
                                      },
                                      onBannerCreated:
                                          (AdmobBannerController controller) {},
                                    ),
                                  )
                                : SizedBox(height: 0),
                          ]))),
      ],
    );
  }

  DataModel? getModel() {
    _cachedModel ??= DataModel(currentUserNo);
    return _cachedModel;
  }

  @override
  Widget build(BuildContext context) {
    final observer = Provider.of<Observer>(this.context, listen: false);
    return Fiberchat.getNTPWrappedWidget(ScopedModel<DataModel>(
      model: getModel()!,
      child:
          ScopedModelDescendant<DataModel>(builder: (context, child, _model) {
        _cachedModel = _model;
        return Scaffold(
            bottomSheet: IsBannerAdShow == true && observer.isadmobshow == true
                ? Container(
                    height: 60,
                    margin: EdgeInsets.only(
                        bottom: Platform.isIOS == true ? 25.0 : 5, top: 0),
                    child: Center(
                      child: AdmobBanner(
                        adUnitId: getBannerAdUnitId()!,
                        adSize: AdmobBannerSize.BANNER,
                        listener:
                            (AdmobAdEvent event, Map<String, dynamic>? args) {
                          // handleEvent(event, args, 'Banner');
                        },
                        onBannerCreated: (AdmobBannerController controller) {
                          // Dispose is called automatically for you when Flutter removes the banner from the widget tree.
                          // Normally you don't need to worry about disposing this yourself, it's handled.
                          // If you need direct access to dispose, this is your guy!
                          // controller.dispose();
                        },
                      ),
                    ),
                  )
                : SizedBox(
                    height: 0,
                  ),
            key: scaffoldState,
            backgroundColor: fiberchatWhite,
            body: ListView(
                padding: IsBannerAdShow == true && observer.isadmobshow == true
                    ? EdgeInsets.fromLTRB(5, 5, 5, 60)
                    : EdgeInsets.all(5),
                shrinkWrap: true,
                children: [
                  Container(
                    height: 77,
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      textCapitalization: TextCapitalization.sentences,
                      controller: _filter,
                      decoration: new InputDecoration(
                        fillColor: Colors.white,
                        filled: true,
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: fiberchatLightGreen, width: 2.0),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: fiberchatGrey, width: 1.5),
                        ),
                        hintText: getTranslated(context, 'search_recentchats'),
                      ),
                    ),
                  ),
                  Divider(),
                  _chats(_model.userData, _model.currentUser),
                ]));
      }),
    ));
  }

  @override
  void dispose() {
    super.dispose();
  }
}
