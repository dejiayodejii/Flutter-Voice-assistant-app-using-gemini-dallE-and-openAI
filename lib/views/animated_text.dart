import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';

class MyAnimatedText extends StatelessWidget {
  const MyAnimatedText({
    super.key,
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return AnimatedTextKit(
      repeatForever: false,
      displayFullTextOnTap: true,
      totalRepeatCount: 1,

      animatedTexts: [TyperAnimatedText(text)]);
  }
}
