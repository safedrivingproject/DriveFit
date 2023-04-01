import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import '/main.dart';
import '/theme/color_schemes.g.dart';

class NotificationController {
  static ReceivedAction? initialAction;

  //Initializations
  static Future<void> initializeLocalNotifications() async {
    await AwesomeNotifications().initialize(
        'resource://drawable/res_logo_transparent_dark',
        [
          NotificationChannel(
              channelKey: 'drivefit_alerts',
              channelName: 'DriveFit Alerts',
              channelDescription:
                  'Notification channel for driving alerts from DriveFit',
              playSound: true,
              groupAlertBehavior: GroupAlertBehavior.All,
              importance: NotificationImportance.Max,
              defaultPrivacy: NotificationPrivacy.Public,
              defaultColor: lightColorScheme.primary,
              ledColor: Colors.red),
          NotificationChannel(
              channelKey: 'foreground_service',
              channelName: 'DriveFit Service',
              channelDescription:
                  'Notification channel for the foreground services.',
              playSound: true,
              groupAlertBehavior: GroupAlertBehavior.All,
              importance: NotificationImportance.Default,
              defaultPrivacy: NotificationPrivacy.Public,
              defaultColor: lightColorScheme.primary,
              ledColor: Colors.blue,
              locked: true)
        ],
        debug: true);

    // Get initial notification action is optional
    initialAction = await AwesomeNotifications()
        .getInitialNotificationAction(removeFromActionEvents: false);
  }

  ///  *********************************************
  ///     NOTIFICATION EVENTS LISTENER
  ///  *********************************************
  ///  Notifications events are only delivered after call this method
  static Future<void> startListeningNotificationEvents() async {
    AwesomeNotifications()
        .setListeners(onActionReceivedMethod: onActionReceivedMethod);
  }

  ///  *********************************************
  ///     NOTIFICATION EVENTS
  ///  *********************************************
  ///
  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(
      ReceivedAction receivedAction) async {
    MyApp.navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/notification-page',
      (route) => (route.settings.name != '/notification-page') || route.isFirst,
      arguments: receivedAction,
    );
  }

  ///  *********************************************
  ///     REQUESTING NOTIFICATION PERMISSIONS
  ///  *********************************************
  ///
  static Future<bool> displayNotificationRationale() async {
    bool userAuthorized = false;
    BuildContext context = MyApp.navigatorKey.currentContext!;
    await showDialog(
        context: context,
        builder: (BuildContext ctx) {
          return AlertDialog(
            title: Text('Get Notified!',
                style: Theme.of(context).textTheme.titleLarge),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                SizedBox(height: 20),
                Text(
                    'Allow Awesome Notifications to send you beautiful notifications!'),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                  },
                  child: Text(
                    'Deny',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(color: Colors.red),
                  )),
              TextButton(
                  onPressed: () async {
                    userAuthorized = true;
                    Navigator.of(ctx).pop();
                  },
                  child: Text(
                    'Allow',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(color: Colors.deepPurple),
                  )),
            ],
          );
        });
    return userAuthorized &&
        await AwesomeNotifications().requestPermissionToSendNotifications();
  }

  ///  *********************************************
  ///     NOTIFICATION CREATION METHODS
  ///  *********************************************
  ///
  static Future<void> createSleepyNotification() async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      AwesomeNotifications().requestPermissionToSendNotifications();
      return;
    }

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: -1,
        channelKey: 'drivefit_alerts',
        title: 'Drive Safely!',
        body: "Wanna park and take a nap?",
        notificationLayout: NotificationLayout.Default,
        wakeUpScreen: true,
        fullScreenIntent: true,
        criticalAlert: true,
        actionType: ActionType.DisabledAction,
      ),
    );
  }

  static Future<void> createDistractedNotification() async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) isAllowed = await displayNotificationRationale();
    if (!isAllowed) return;

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: -1,
        channelKey: 'drivefit_alerts',
        title: 'Drive Safely!',
        body: "Keep your eyes on the road!",
        notificationLayout: NotificationLayout.Default,
        wakeUpScreen: true,
        fullScreenIntent: true,
        criticalAlert: true,
        actionType: ActionType.DisabledAction,
      ),
    );
  }

  static Future<void> resetBadgeCounter() async {
    await AwesomeNotifications().resetGlobalBadge();
  }

  static Future<void> dismissAlertNotifications() async {
    await AwesomeNotifications()
        .dismissNotificationsByChannelKey('drivefit_alerts');
  }
}
