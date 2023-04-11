import 'package:drive_fit/theme/color_schemes.g.dart';
import 'package:flutter/material.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import '../service/database_service.dart';
import 'home_page.dart';
import '/global_variables.dart' as globals;

class LoginPage extends StatelessWidget {
  LoginPage({super.key});
  final DatabaseService databaseService = DatabaseService();

  @override
  Widget build(BuildContext context) {
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
                  "Register & sign in",
                  style: Theme.of(context).textTheme.displaySmall,
                  textAlign: TextAlign.center,
                ),
                Text(
                  "to connect to your company",
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                Text(
                  "so you can let us know your safe driving progress!",
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
                    Navigator.of(context).push(PageRouteBuilder(
                        pageBuilder: (BuildContext context,
                                Animation<double> animation,
                                Animation<double> secondaryAnimation) =>
                            SignInScreen(
                              actions: [
                                AuthStateChangeAction<SignedIn>(
                                    (context, state) {
                                  databaseService.updateUserProfile();
                                  showSnackBar("Signed in!");
                                  Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const HomePage()));
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ProfileScreen(
                                          appBar: AppBar(
                                            title: Text(
                                              "Your Profile",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleLarge,
                                            ),
                                            centerTitle: true,
                                          ),
                                          actions: [
                                            SignedOutAction((context) {
                                              globals.hasSignedIn = false;
                                              databaseService
                                                  .updateUserProfile();
                                              showSnackBar("Signed out!");
                                              Navigator.pushReplacement(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (context) =>
                                                          const HomePage()));
                                            })
                                          ],
                                        ),
                                      ));
                                }),
                              ],
                            ),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                          return FadeTransition(
                            opacity: Tween<double>(begin: 0.0, end: 1.0)
                                .chain(CurveTween(curve: Curves.easeInOutExpo))
                                .animate(animation),
                            child: child,
                          );
                        },
                        transitionDuration: const Duration(milliseconds: 500),
                        reverseTransitionDuration:
                            const Duration(milliseconds: 500)));
                  },
                  child: Text(
                    "Go to Sign in",
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
