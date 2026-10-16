/// The app is free, so there is nothing to sell - only an optional tip jar.
///
/// Everything here is a one-line change: point [donationUrl] at your own page
/// and the Support card in Settings picks it up. While the URL still contains
/// the placeholder, Settings shows a reminder instead of a button that would
/// open a dead page.
///
/// Choosing a platform (fees as of writing):
///
///  * **Ko-fi** - 0% on donations, no account needed to give.
///  * **Buy Me a Coffee** - 5%, but the best-known name.
///  * **GitHub Sponsors** - 0%, best if the project is open source.
///  * **PayPal.me** - ~2.9%, instant, reads less like a product.
class SupportConfig {
  SupportConfig._();

  /// Replace `your-handle` with your own page, for example
  /// `https://ko-fi.com/syedmunawer` or `https://buymeacoffee.com/syedmunawer`.
  static const String donationUrl = 'https://ko-fi.com/your-handle';

  /// Button label. Keep it honest - this unlocks nothing.
  static const String donationLabel = 'Buy me a coffee';

  static const String donationHeadline = 'Support this app';

  static const String donationBlurb =
      'Every country pack is free: all the places, local tips, weather and the '
      'currency converter, with nothing locked and no ads. If it saved you a '
      'roaming bill, a coffee is appreciated but never expected - the app is '
      'complete without it.';

  /// Whether to offer the tip jar on iOS.
  ///
  /// App Review Guideline 3.1.1 restricts linking out to external payment, and
  /// donation links inside iOS apps have been rejected before. The link is
  /// unproblematic on Android. If a reviewer objects, set this to false: the
  /// Support card is then simply hidden on iOS and everything else is unchanged.
  static const bool showDonationLinkOnIos = true;

  /// True while [donationUrl] is still the placeholder.
  static bool get hasPlaceholderUrl => donationUrl.contains('your-handle');
}
