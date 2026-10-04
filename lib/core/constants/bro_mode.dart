import 'package:flutter/material.dart';

/// The four plays. [apiValue] is what the backend's `[MODE: ...]` flag expects.
enum BroMode {
  opener(
    apiValue: 'OPENER',
    title: 'OPENER',
    description: 'Start the conversation from her profile',
    inputLabel: 'Her bio or interests',
    icon: Icons.bolt_rounded,
  ),
  banter(
    apiValue: 'BANTER',
    title: 'BANTER',
    description: 'Reply to her last message',
    inputLabel: 'Her last message (or the chat)',
    icon: Icons.forum_rounded,
  ),
  moveOffApp(
    apiValue: 'MOVE_OFF_APP',
    title: 'MOVE IT OFF-APP',
    description: 'Get the number or set the date',
    inputLabel: 'The chat so far',
    icon: Icons.local_cafe_rounded,
  ),
  revive(
    apiValue: 'REVIVE',
    title: 'REVIVE',
    description: 'Restart a chat that went quiet',
    inputLabel: 'The last few messages',
    icon: Icons.replay_rounded,
  );

  const BroMode({
    required this.apiValue,
    required this.title,
    required this.description,
    required this.inputLabel,
    required this.icon,
  });

  final String apiValue;
  final String title;
  final String description;
  final String inputLabel;
  final IconData icon;

  static BroMode fromApi(String value) =>
      BroMode.values.firstWhere((m) => m.apiValue == value, orElse: () => BroMode.banter);
}

enum AppLanguage {
  english('english', 'English'),
  taglish('taglish', 'Taglish');

  const AppLanguage(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static AppLanguage fromApi(String? value) =>
      AppLanguage.values.firstWhere((l) => l.apiValue == value, orElse: () => AppLanguage.english);
}

/// Maps the 0..1 slider to a human label (matches the backend's mapping).
String toneLabel(double tone) {
  if (tone < 0.34) return 'Chill';
  if (tone < 0.67) return 'Balanced';
  return 'Bold';
}
