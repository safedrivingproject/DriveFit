import 'package:flutter/material.dart';

class FadeNavigator {
  static final opacityTweenSequence = <TweenSequenceItem<double>>[
    TweenSequenceItem<double>(
      tween: ConstantTween<double>(0.0),
      weight: 20.0,
    ),
    TweenSequenceItem<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0)
          .chain(CurveTween(curve: Curves.easeOutExpo)),
      weight: 80.0,
    ),
  ];

  static void pushReplacement(
      BuildContext context,
      Widget page,
      List<TweenSequenceItem<double>> tweenSequence,
      Color barrierColor,
      Duration transitionDuration) {
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      barrierColor: barrierColor,
      transitionDuration: transitionDuration,
      pageBuilder: (BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation) {
        return page;
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: TweenSequence<double>(tweenSequence).animate(animation),
          child: child,
        );
      },
    ));
  }

  static void push(
      BuildContext context,
      Widget page,
      List<TweenSequenceItem<double>> tweenSequence,
      Color barrierColor,
      Duration transitionDuration) {
    Navigator.of(context).push(PageRouteBuilder(
      barrierColor: barrierColor,
      transitionDuration: transitionDuration,
      pageBuilder: (BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation) {
        return page;
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: TweenSequence<double>(tweenSequence).animate(animation),
          child: child,
        );
      },
    ));
  }
}
