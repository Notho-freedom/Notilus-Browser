import 'dart:async';
import 'package:flutter/material.dart';

/// Classe pour débouncer les callbacks et éviter les updates trop fréquentes
class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void dispose() {
    _timer?.cancel();
  }
}

