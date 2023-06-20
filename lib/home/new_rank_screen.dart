import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:confetti/confetti.dart';
import 'package:drive_fit/home/home_page.dart';
import 'package:drive_fit/theme/color_schemes.g.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../service/navigation.dart';
import '/service/rank_list.dart';

import '/theme/custom_color.g.dart';

import 'package:localization/localization.dart';

class NewRankScreen extends StatefulWidget {
  const NewRankScreen({
    super.key,
    required this.rankIndex,
  });

  final int rankIndex;

  @override
  State<NewRankScreen> createState() => _NewRankScreenState();
}

class _NewRankScreenState extends State<NewRankScreen>
    with TickerProviderStateMixin {
  String rankName = "Toyota";

  late final AnimationController _animationController = AnimationController(
    duration: const Duration(milliseconds: 1500),
    vsync: this,
  );
  late Animation<double> animation;

  final Animatable<double> levelUpTweenSequence =
      TweenSequence<double>(<TweenSequenceItem<double>>[
    TweenSequenceItem<double>(
      tween: ConstantTween<double>(1.0),
      weight: 20.0,
    ),
    TweenSequenceItem<double>(
      tween: Tween<double>(begin: 1.0, end: 1.2)
          .chain(CurveTween(curve: Curves.linear)),
      weight: 20.0,
    ),
    TweenSequenceItem<double>(
      tween: Tween<double>(begin: 1.2, end: 1.0)
          .chain(CurveTween(curve: Curves.linear)),
      weight: 20.0,
    ),
    TweenSequenceItem<double>(
      tween: Tween<double>(begin: 1.0, end: 1.2)
          .chain(CurveTween(curve: Curves.linear)),
      weight: 20.0,
    ),
    TweenSequenceItem<double>(
      tween: Tween<double>(begin: 1.2, end: 1.0)
          .chain(CurveTween(curve: Curves.linear)),
      weight: 20.0,
    ),
  ]);

  late ConfettiController _confettiControllerBottomLeft;
  late ConfettiController _confettiControllerBottomRight;

  @override
  void initState() {
    super.initState();
    rankName = rankList[widget.rankIndex]["name"];
    _confettiControllerBottomLeft =
        ConfettiController(duration: const Duration(seconds: 5));
    _confettiControllerBottomRight =
        ConfettiController(duration: const Duration(seconds: 5));
    animation = levelUpTweenSequence.animate(_animationController);
    _animationController.forward();
    _confettiControllerBottomLeft.play();
    _confettiControllerBottomRight.play();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _confettiControllerBottomLeft.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sourceXanthous =
        Theme.of(context).extension<CustomColors>()!.sourceXanthous;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            color: lightColorScheme.surfaceVariant,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: kToolbarHeight),
                Container(
                  padding:
                      const EdgeInsetsDirectional.symmetric(horizontal: 28),
                  width: MediaQuery.of(context).size.width,
                  child: Align(
                    alignment: const AlignmentDirectional(0, 0),
                    child: Text(
                      "congrats".i18n(),
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .displayMedium
                          ?.copyWith(color: lightColorScheme.primary),
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsetsDirectional.symmetric(horizontal: 28),
                  width: MediaQuery.of(context).size.width,
                  child: Align(
                    alignment: const AlignmentDirectional(0, 0),
                    child: Text(
                      "you-leveled-up".i18n(),
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(color: lightColorScheme.primary),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(0, 7, 0, 14),
                  child: Text(
                    "your-rank".i18n(),
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(color: lightColorScheme.primary),
                  ),
                ),
                AnimatedCarImage(
                    animation: animation,
                    customColor: sourceXanthous,
                    rankName: rankName),
                AutoSizeText(
                  rankName,
                  style: Theme.of(context)
                      .textTheme
                      .displaySmall
                      ?.copyWith(color: lightColorScheme.primary),
                  maxLines: 1,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(0, 4, 0, 0),
                      child: Text(
                        "> ${rankList[widget.rankIndex]["requiredScore"]} ",
                        style: Theme.of(context)
                            .textTheme
                            .displaySmall
                            ?.copyWith(fontSize: 32),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(0, 8, 0, 0),
                      child: Icon(
                        Icons.star_rounded,
                        color: sourceXanthous,
                        size: 24,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.all(Radius.circular(16.0))),
                      backgroundColor: lightColorScheme.primary,
                      minimumSize: const Size.fromHeight(50),
                    ),
                    onPressed: () {
                      FadeNavigator.pushReplacement(
                          context,
                          const HomePage(index: 2),
                          FadeNavigator.opacityTweenSequence,
                          lightColorScheme.primary,
                          const Duration(milliseconds: 1500));
                    },
                    child: Text(
                      "yay".i18n(),
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(color: lightColorScheme.onPrimary),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: ConfettiWidget(
              confettiController: _confettiControllerBottomLeft,
              blastDirection: (-pi / 2) + (pi / 6),
              maxBlastForce: 100,
              minBlastForce: 80,
              emissionFrequency: 0.5,
              numberOfParticles: 2,
              gravity: 0.3,
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: ConfettiWidget(
              confettiController: _confettiControllerBottomRight,
              blastDirection: (-pi / 2) - (pi / 6),
              maxBlastForce: 100,
              minBlastForce: 80,
              emissionFrequency: 0.5,
              numberOfParticles: 2,
              gravity: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedCarImage extends AnimatedWidget {
  const AnimatedCarImage({
    super.key,
    required Animation<double> animation,
    required this.customColor,
    required this.rankName,
  }) : super(listenable: animation);

  final Color? customColor;
  final String rankName;

  @override
  Widget build(BuildContext context) {
    final animation = listenable as Animation<double>;
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 28),
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height * 0.5,
      child: Align(
        alignment: Alignment.center,
        child: CircularPercentIndicator(
          circularStrokeCap: CircularStrokeCap.round,
          radius: animation.value * MediaQuery.of(context).size.width * 0.3,
          lineWidth: 20.0,
          percent: 1.0,
          center: Container(
            width: MediaQuery.of(context).size.width * 0.5,
            height: MediaQuery.of(context).size.width * 0.5,
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
            ),
            child: Image(
              image: AssetImage("./assets/cars/$rankName.png"),
              fit: BoxFit.cover,
              isAntiAlias: true,
            ),
          ),
          progressColor: customColor,
        ),
      ),
    );
  }
}
