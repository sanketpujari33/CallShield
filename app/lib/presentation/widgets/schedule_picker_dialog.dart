import 'package:flutter/material.dart';
import '../../core/theme/signal_ledger_theme.dart';
import '../../domain/models/rule_models.dart';

class SchedulePickerDialog extends StatefulWidget {
  final TimeSchedule initialSchedule;

  const SchedulePickerDialog({super.key, this.initialSchedule = const TimeSchedule()});

  @override
  State<SchedulePickerDialog> createState() => _SchedulePickerDialogState();
}

class _SchedulePickerDialogState extends State<SchedulePickerDialog> {
  late int _daysMask;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  final List<String> _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  void initState() {
    super.initState();
    _daysMask = widget.initialSchedule.daysMask;
    _startTime = TimeOfDay(
      hour: widget.initialSchedule.startHour,
      minute: widget.initialSchedule.startMinute,
    );
    _endTime = TimeOfDay(
      hour: widget.initialSchedule.endHour,
      minute: widget.initialSchedule.endMinute,
    );
  }

  void _toggleDay(int index) {
    setState(() {
      final bit = 1 << index;
      _daysMask ^= bit;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? SignalLedgerTheme.darkCard : SignalLedgerTheme.lightSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? SignalLedgerTheme.darkBorder : SignalLedgerTheme.lightBorder,
        ),
      ),
      title: const Text('Configure Rule Schedule', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Active Days',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (i) {
                final isSelected = (_daysMask & (1 << i)) != 0;
                return InkWell(
                  onTap: () => _toggleDay(i),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? SignalLedgerTheme.cyan
                          : (isDark ? SignalLedgerTheme.darkSurface : SignalLedgerTheme.lightCard),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? SignalLedgerTheme.cyan
                            : (isDark ? SignalLedgerTheme.darkBorder : SignalLedgerTheme.lightBorder),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _dayLabels[i],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.black
                            : (isDark ? SignalLedgerTheme.darkText : SignalLedgerTheme.lightText),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            const Text(
              'Time Window',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final picked = await showTimePicker(context: context, initialTime: _startTime);
                      if (picked != null) setState(() => _startTime = picked);
                    },
                    child: Text('Start: ${_startTime.format(context)}'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final picked = await showTimePicker(context: context, initialTime: _endTime);
                      if (picked != null) setState(() => _endTime = picked);
                    },
                    child: Text('End: ${_endTime.format(context)}'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final schedule = TimeSchedule(
              daysMask: _daysMask,
              startHour: _startTime.hour,
              startMinute: _startTime.minute,
              endHour: _endTime.hour,
              endMinute: _endTime.minute,
            );
            Navigator.of(context).pop(schedule);
          },
          child: const Text('Save Schedule'),
        ),
      ],
    );
  }
}
