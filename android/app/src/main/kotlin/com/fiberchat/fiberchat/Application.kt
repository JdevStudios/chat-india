
package com.fiberchat.fiberchat

import io.flutter.app.FlutterApplication
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugin.common.PluginRegistry.PluginRegistrantCallback

import io.flutter.view.FlutterMain

import io.inway.ringtone.player.FlutterRingtonePlayerPlugin
import com.dexterous.flutterlocalnotifications.FlutterLocalNotificationsPlugin


class Application : FlutterApplication(), PluginRegistrantCallback {

    override fun onCreate() {
        super.onCreate()
      
        FlutterMain.startInitialization(this)
        }

    override fun registerWith(registry: PluginRegistry?) {

   if (!registry!!.hasPlugin("io.inway.ringtone.player")) {
            FlutterRingtonePlayerPlugin.registerWith(registry!!.registrarFor("io.inway.ringtone.player.FlutterRingtonePlayerPlugin"));
        }
   if (!registry!!.hasPlugin("com.dexterous.flutterlocalnotifications.FlutterLocalNotificationsPlugin")) {
        FlutterLocalNotificationsPlugin.registerWith(registry!!.registrarFor("com.dexterous.flutterlocalnotifications.FlutterLocalNotificationsPlugin"));
        }
    }


}
