//*************   © Copyrighted by Thinkcreative_Technologies. An Exclusive item of Envato market. Make sure you have purchased a Regular License OR Extended license for the Source Code from Envato to use this product. See the License Defination attached with source code. *********************

import 'dart:async';
import 'dart:io';
import 'package:admob_flutter/admob_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fiberchat/Configs/Dbkeys.dart';
import 'package:fiberchat/Configs/Dbpaths.dart';
import 'package:fiberchat/Configs/app_constants.dart';
import 'package:fiberchat/Services/Providers/Observer.dart';
import 'package:fiberchat/Services/localization/language_constants.dart';
import 'package:fiberchat/Screens/calling_screen/pickup_layout.dart';
import 'package:fiberchat/Services/Admob/admob.dart';
import 'package:fiberchat/Utils/utils.dart';
import 'package:fiberchat/widgets/ImagePicker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fiberchat/Configs/Enum.dart';

class ProfileSetting extends StatefulWidget {
  final bool? biometricEnabled;
  final AuthenticationType? type;
  final SharedPreferences prefs;
  ProfileSetting({this.biometricEnabled, this.type, required this.prefs});
  @override
  State createState() => new ProfileSettingState();
}

class ProfileSettingState extends State<ProfileSetting> {
  TextEditingController? controllerNickname;
  TextEditingController? controllerAboutMe;
  TextEditingController? controllerMobilenumber;

  String phone = '';
  String nickname = '';
  String aboutMe = '';
  String photoUrl = '';

  bool isLoading = false;
  File? avatarImageFile;

  final FocusNode focusNodeNickname = new FocusNode();
  final FocusNode focusNodeAboutMe = new FocusNode();
  AuthenticationType? _type;

  @override
  void initState() {
    super.initState();
    Fiberchat.internetLookUp();
    readLocal();
    _type = widget.type;
  }

  void readLocal() async {
    phone = widget.prefs.getString(Dbkeys.phone) ?? '';
    nickname = widget.prefs.getString(Dbkeys.nickname) ?? '';
    aboutMe = widget.prefs.getString(Dbkeys.aboutMe) ?? '';
    photoUrl = widget.prefs.getString(Dbkeys.photoUrl) ?? '';

    controllerNickname = new TextEditingController(text: nickname);
    controllerAboutMe = new TextEditingController(text: aboutMe);
    controllerMobilenumber = new TextEditingController(text: phone);
    // Force refresh input
    setState(() {});
  }

  Future getImage(File image) async {
    // ignore: unnecessary_null_comparison
    if (image != null) {
      setState(() {
        avatarImageFile = image;
      });
    }
    return uploadFile();
  }

  Future uploadFile() async {
    String fileName = phone;
    Reference reference = FirebaseStorage.instance.ref().child(fileName);
    TaskSnapshot uploading = await reference.putFile(avatarImageFile!);

    return uploading.ref.getDownloadURL();
  }

