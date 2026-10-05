import 'package:flutter/material.dart';

import '../../core/theme/app_text_styles.dart';
import 'legal_text.dart';

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.doc});

  final LegalDoc doc;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(doc.title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            Text('Last updated $legalLastUpdated', style: AppTextStyles.caption),
            for (final section in doc.sections) ...[
              const SizedBox(height: 20),
              Semantics(header: true, child: Text(section.heading.toUpperCase(), style: AppTextStyles.title)),
              const SizedBox(height: 6),
              Text(section.body, style: AppTextStyles.bodyMuted),
            ],
          ],
        ),
      ),
    );
  }
}
