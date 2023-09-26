import 'package:drive_fit/theme/color_schemes.g.dart';
import 'package:flutter/material.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import '../service/database_service.dart';
import '../service/navigation.dart';
import 'home_page.dart';
import '/global_variables.dart' as globals;

import 'package:localization/localization.dart';

class LoginPage extends StatelessWidget {
  LoginPage({super.key});
  final DatabaseService databaseService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    ProfileScreen profileScreen = ProfileScreen(
      appBar: AppBar(
        title: Text(
          "your-profile".i18n(),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        centerTitle: true,
      ),
      actions: [
        SignedOutAction((context) {
          globals.hasSignedIn = false;
          databaseService.updateUserProfile();
          showSnackBar("signed-out".i18n());
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => const HomePage()));
        })
      ],
    );

    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Container(
          color: lightColorScheme.background,
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(),
                Icon(
                  Icons.login_outlined,
                  size: 69,
                  color: lightColorScheme.primary,
                ),
                Text(
                  "register-and-sign-in".i18n(),
                  style: Theme.of(context).textTheme.displaySmall,
                  textAlign: TextAlign.center,
                ),
                Text(
                  "to-connect-to-company".i18n(),
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                Text(
                  "so-you-can-let-company-know".i18n(),
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                FilledButton(
                  style: FilledButton.styleFrom(
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16.0))),
                    minimumSize: const Size.fromHeight(50.0),
                    padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 0),
                  ),
                  onPressed: () {
                    FadeNavigator.push(
                        context,
                        SignInScreen(
                          actions: [
                            EmailLinkSignInAction((context) {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: ((context) =>
                                          EmailLinkSignInScreen(
                                            actions: [
                                              AuthStateChangeAction<SignedIn>(
                                                  (context, state) {
                                                databaseService
                                                    .updateUserProfile();
                                                showSnackBar(
                                                    "signed-in".i18n());
                                                Navigator.pushReplacement(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            const HomePage()));
                                                Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          profileScreen,
                                                    ));
                                              }),
                                            ],
                                          ))));
                            }),
                            AuthStateChangeAction<SignedIn>((context, state) {
                              databaseService.updateUserProfile();
                              showSnackBar("signed-in".i18n());
                              Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const HomePage()));
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => profileScreen,
                                  ));
                            }),
                          ],
                        ),
                        FadeNavigator.opacityTweenSequence,
                        Colors.transparent,
                        const Duration(milliseconds: 500));
                  },
                  child: Text(
                    "go-to-sign-in".i18n(),
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: lightColorScheme.onPrimary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void showSnackBar(String text) {
    var snackBar =
        SnackBar(content: Text(text), duration: const Duration(seconds: 2));
    globals.snackbarKey.currentState?.showSnackBar(snackBar);
  }
}
