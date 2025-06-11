import 'package:flutter/material.dart';

enum DateTimeType { date, time, dateTime }

class CustomDateTimePicker extends StatelessWidget {
  final String label;
  final DateTimeType type;
  final String dateTimeString;
  final Function(String) onChanged;
  final IconData icon; // New
  final bool isRequired; // New

  const CustomDateTimePicker({
    Key? key,
    required this.label,
    required this.type,
    required this.dateTimeString,
    required this.onChanged,
    this.icon = Icons.calendar_today, // default icon
    this.isRequired = false,
  }) : super(key: key);

  String _formatDateTime() {
    final dt = DateTime.tryParse(dateTimeString);
    if (dt == null) return '';
    switch (type) {
      case DateTimeType.date:
        return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
      case DateTimeType.time:
        final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
        final minute = dt.minute.toString().padLeft(2, '0');
        final period = dt.hour < 12 ? 'AM' : 'PM';
        return "$hour:$minute $period";
      case DateTimeType.dateTime:
        return dt.toIso8601String();
    }
  }

  void _pick(BuildContext context) async {
    final current = DateTime.tryParse(dateTimeString) ?? DateTime.now();
    if (type == DateTimeType.date || type == DateTimeType.dateTime) {
      final pickedDate = await showDatePicker(
        context: context,
        initialDate: current,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (pickedDate != null) {
        TimeOfDay time = TimeOfDay.fromDateTime(current);
        if (type == DateTimeType.dateTime) {
          time =
              (await showTimePicker(context: context, initialTime: time)) ??
              time;
        }
        final dt = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          time.hour,
          time.minute,
        );
        onChanged(dt.toIso8601String());
      }
    } else if (type == DateTimeType.time) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(current),
      );
      if (pickedTime != null) {
        final dt = DateTime(
          current.year,
          current.month,
          current.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        onChanged(dt.toIso8601String());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      readOnly: true,
      controller: TextEditingController(text: _formatDateTime()),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
      validator:
          isRequired
              ? (value) => dateTimeString.isEmpty ? '$label is required' : null
              : null,
      onTap: () => _pick(context),
    );
  }
}
