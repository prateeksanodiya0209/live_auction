import 'dart:async';
import 'package:flutter/material.dart';
import 'package:live_auction/core/constants/app_colors.dart';

class CountdownTimerWidget extends StatefulWidget {
  final DateTime? endTime;
  final String status;
  final bool compact;

  const CountdownTimerWidget({
    super.key,
    required this.endTime,
    this.status = 'live',
    this.compact = false,
  });

  @override
  State<CountdownTimerWidget> createState() => _CountdownTimerWidgetState();
}

class _CountdownTimerWidgetState extends State<CountdownTimerWidget> {
  Timer? _timer;
  Duration _remainingTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _calculateRemainingTime();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant CountdownTimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.endTime != widget.endTime) {
      _calculateRemainingTime();
    }
  }

  void _calculateRemainingTime() {
    if (widget.endTime == null) {
      _remainingTime = Duration.zero;
      return;
    }
    final now = DateTime.now();
    final difference = widget.endTime!.difference(now);
    if (difference.isNegative) {
      _remainingTime = Duration.zero;
    } else {
      _remainingTime = difference;
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _calculateRemainingTime();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    if (duration.inSeconds <= 0) return '00:00:00';
    final days = duration.inDays;
    final hours = duration.inHours.remainder(24).toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');

    if (days > 0) {
      return '${days}d ${hours}h ${minutes}m ${seconds}s';
    }
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final isEnded = widget.status == 'ended' || _remainingTime == Duration.zero;
    final isUpcoming = widget.status == 'upcoming';

    if (widget.compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isEnded
              ? AppColors.error.withValues(alpha: 0.2)
              : isUpcoming
                  ? AppColors.warning.withValues(alpha: 0.2)
                  : AppColors.primary.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isEnded
                ? AppColors.error
                : isUpcoming
                    ? AppColors.warning
                    : AppColors.primary,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isEnded ? Icons.timer_off_outlined : Icons.timer_outlined,
              size: 14,
              color: isEnded
                  ? AppColors.error
                  : isUpcoming
                      ? AppColors.warning
                      : AppColors.primary,
            ),
            const SizedBox(width: 4),
            Text(
              isEnded ? 'ENDED' : _formatDuration(_remainingTime),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isEnded
                    ? AppColors.error
                    : isUpcoming
                        ? AppColors.warning
                        : AppColors.primary,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isEnded
                        ? AppColors.error
                        : isUpcoming
                            ? AppColors.warning
                            : AppColors.success,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    isEnded
                        ? 'AUCTION ENDED'
                        : isUpcoming
                            ? 'STARTS IN'
                            : 'ENDS IN',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                isEnded ? 'Completed' : _formatDuration(_remainingTime),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  color: isEnded
                      ? AppColors.error
                      : isUpcoming
                          ? AppColors.warning
                          : AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
