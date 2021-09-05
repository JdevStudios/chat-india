//*************   © Copyrighted by Thinkcreative_Technologies. An Exclusive item of Envato market. Make sure you have purchased a Regular License OR Extended license for the Source Code from Envato to use this product. See the License Defination attached with source code. *********************

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fiberchat/Configs/Dbkeys.dart';
import 'package:fiberchat/Configs/Dbpaths.dart';
import 'dart:async';

class FirebaseGroupServices {
  Stream<List<GroupModel>> getGroupsList(String? phone) {
    return FirebaseFirestore.instance
        .collection(DbPaths.collectiongroups)
        .where(Dbkeys.groupMEMBERSLIST, arrayContains: phone)
        .orderBy(Dbkeys.groupCREATEDON, descending: true)
        .snapshots()
        .map((snapShot) => snapShot.docs
            .map((document) => GroupModel.fromJson(document.data()))
            .toList());
  }
}

class GroupModel {
  Map<String, dynamic> docmap = {};

  GroupModel.fromJson(Map<String, dynamic> parsedJSON) : docmap = parsedJSON;
}
