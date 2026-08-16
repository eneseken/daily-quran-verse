import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// The two legal links the app is required to surface — shared by the
/// paywall and the profile screen so they can never drift out of sync.
///
/// Apple requires the standard EULA to be linked wherever a subscription is
/// sold; the privacy policy is required on both stores.
const legalTermsUrl =
    'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';
const legalPrivacyUrl = 'https://sites.google.com/view/quran-verse/home';

/// Whether the Terms link should be shown at all — Apple's standard EULA is
/// an iOS-specific requirement, Android has no equivalent.
bool shouldShowLegalTerms(BuildContext context) =>
    Theme.of(context).platform == TargetPlatform.iOS;

/// The URL a "Terms of Use" tap should open. Apple's standard EULA on iOS;
/// Android has no equivalent page, so it falls back to the privacy policy
/// rather than dead-ending on a row with no content behind it.
String legalTermsUrlFor(BuildContext context) =>
    shouldShowLegalTerms(context) ? legalTermsUrl : legalPrivacyUrl;

Future<void> openLegalUrl(String url) =>
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

Future<void> openFeedbackMail() => launchUrl(
  Uri(
    scheme: 'mailto',
    path: 'eneseken065@gmail.com',
    queryParameters: {'subject': 'Daily Quran Verse Feedback'},
  ),
  mode: LaunchMode.externalApplication,
);