  void handleUpdateData() {
    focusNodeNickname.unfocus();
    focusNodeAboutMe.unfocus();

    setState(() {
      isLoading = true;
    });
    nickname =
        controllerNickname!.text.isEmpty ? nickname : controllerNickname!.text;
    aboutMe =
        controllerAboutMe!.text.isEmpty ? aboutMe : controllerAboutMe!.text;
    FirebaseFirestore.instance
        .collection(DbPaths.collectionusers)
        .doc(phone)
        .update({
      Dbkeys.nickname: nickname,
      Dbkeys.aboutMe: aboutMe,
      Dbkeys.authenticationType: _type!.index,
      Dbkeys.searchKey: nickname.trim().substring(0, 1).toUpperCase(),
    }).then((data) {
      widget.prefs.setString(Dbkeys.nickname, nickname);
      widget.prefs.setString(Dbkeys.aboutMe, aboutMe);
      setState(() {
        isLoading = false;
      });
      Fiberchat.toast(getTranslated(this.context, 'saved'));
      Navigator.of(context).pop();
    }).catchError((err) {
      setState(() {
        isLoading = false;
      });

      Fiberchat.toast(err.toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    final observer = Provider.of<Observer>(context, listen: false);
    return PickupLayout(
        scaffold: Fiberchat.getNTPWrappedWidget(Scaffold(
            backgroundColor: fiberchatWhite,
            appBar: new AppBar(
              leading: IconButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                icon: Icon(
                  Icons.arrow_back,
                  size: 24,
                  color: DESIGN_TYPE == Themetype.whatsapp
                      ? fiberchatWhite
                      : fiberchatBlack,
                ),
              ),
              titleSpacing: 0,
              backgroundColor: DESIGN_TYPE == Themetype.whatsapp
                  ? fiberchatDeepGreen
                  : fiberchatWhite,
              title: new Text(
                getTranslated(this.context, 'editprofile'),
                style: TextStyle(
                  fontSize: 20.0,
                  color: DESIGN_TYPE == Themetype.whatsapp
                      ? fiberchatWhite
                      : fiberchatBlack,
                  fontWeight: FontWeight.w600,
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: handleUpdateData,
                  child: Text(
                    getTranslated(this.context, 'save'),
                    style: TextStyle(
                      fontSize: 16,
                      color: DESIGN_TYPE == Themetype.whatsapp
                          ? fiberchatWhite
                          : fiberchatgreen,
                    ),
                  ),
                )
              ],
            ),
            body: Stack(
              children: <Widget>[
                SingleChildScrollView(
                  child: Column(
                    children: <Widget>[
                      // Avatar
                      Container(
                        child: Center(
                          child: Stack(
                            children: <Widget>[
                              (avatarImageFile == null)
                                  ? (photoUrl != ''
                                      ? Material(
                                          child: CachedNetworkImage(
                                            placeholder: (context, url) =>
                                                Container(
                                                    child: Padding(
                                                        padding: EdgeInsets.all(
                                                            50.0),
                                                        child:
                                                            CircularProgressIndicator(
                                                          valueColor:
                                                              AlwaysStoppedAnimation<
                                                                      Color>(
                                                                  fiberchatLightGreen),
                                                        )),
                                                    width: 150.0,
                                                    height: 150.0),
                                            imageUrl: photoUrl,
                                            width: 150.0,
                                            height: 150.0,
                                            fit: BoxFit.cover,
                                          ),
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(75.0)),
                                          clipBehavior: Clip.hardEdge,
                                        )
                                      : Icon(
                                          Icons.account_circle,
                                          size: 150.0,
                                          color: Colors.grey,
                                        ))
                                  : Material(
                                      child: Image.file(
                                        avatarImageFile!,
                                        width: 150.0,
                                        height: 150.0,
                                        fit: BoxFit.cover,
                                      ),
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(75.0)),
                                      clipBehavior: Clip.hardEdge,
                                    ),
                              Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: FloatingActionButton(
                                      backgroundColor: fiberchatLightGreen,
                                      child: Icon(Icons.camera_alt,
                                          color: fiberchatWhite),
                                      onPressed: () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    HybridImagePicker(
                                                        title: getTranslated(
                                                            this.context,
                                                            'pickimage'),
                                                        callback: getImage,
                                                        profile: true))).then(
                                            (url) {
                                          if (url != null) {
                                            photoUrl = url.toString();
                                            FirebaseFirestore.instance
                                                .collection(
                                                    DbPaths.collectionusers)
                                                .doc(phone)
                                                .update({
                                              Dbkeys.photoUrl: photoUrl
                                            }).then((data) async {
                                              await widget.prefs.setString(
                                                  Dbkeys.photoUrl, photoUrl);
                                              setState(() {
                                                isLoading = false;
                                              });
                                              // Fiberchat.toast(
                                              //     "Profile Picture Changed!");
                                            }).catchError((err) {
                                              setState(() {
                                                isLoading = false;
                                              });

                                              Fiberchat.toast(err.toString());
                                            });
                                          }
                                        });
                                      })),
                            ],
                          ),
                        ),
                        width: double.infinity,
                        margin: EdgeInsets.all(20.0),
                      ),
                      ListTile(
                          title: TextFormField(
                        textCapitalization: TextCapitalization.sentences,
                        autovalidateMode: AutovalidateMode.always,
                        controller: controllerNickname,
                        validator: (v) {
                          return v!.isEmpty
                              ? getTranslated(this.context, 'validdetails')
                              : null;
                        },
                        decoration: InputDecoration(
                            contentPadding: EdgeInsets.all(6),
                            labelStyle: TextStyle(height: 0.8),
                            labelText:
                                getTranslated(this.context, 'enter_fullname')),
                      )),
                      SizedBox(
                        height: 15,
                      ),
                      ListTile(
                          title: TextFormField(
                        textCapitalization: TextCapitalization.sentences,
                        controller: controllerAboutMe,
                        decoration: InputDecoration(
                            contentPadding: EdgeInsets.all(6),
                            labelStyle: TextStyle(height: 0.8),
                            labelText: getTranslated(this.context, 'status')),
                      )),
                      SizedBox(
                        height: 15,
                      ),
                      ListTile(
                          title: TextFormField(
                        textCapitalization: TextCapitalization.sentences,
                        readOnly: true,
                        controller: controllerMobilenumber,
                        decoration: InputDecoration(
                            contentPadding: EdgeInsets.all(6),
                            labelStyle: TextStyle(height: 0.8),
                            labelText: getTranslated(
                                this.context, 'enter_mobilenumber')),
                      )),
                      IsBannerAdShow == true && observer.isadmobshow == true
                          ? Container(
                              margin: EdgeInsets.only(bottom: 5.0, top: 40),
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
                          : SizedBox(
                              height: 0,
                            ),
                    ],
                  ),
                  padding: EdgeInsets.only(left: 15.0, right: 15.0),
                ),
                // Loading
                Positioned(
                  child: isLoading
                      ? Container(
                          child: Center(
                            child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    fiberchatBlue)),
                          ),
                          color: DESIGN_TYPE == Themetype.whatsapp
                              ? fiberchatBlack.withOpacity(0.8)
                              : fiberchatWhite.withOpacity(0.8))
                      : Container(),
                ),
              ],
            ))));
  }
}
