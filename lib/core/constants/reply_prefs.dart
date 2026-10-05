import 'package:flutter/material.dart';

/// The user's standing style preferences, sent with every request.
class ReplyPrefs {
  const ReplyPrefs({this.allowEmoji = true, this.short = false, this.style = ''});

  final bool allowEmoji;

  /// One short sentence instead of up to two.
  final bool short;

  /// How the user texts, in their own words.
  final String style;

  Map<String, dynamic> toJson() => {
        'emoji': allowEmoji,
        if (short) 'short': true,
        if (style.trim().isNotEmpty) 'style': style.trim(),
      };
}

/// One-tap rewrites of a reply. [apiValue] matches the backend's TWEAKS.
enum ReplyTweak {
  shorter('SHORTER', 'Shorter', Icons.short_text_rounded),
  funnier('FUNNIER', 'Funnier', Icons.sentiment_very_satisfied_rounded),
  bolder('BOLDER', 'Bolder', Icons.local_fire_department_rounded),
  softer('SOFTER', 'Softer', Icons.favorite_border_rounded),
  addQuestion('ADD_QUESTION', '+ Question', Icons.help_outline_rounded);

  const ReplyTweak(this.apiValue, this.label, this.icon);

  final String apiValue;
  final String label;
  final IconData icon;
}
