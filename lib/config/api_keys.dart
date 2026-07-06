/// API keys for third-party services used by the app.
///
/// IMPORTANT — SECURITY NOTE:
/// This key is bundled inside the app, which means anyone who
/// decompiles the app could extract it. That's an acceptable
/// trade-off for a personal project / learning app, but before
/// publishing this app publicly (Play Store, App Store, or sharing
/// the APK), move this key behind a backend (e.g. a Firebase Cloud
/// Function) so it's never shipped inside the client.
///
/// Get your free Gemini API key from: https://aistudio.google.com/apikey
/// (No credit card required.)
///
/// If you plan to push this project to GitHub, add this file to
/// .gitignore so your key isn't committed publicly.
class ApiKeys {
  static const String geminiApiKey =
      '<YOUR_GEMINI_API_KEY>'; // Replace with your actual Gemini API key
}
