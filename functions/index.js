'use strict';

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const firebase = admin.initializeApp();

exports.deleteGroup = functions.firestore.document('/groups/{groupId}')
    .onDelete(async(snap, context) => {
        const { groupId } = context.params;
        const bucket = firebase.storage().bucket();
        return bucket.deleteFiles({
            prefix: `+00_GROUP_MEDIA/${groupId}`
        });

    });
exports.deleteStatus = functions.firestore.document('/status/{statusId}')
    .onDelete(async(snap, context) => {
        const { statusId } = context.params;
        const bucket = firebase.storage().bucket();
        return bucket.deleteFiles({
            prefix: `+00_STATUS_MEDIA/${statusId}`
        });

    });
exports.deleteBroadcast = functions.firestore.document('/broadcasts/{broadcastId}')
    .onDelete(async(snap, context) => {
        const { broadcastId } = context.params;
        const bucket = firebase.storage().bucket();
        return bucket.deleteFiles({
            prefix: `+00_BROADCAST_MEDIA/${broadcastId}`
        });

    });
exports.recieveGroupMsgNotification = functions.firestore.document('/groups/{groupId}/groupChats/{chatId}')
    .onCreate(async(snap, context) => {
        const message = snap.data();

        const multiLangNotifMap = {
            "ntm": "New text message",
            "nim": "📷 Photo",
            "nvm": "🎥 Video",
            "nam": "🎙️ Recording",
            "ncm": "👤 Contact shared",
            "ndm": "📄 Document",
            "nlm": "📍 Current Location shared",
            "niac": "📞 Incoming Audio Call",
            "nivc": "🎥 Incoming Video Call",
            "ce": "Call Ended",
            "mc": "Missed Call",
            "aorc": "Accept Or Reject the Call",
            "cr": " all Rejected"
        };
        // Notification details.
        const payload = {
            notification: {
                title: message.name,
                body: message.sname + ':  ' + (message.type == 0 ? multiLangNotifMap['ntm'] : message.type == 1 ? multiLangNotifMap['nim'] : message.type == 2 ? multiLangNotifMap['nvm'] : message.type == 3 ? multiLangNotifMap['ndm'] : message.type == 4 ? multiLangNotifMap['nlm'] : message.type == 5 ? multiLangNotifMap['ncm'] : message.type == 6 ? multiLangNotifMap['nam'] : multiLangNotifMap['ntm']),
                click_action: 'FLUTTER_NOTIFICATION_CLICK',
                priority: "high",
                sound: 'default',
            },
            data: {
                'titleMultilang': message.name,
                'bodyMultilang': message.sname + ':  ' + (message.type == 0 ? multiLangNotifMap['ntm'] : message.type == 1 ? multiLangNotifMap['nim'] : message.type == 2 ? multiLangNotifMap['nvm'] : message.type == 3 ? multiLangNotifMap['ndm'] : message.type == 4 ? multiLangNotifMap['nlm'] : message.type == 5 ? multiLangNotifMap['ncm'] : message.type == 6 ? multiLangNotifMap['nam'] : multiLangNotifMap['ntm']),
                'title': 'New message in Group',
                'body': 'New message(s) recieved.',
                'groupid': message.iDfltrd,
                'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            },

        };
        var options = {
            priority: 'high',
            contentAvailable: true,

        };
        await admin.messaging().sendToTopic(`GROUP${message.iDfltrd}`, payload, options);
    });

exports.manageGroupTokens = functions.firestore.document('/tempUnsubscribeTokens/{id}')
    .onCreate(async(snap, context) => {
        const message = snap.data();
        // These registration tokens come from the client FCM SDKs.
        const registrationTokens = message.notificationTokens;
        if (message.type == 'subscribe') {
            // Subscribe the devices corresponding to the registration tokens to the
            // topic.
            admin.messaging().subscribeToTopic(registrationTokens, `GROUP${message.iDfltrd}`)
                .then((response) => {
                    // See the MessagingTopicManagementResponse reference documentation
                    // for the contents of response.
                    console.log('Successfully subscribed to topic:', response);
                })
                .catch((error) => {
                    console.log('Error subscribing to topic:', error);
                });
        } else if (message.type == 'unsubscribe') {
            // Unsubscribe the devices corresponding to the registration tokens from
            // the topic.
            admin.messaging().unsubscribeFromTopic(registrationTokens, `GROUP${message.iDfltrd}`)
                .then((response) => {
                    // See the MessagingTopicManagementResponse reference documentation
                    // for the contents of response.
                    console.log('Successfully unsubscribed from topic:', response);
                })
                .catch((error) => {
                    console.log('Error unsubscribing from topic:', error);
                });



        }


    });

exports.sendNewMessageNotification = functions.firestore.document('/messages/{chatId}/{chat_id}/{timestamp}')
    .onCreate(async(snap, context) => {
        const message = snap.data();
        // Get the list of device notification tokens.
        const getRecipientPromise = admin.firestore().collection('users').doc(message.to).get();

        // The snapshot to the user's tokens.
        let recipient;
        let isMultilangNotificationEnabled;
        let multiLangNotifMap;
        // The array containing all the user's tokens.
        let tokens;

        const results = await Promise.all([getRecipientPromise]);

        recipient = results[0];


        tokens = recipient.data().notificationTokens || [];
        isMultilangNotificationEnabled = recipient.data().isMultiLangNotifEnabled || false;
        multiLangNotifMap = recipient.data().notificationsMap || {};
        // Check if there are any device tokens.
        if (tokens.length === 0) {
            return console.log('There are no notification tokens to send to.');
        }
        // if (recipient.data().lastSeen === true) {
        //     return console.log('User is Online. So no need to send message.');
        // }
        let payload;
        // Notification details.
        if (isMultilangNotificationEnabled == true) {
            //----MultiLang New Message Notification --------------------------------------------------------------------------------                

            payload = {
                notification: {
                    title: message.sname || message.from,
                    body: message.type == 0 ? multiLangNotifMap['ntm'] : message.type == 1 ? multiLangNotifMap['nim'] : message.type == 2 ? multiLangNotifMap['nvm'] : message.type == 3 ? multiLangNotifMap['ndm'] : message.type == 4 ? multiLangNotifMap['nlm'] : message.type == 5 ? multiLangNotifMap['ncm'] : message.type == 6 ? multiLangNotifMap['nam'] : multiLangNotifMap['ntm'],
                    click_action: 'FLUTTER_NOTIFICATION_CLICK',
                    priority: "high",
                    sound: 'default',
                },
                data: {

                    'titleMultilang': message.sname || message.from,
                    'bodyMultilang': message.type == 0 ? multiLangNotifMap['ntm'] : message.type == 1 ? multiLangNotifMap['nim'] : message.type == 2 ? multiLangNotifMap['nvm'] : message.type == 3 ? multiLangNotifMap['ndm'] : message.type == 4 ? multiLangNotifMap['nlm'] : message.type == 5 ? multiLangNotifMap['ncm'] : message.type == 6 ? multiLangNotifMap['nam'] : multiLangNotifMap['ntm'],
                    'title': 'You have new message(s)',
                    'body': 'New message(s) recieved.',
                    'peerid': message.from,
                    'click_action': 'FLUTTER_NOTIFICATION_CLICK',
                },

            };

        } else {
            //----non-MultiLang New Message Notification --------------------------------------------------------------------------------                

            payload = {
                notification: {
                    title: 'You have new message(s)',
                    body: 'New message(s) recieved.',
                    click_action: 'FLUTTER_NOTIFICATION_CLICK',
                    priority: "high",
                    sound: 'default',
                },
                data: {
                    'titleMultilang': 'You have new message(s)',
                    'bodyMultilang': 'New message(s) recieved.',
                    'title': 'You have new message(s)',
                    'body': 'New message(s) recieved.',
                    'peerid': message.from,
                    'click_action': 'FLUTTER_NOTIFICATION_CLICK',
                },

            };


        }

        // Send notifications to all tokens.
        const response = await admin.messaging().sendToDevice(tokens, payload);
        // For each message check if there was an error.
        const tokensToRemove = [];
        response.results.forEach((result, index) => {
            const error = result.error;
            if (error) {
                console.error('Failure sending notification to', tokens[index], error);
                // Cleanup the tokens who are not registered anymore.
                if (error.code === 'messaging/invalid-registration-token' ||
                    error.code === 'messaging/registration-token-not-registered') {
                    tokensToRemove.push(tokens[index]);
                }
            }
        });
        return recipient.ref.update({
            notificationTokens: tokens.filter((token) => !tokensToRemove.includes(token))
        });
    });




exports.newIncomingCall = functions.firestore.document('/users/{userId}/callhistory/{callId}')
    .onCreate(async(snap, context) => {
        const message = snap.data();

        if (message['TYPE'] === 'OUTGOING') {
            return console.log('Skipped Notification as it is Outgoing Call.');
        } else {


            // Get the list of device notification tokens.
            const getRecipientPromise = admin.firestore().collection('users').doc(message['TARGET']).get();

            // The snapshot to the user's tokens.
            let recipient;

            // The array containing all the user's tokens.
            let tokens;
            let isMultilangNotificationEnabled;
            let multiLangNotifMap;
            const results = await Promise.all([getRecipientPromise]);

            recipient = results[0];
            tokens = recipient.data().notificationTokens || [];
            isMultilangNotificationEnabled = recipient.data().isMultiLangNotifEnabled || false;
            multiLangNotifMap = recipient.data().notificationsMap || {};
            // Check if there are any device tokens.
            if (tokens.length === 0) {
                return console.log('There are no notification tokens to send to.');
            }
            let payload;
            // Notification details.
            if (isMultilangNotificationEnabled == true) {
                //----MultiLang Call Notification --------------------------------------------------------------------------------                

                if (message['ISVIDEOCALL'] == true) {
                    payload = {
                        //  Disabled the notification property so that onbackgroundmessage can be triggered--------
                        // notification: {
                        //     title: 'Incoming Video Call...',
                        //     body: 'Accept / Reject the Call',
                        //     click_action: 'FLUTTER_NOTIFICATION_CLICK',

                        //     priority: 'high',
                        //     sound: 'default'

                        // },
                        data: {
                            'dp': message['DP'],
                            'titleMultilang': multiLangNotifMap['nivc'],
                            'bodyMultilang': multiLangNotifMap['aorc'],
                            'title': 'Incoming Video Call...',
                            'body': 'Accept / Reject the Call',
                            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
                        }

                    }
                    var options = {
                        priority: 'high',
                        contentAvailable: true,

                    };
                } else {
                    payload = {
                        //  Disabled the notification property so that onbackgroundmessage can be triggered--------
                        // notification: {
                        //     title: 'Incoming Audio Call...',
                        //     body: 'Accept / Reject the Call',
                        //     click_action: 'FLUTTER_NOTIFICATION_CLICK',
                        //     priority: 'high',
                        //     sound: 'default'
                        // },
                        data: {
                            'dp': message['DP'],
                            'titleMultilang': multiLangNotifMap['niac'],
                            'bodyMultilang': multiLangNotifMap['aorc'],
                            'title': 'Incoming Audio Call...',
                            'body': 'Accept / Reject the Call',
                            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
                        }

                    }
                    var options = {
                        priority: 'high',
                        contentAvailable: true,

                    };

                }
            } else {
                //----Non - multiLang Call Notification --------------------------------------------------------------------------------
                if (message['ISVIDEOCALL'] == true) {
                    payload = {
                        //  Disabled the notification property so that onbackgroundmessage can be triggered--------
                        // notification: {
                        //     title: 'Incoming Video Call...',
                        //     body: 'Accept / Reject the Call',
                        //     click_action: 'FLUTTER_NOTIFICATION_CLICK',
                        //     priority: 'high',
                        //     sound: 'default'
                        // },
                        data: {
                            'dp': message['DP'],
                            'titleMultilang': 'Incoming Video Call...',
                            'bodyMultilang': 'Accept / Reject the Call',
                            'title': 'Incoming Video Call...',
                            'body': 'Accept / Reject the Call',
                            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
                        }

                    }
                    var options = {
                        priority: 'high',
                        contentAvailable: true,

                    };
                } else {
                    payload = {
                        //  Disabled the notification property so that onbackgroundmessage can be triggered--------
                        // notification: {
                        //     title: 'Incoming Audio Call...',
                        //     body: 'Accept / Reject the Call',
                        //     click_action: 'FLUTTER_NOTIFICATION_CLICK',
                        //     priority: 'high',
                        //     sound: 'default'
                        // },
                        data: {
                            'dp': message['DP'],
                            'titleMultilang': 'Incoming Audio Call...',
                            'bodyMultilang': 'Accept / Reject the Call',
                            'title': 'Incoming Audio Call...',
                            'body': 'Accept / Reject the Call',
                            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
                        }

                    }
                    var options = {
                        priority: 'high',
                        contentAvailable: true,

                    };

                }

            }
            // Send notifications to all tokens.
            const response = await admin.messaging().sendToDevice(tokens, payload, options);
            // For each message check if there was an error.
            const tokensToRemove = [];
            response.results.forEach((result, index) => {
                const error = result.error;
                if (error) {
                    console.error('Failure sending notification to', tokens[index], error);
                    // Cleanup the tokens who are not registered anymore.
                    if (error.code === 'messaging/invalid-registration-token' ||
                        error.code === 'messaging/registration-token-not-registered') {
                        tokensToRemove.push(tokens[index]);
                    }
                }
            });
            return recipient.ref.update({
                notificationTokens: tokens.filter((token) => !tokensToRemove.includes(token))
            });
        }
    });

exports.callRejectedFirstTime = functions.firestore.document('/users/{userId}/recent/callended')
    .onCreate(async(snap, context) => {
        const message = snap.data();

        // if (message['TYPE'] === 'OUTGOING') {
        //     return console.log('Skipped Notification as it is Outgoing Call.');
        // } else {


        // Get the list of device notification tokens.
        const getRecipientPromise = admin.firestore().collection('users').doc(message['id']).get();

        // The snapshot to the user's tokens.
        let recipient;
        let isMultilangNotificationEnabled;
        let multiLangNotifMap;
        // The array containing all the user's tokens.
        let tokens;

        const results = await Promise.all([getRecipientPromise]);

        recipient = results[0];


        tokens = recipient.data().notificationTokens || [];
        isMultilangNotificationEnabled = recipient.data().isMultiLangNotifEnabled || false;
        multiLangNotifMap = recipient.data().notificationsMap || {};
        // Check if there are any device tokens.
        if (tokens.length === 0) {
            return console.log('There are no notification tokens to send to.');
        }
        let payload;
        // Notification details.
        if (isMultilangNotificationEnabled == true) {
            //----MultiLang Call Rejected  Notification --------------------------------------------------------------------------------
            payload = {
                notification: {
                    title: multiLangNotifMap['cr'],
                    body: 'Incoming Call ended',
                    click_action: 'FLUTTER_NOTIFICATION_CLICK',
                    priority: "high",
                    sound: 'default'

                },

                data: {
                    "titleMultilang": multiLangNotifMap['cr'],
                    "bodyMultilang": 'Incoming Call ended',
                    "title": 'Call Ended',
                    "body": 'Incoming Call ended',
                    "click_action": "FLUTTER_NOTIFICATION_CLICK",
                },
            }
        } else {
            //----Non - multiLang Call Rejected Notification --------------------------------------------------------------------------------
            payload = {
                notification: {
                    title: 'Call Ended',
                    body: 'Incoming Call ended',
                    click_action: 'FLUTTER_NOTIFICATION_CLICK',
                    priority: "high",
                    sound: 'default'

                },

                data: {
                    "titleMultilang": 'Call Ended',
                    "bodyMultilang": 'Incoming Call ended',
                    "title": 'Call Ended',
                    "body": 'Incoming Call ended',
                    "click_action": "FLUTTER_NOTIFICATION_CLICK",


                },
            }



        }
        var options = {
            priority: 'high',
            contentAvailable: true,

        };



        // Send notifications to all tokens.
        const response = await admin.messaging().sendToDevice(tokens, payload, options);
        // For each message check if there was an error.
        const tokensToRemove = [];
        response.results.forEach((result, index) => {
            const error = result.error;
            if (error) {
                console.error('Failure sending notification to', tokens[index], error);
                // Cleanup the tokens who are not registered anymore.
                if (error.code === 'messaging/invalid-registration-token' ||
                    error.code === 'messaging/registration-token-not-registered') {
                    tokensToRemove.push(tokens[index]);
                }
            }
        });
        return recipient.ref.update({
            notificationTokens: tokens.filter((token) => !tokensToRemove.includes(token))
        });
        // }
    });





exports.callRejectedNotFirstTime = functions.firestore.document('/users/{userId}/recent/callended')
    .onUpdate(async(change, context) => {
        const message = change.after.data();

        // if (message['TYPE'] === 'OUTGOING') {
        //     return console.log('Skipped Notification as it is Outgoing Call.');
        // } else {


        // Get the list of device notification tokens.
        const getRecipientPromise = admin.firestore().collection('users').doc(message['id']).get();

        // The snapshot to the user's tokens.
        let recipient;
        let isMultilangNotificationEnabled;
        let multiLangNotifMap;
        // The array containing all the user's tokens.
        let tokens;

        const results = await Promise.all([getRecipientPromise]);

        recipient = results[0];

        tokens = recipient.data().notificationTokens || [];
        isMultilangNotificationEnabled = recipient.data().isMultiLangNotifEnabled || false;
        multiLangNotifMap = recipient.data().notificationsMap || {};
        // Check if there are any device tokens.
        if (tokens.length === 0) {
            return console.log('There are no notification tokens to send to.');
        }
        let payload;
        // Notification details.

        if (isMultilangNotificationEnabled == true) {
            //----MultiLang Call Ended Notification --------------------------------------------------------------------------------
            payload = {
                notification: {
                    title: multiLangNotifMap['ce'],
                    body: 'Incoming Call ended',
                    click_action: 'FLUTTER_NOTIFICATION_CLICK',
                    priority: "high",
                    sound: 'default'

                },

                data: {
                    "titleMultilang": multiLangNotifMap['ce'],
                    "bodyMultilang": 'Incoming Call ended',
                    "title": 'Call Ended',
                    "body": 'Incoming Call ended',
                    "click_action": "FLUTTER_NOTIFICATION_CLICK",
                },
            }
        } else {
            //----Non - multiLang Call Ended  Notification --------------------------------------------------------------------------------
            payload = {
                notification: {
                    title: 'Call Ended',
                    body: 'Incoming Call ended',
                    click_action: 'FLUTTER_NOTIFICATION_CLICK',
                    priority: "high",
                    sound: 'default'

                },

                data: {

                    "titleMultilang": 'Call Ended',
                    "bodyMultilang": 'Incoming Call ended',
                    "title": 'Call Ended',
                    "body": 'Incoming Call ended',
                    "click_action": "FLUTTER_NOTIFICATION_CLICK",


                },
            }



        }

        var options = {
            priority: 'high',
            contentAvailable: true,

        };
        // Send notifications to all tokens.
        const response = await admin.messaging().sendToDevice(tokens, payload, options);
        // For each message check if there was an error.
        const tokensToRemove = [];
        response.results.forEach((result, index) => {
            const error = result.error;
            if (error) {
                console.error('Failure sending notification to', tokens[index], error);
                // Cleanup the tokens who are not registered anymore.
                if (error.code === 'messaging/invalid-registration-token' ||
                    error.code === 'messaging/registration-token-not-registered') {
                    tokensToRemove.push(tokens[index]);
                }
            }
        });
        return recipient.ref.update({
            notificationTokens: tokens.filter((token) => !tokensToRemove.includes(token))
        });
        // }
    });



//  Deploy these cloud functions using Firebase CLI using following command:
//     firebase login
//     firebase deploy --only functions