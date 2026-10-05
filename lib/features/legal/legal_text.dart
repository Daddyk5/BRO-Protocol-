import '../../core/constants/app_constants.dart';

/// One titled section of a legal document.
class LegalSection {
  const LegalSection(this.heading, this.body);

  final String heading;
  final String body;
}

enum LegalDoc {
  privacy('PRIVACY POLICY'),
  terms('TERMS OF USE');

  const LegalDoc(this.title);

  final String title;

  List<LegalSection> get sections => switch (this) {
        LegalDoc.privacy => _privacy,
        LegalDoc.terms => _terms,
      };
}

// Plain-language drafts that describe what the app actually does. Have them
// reviewed before a public release, and keep them in sync with the code.
const String legalLastUpdated = 'October 5, 2026';

final List<LegalSection> _privacy = [
  const LegalSection(
    'The short version',
    'Bro Protocol has no accounts, no ads and no tracking. Your history and match notes stay on your device. '
        'Text you choose to send for a reply is used to write that reply and is not kept on our servers.',
  ),
  const LegalSection(
    'What stays on your device',
    'Your saved replies (the last ${AppConstants.historyLimit}), your match names and notes, and your settings are '
        'stored only on this device. Screenshots you scan are read on-device; the image is never uploaded.',
  ),
  const LegalSection(
    'What is sent to write a reply',
    'When you tap Generate, we send: the text in the composer, the mode, tone and language you picked, the notes of '
        'the match you selected (if any), and a random install ID. Nothing is sent until you tap Generate.',
  ),
  const LegalSection(
    'How it is processed',
    'Our server passes that request to an AI model (Anthropic\'s Claude, or a model we host) to write the reply, '
        'and returns it to your device. We do not store the text you send or the replies. Our logs record only the '
        'mode, language and character counts, never the content.',
  ),
  const LegalSection(
    'The install ID',
    'A random ID created on first launch lets us limit how many replies one device can request per hour. It is not '
        'linked to your name, phone number or accounts. Deleting your data in Settings creates a new one.',
  ),
  const LegalSection(
    'Other people\'s messages',
    'The chats you paste contain someone else\'s words. Only share what you need for the reply, and leave out '
        'phone numbers, addresses and anything sensitive.',
  ),
  const LegalSection(
    'Your choices',
    'You can delete single replies in History, remove matches, or erase everything with Settings → Delete all my '
        'data. Uninstalling the app also removes all on-device data.',
  ),
  const LegalSection(
    'Age',
    'Bro Protocol is for adults (18+). We do not knowingly process data from anyone under 18.',
  ),
  const LegalSection(
    'Contact',
    'Questions about privacy: ${AppConstants.supportEmail}',
  ),
];

final List<LegalSection> _terms = [
  const LegalSection(
    'Using Bro Protocol',
    'Bro Protocol suggests messages. It never sends anything for you: you decide what to copy, edit and send. '
        'You must be 18 or older to use it.',
  ),
  const LegalSection(
    'Be respectful',
    'Do not use Bro Protocol to harass, deceive, pressure or threaten anyone, or to write sexual messages to people '
        'who have not invited them. If someone has said no or stopped replying, respect it.',
  ),
  const LegalSection(
    'AI suggestions',
    'Replies are written by an AI model and can be wrong, awkward or not fit your situation. Read every suggestion '
        'before you send it. You are responsible for what you send.',
  ),
  const LegalSection(
    'Fair use',
    'Each device can request a limited number of replies per hour. Automated or bulk use is not allowed.',
  ),
  const LegalSection(
    'No guarantee',
    'Bro Protocol is provided as is. We do not promise any outcome from a conversation, and the service may change '
        'or be unavailable at times.',
  ),
  const LegalSection(
    'Changes',
    'We may update these terms. If the changes are significant, the app will ask you to review them again.',
  ),
  const LegalSection(
    'Contact',
    'Questions about these terms: ${AppConstants.supportEmail}',
  ),
];
