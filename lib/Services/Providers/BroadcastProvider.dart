//*************   © Copyrighted by Thinkcreative_Technologies. An Exclusive item of Envato market. Make sure you have purchased a Regular License OR Extended license for the Source Code from Envato to use this product. See the License Defination attached with source code. *********************

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fiberchat/Configs/Dbkeys.dart';
import 'package:fiberchat/Configs/Dbpaths.dart';
import 'dart:async';
import 'package:fiberchat/Utils/crc.dart';
import 'package:fiberchat/Utils/utils.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FirebaseBroadcastServices {
  Stream<List<BroadcastModel>> getBroadcastsList(String? phone) {
    //----BROADCAST FEATURE NOT INCLUDED IN THE CODECANYON SOURCE CODE----
    return FirebaseFirestore.instance
        .collection(DbPaths.collectionbroadcasts + 'notexists')
        .where(Dbkeys.broadcastCREATEDBY, isEqualTo: phone)
        // .orderBy(Dbkeys.broadcastCREATEDON, descending: true)
        .snapshots()
        .map((snapShot) => snapShot.docs
            .map((document) => BroadcastModel.fromJson(document.data()))
            .toList());
  }

  FlutterSecureStorage storage = new FlutterSecureStorage();
  late encrypt.Encrypter cryptor;
  final iv = encrypt.IV.fromLength(8);

  dynamic encryptWithCRC(String input) {
    try {
      String encrypted = cryptor.encrypt(input, iv: iv).base64;
      int crc = CRC32.compute(input);
      return '$encrypted${Dbkeys.crcSeperator}$crc';
    } catch (e) {
      Fiberchat.toast('Error occured while encrypting !');
      return false;
    }
  }
}

class BroadcastModel {
  Map<String, dynamic> docmap = {};
  BroadcastModel.fromJson(Map<String, dynamic> parsedJSON)
      : docmap = parsedJSON;
}
