/// Widget autonome pour afficher l'heure
library time_display_widget;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:async';

/// Widget autonome pour afficher l'heure
class TimeDisplayWidget extends StatefulWidget {
  final Color? textColor;
  final bool showSeconds;
  final bool showDate;
  final String? timezone;

  const TimeDisplayWidget({
    super.key,
    this.textColor,
    this.showSeconds = true,
    this.showDate = false,
    this.timezone,
  });

  @override
  State<TimeDisplayWidget> createState() => _TimeDisplayWidgetState();
}

class _TimeDisplayWidgetState extends State<TimeDisplayWidget> {
  String _currentTime = '';
  String _currentDate = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _startClock();
  }

  void _startClock() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _updateTime();
      } else {
        timer.cancel();
      }
    });
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      if (widget.showSeconds) {
        _currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
      } else {
        _currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      }
      
      if (widget.showDate) {
        final weekdays = ['Dimanche', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi'];
        final months = ['janvier', 'février', 'mars', 'avril', 'mai', 'juin', 
                        'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'];
        _currentDate = '${weekdays[now.weekday % 7]}, ${now.day} ${months[now.month - 1]}';
      }
      
      if (widget.timezone != null) {
        _currentTime += ' ${widget.timezone}';
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.textColor ?? Colors.white;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              CupertinoIcons.clock,
              size: 14,
              color: textColor.withOpacity(0.7),
            ),
            const SizedBox(width: 8),
            Text(
              _currentTime,
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: widget.showSeconds ? 11 : 14,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ],
        ),
        if (widget.showDate && _currentDate.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            _currentDate,
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 10,
              color: textColor.withOpacity(0.7),
            ),
          ),
        ],
      ],
    );
  }
}

