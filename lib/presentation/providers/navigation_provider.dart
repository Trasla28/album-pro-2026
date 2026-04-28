import 'package:flutter_riverpod/flutter_riverpod.dart';

// Single source of truth for the active tab in HomeScreen.
// Can be written by NotificationService to deep-link into a tab.
final selectedHomeTabProvider = StateProvider<int>((ref) => 0);
