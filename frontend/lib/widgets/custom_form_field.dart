import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CustomFormField extends StatefulWidget {
  final String label;
  final IconData icon;
  final String? initialValue;
  final bool isRequired;
  final bool isDateTime; // combined picker
  final bool isDate; // date only picker
  final bool isTime; // time only picker
  final Function(String?)? onSaved;
  final Function(DateTime)? onDateTimeSelected;

  const CustomFormField({
    Key? key,
    required this.label,
    required this.icon,
    this.initialValue,
    this.isRequired = false,
    this.isDateTime = false,
    this.isDate = false,
    this.isTime = false,
    this.onSaved,
    this.onDateTimeSelected,
  }) : assert(
         (isDateTime ? 1 : 0) + (isDate ? 1 : 0) + (isTime ? 1 : 0) <= 1,
         'Only one of isDateTime, isDate, or isTime can be true',
       ),
       super(key: key);

  @override
  _CustomFormFieldState createState() => _CustomFormFieldState();
}

class _CustomFormFieldState extends State<CustomFormField> {
  late TextEditingController _controller;
  DateTime? selectedDateTime;

  @override
  void initState() {
    super.initState();
    selectedDateTime =
        widget.initialValue != null
            ? DateTime.tryParse(widget.initialValue!)
            : null;

    _controller = TextEditingController(text: _formatInitialValue());
  }

  String _formatInitialValue() {
    if (selectedDateTime == null) return '';
    if (widget.isDate) {
      return DateFormat('yyyy-MM-dd').format(selectedDateTime!);
    } else if (widget.isTime) {
      return DateFormat('hh:mm a').format(selectedDateTime!);
    } else if (widget.isDateTime) {
      return DateFormat('yyyy-MM-dd HH:mm').format(selectedDateTime!);
    }
    return widget.initialValue ?? '';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initialDate = selectedDateTime ?? now;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        if (widget.isDate) {
          selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
          );
        } else if (widget.isDateTime) {
          // If combined, keep old time or default to 00:00
          final oldTime = selectedDateTime ?? DateTime(0);
          selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            oldTime.hour,
            oldTime.minute,
          );
          _pickTime(); // chain pick time
          return; // avoid updating controller now
        }
        _controller.text = _formatInitialValue();
        widget.onDateTimeSelected?.call(selectedDateTime!);
      });
    }
  }

  Future<void> _pickTime() async {
    final initialTime =
        selectedDateTime != null
            ? TimeOfDay.fromDateTime(selectedDateTime!)
            : TimeOfDay.now();

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (pickedTime != null) {
      setState(() {
        final date = selectedDateTime ?? DateTime.now();
        selectedDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        _controller.text = _formatInitialValue();
        widget.onDateTimeSelected?.call(selectedDateTime!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPicker = widget.isDate || widget.isTime || widget.isDateTime;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: isPicker ? _controller : null,
        readOnly: isPicker,
        decoration: InputDecoration(
          labelText: widget.label,
          prefixIcon: Icon(widget.icon),
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
            widget.isRequired
                ? (value) =>
                    value == null || value.isEmpty
                        ? '${widget.label} is required'
                        : null
                : null,
        onTap:
            isPicker
                ? () async {
                  if (widget.isDate) {
                    await _pickDate();
                  } else if (widget.isTime) {
                    await _pickTime();
                  } else if (widget.isDateTime) {
                    await _pickDate();
                  }
                }
                : null,
        onSaved: !isPicker ? widget.onSaved : null,
      ),
    );
  }
}
