# smart_notification_listener

A Flutter plugin for Android that allows your app to **listen to system notifications** and **send replies directly** to supported notifications like WhatsApp, Telegram, etc.

This plugin uses a custom `NotificationListenerService` implemented natively in Kotlin for more reliable and maintainable functionality than older packages.

---

## 🔧 Features

- ✅ Read notifications (title, text, package name, etc.)
- 📤 Send smart replies to compatible notifications
- 🚀 Custom implementation — not dependent on unmaintained packages
- 🔐 Does **not** require intrusive permissions — just Notification Access

---

## 📦 Installation

In your `pubspec.yaml`:

```yaml
dependencies:
  smart_notification_listener:
    path: ../smart_notification_listener  # Use path for local testing or replace with Git URL
