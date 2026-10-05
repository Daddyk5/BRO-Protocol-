import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/bro_logo.dart';
import '../../core/widgets/gradient_button.dart';
import '../legal/legal_text.dart';
import '../settings/providers/settings_provider.dart';

/// First-run walkthrough: what the app does, how your data is handled, and
/// the 18+ / terms agreement. Shown again when the terms version changes.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pages = PageController();
  int _page = 0;
  bool _isAdult = false;
  bool _acceptsTerms = false;

  static const _intro = [
    _IntroPage(
      icon: Icons.bolt_rounded,
      title: 'SAY LESS. SAY IT RIGHT.',
      body: 'Paste her bio or the chat, pick your play, and get replies that sound confident, warm and like you. '
          'Never needy, never cringe.',
    ),
    _IntroPage(
      icon: Icons.touch_app_rounded,
      title: 'YOU STAY IN CONTROL',
      body: 'Bro Protocol never sends anything for you. Pick an option, copy it, tweak it if you want, and send it '
          'yourself.',
    ),
    _IntroPage(
      icon: Icons.lock_outline_rounded,
      title: 'PRIVATE BY DEFAULT',
      body: 'No accounts, no ads. History and match notes stay on this device. Text is only sent when you tap '
          'Generate, and it isn\'t stored on our servers.',
    ),
  ];

  int get _lastPage => _intro.length; // the consent page comes after the intro pages

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _next() => _pages.nextPage(duration: AppMotion.of(context, AppMotion.slow), curve: AppMotion.curve);

  Future<void> _finish() async {
    await ref.read(settingsProvider.notifier).completeOnboarding();
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final onConsent = _page == _lastPage;
    final canFinish = _isAdult && _acceptsTerms;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
              child: Row(
                children: [
                  const BroLogo.full(size: 30),
                  const Spacer(),
                  if (!onConsent)
                    TextButton(
                      onPressed: () => _pages.animateToPage(
                        _lastPage,
                        duration: AppMotion.of(context, AppMotion.slow),
                        curve: AppMotion.curve,
                      ),
                      child: const Text('Skip'),
                    ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pages,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  ..._intro,
                  _ConsentPage(
                    isAdult: _isAdult,
                    acceptsTerms: _acceptsTerms,
                    onAdultChanged: (v) => setState(() => _isAdult = v),
                    onTermsChanged: (v) => setState(() => _acceptsTerms = v),
                    onOpenDoc: (doc) => context.push('/legal/${doc.name}'),
                  ),
                ],
              ),
            ),
            _Dots(count: _lastPage + 1, index: _page),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: GradientButton(
                label: onConsent ? "LET'S GO" : 'NEXT',
                icon: onConsent ? Icons.check_rounded : Icons.arrow_forward_rounded,
                onPressed: onConsent ? (canFinish ? _finish : null) : _next,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroPage extends StatelessWidget {
  const _IntroPage({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 32),
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              gradient: AppColors.gradient,
              shape: BoxShape.circle,
              boxShadow: AppColors.gradientGlow,
            ),
            child: Icon(icon, size: 44, color: AppColors.white),
          ),
          const SizedBox(height: 32),
          Semantics(
            header: true,
            child: Text(title, textAlign: TextAlign.center, style: AppTextStyles.headline),
          ),
          const SizedBox(height: 12),
          Text(body, textAlign: TextAlign.center, style: AppTextStyles.bodyMuted),
        ],
      ),
    );
  }
}

class _ConsentPage extends StatelessWidget {
  const _ConsentPage({
    required this.isAdult,
    required this.acceptsTerms,
    required this.onAdultChanged,
    required this.onTermsChanged,
    required this.onOpenDoc,
  });

  final bool isAdult;
  final bool acceptsTerms;
  final ValueChanged<bool> onAdultChanged;
  final ValueChanged<bool> onTermsChanged;
  final ValueChanged<LegalDoc> onOpenDoc;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Semantics(header: true, child: Text('BEFORE WE START', style: AppTextStyles.headline)),
          const SizedBox(height: 8),
          Text(
            '${AppConstants.appName} is a coach, not an autopilot. Keep it respectful, and if she says no, '
            'take the hint.',
            style: AppTextStyles.bodyMuted,
          ),
          const SizedBox(height: 24),
          Card(
            child: Column(
              children: [
                CheckboxListTile(
                  value: isAdult,
                  onChanged: (v) => onAdultChanged(v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('I am 18 or older'),
                ),
                const Divider(height: 1),
                CheckboxListTile(
                  value: acceptsTerms,
                  onChanged: (v) => onTermsChanged(v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('I agree to the Terms of Use and have read the Privacy Policy'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton(onPressed: () => onOpenDoc(LegalDoc.terms), child: const Text('Read the terms')),
              TextButton(onPressed: () => onOpenDoc(LegalDoc.privacy), child: const Text('Read the privacy policy')),
            ],
          ),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Step ${index + 1} of $count',
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: AppMotion.of(context, AppMotion.normal),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: i == index ? 22 : 8,
              height: 8,
              decoration: BoxDecoration(
                gradient: i == index ? AppColors.gradient : null,
                color: i == index ? null : AppColors.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
        ],
      ),
    );
  }
}
