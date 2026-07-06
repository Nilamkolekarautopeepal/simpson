import 'package:simpson/themes/app_textstyles.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DatePickerField extends StatefulWidget {
  final bool isRangePicker;
  final bool extractSingleDateFromRange;
  final DateTime firstDate;
  final DateTime lastDate;
  final String label;
  final Function(DateTime)? onDateSelected;
  final Function(DateTimeRange)? onRangeSelected;
  final TextEditingController? controller;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;

  const DatePickerField({
    super.key,
    required this.isRangePicker,
    this.extractSingleDateFromRange = false,
    required this.firstDate,
    required this.lastDate,
    required this.label,
    this.onDateSelected,
    this.onRangeSelected,
    this.controller,
    this.labelStyle,
    this.valueStyle,
  });

  @override
  State<DatePickerField> createState() => _DatePickerFieldState();
}

class _DatePickerFieldState extends State<DatePickerField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
  }

  Future<void> _selectDate(BuildContext context) async {
    if (widget.isRangePicker) {
      final picked = await showDateRangePicker(
        context: context,
        firstDate: widget.firstDate,
        lastDate: widget.lastDate,
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(primary: Colors.blue),
            ),
            child: child!,
          );
        },
      );

      if (picked != null) {
        if (widget.extractSingleDateFromRange) {
          DateTime singleDate = picked.start;
          _controller.text = DateFormat('dd-MM-yyyy').format(singleDate);
          widget.onDateSelected?.call(singleDate);
        } else {
          String rangeText =
              '${DateFormat('dd-MM-yyyy').format(picked.start)} to ${DateFormat('dd-MM-yyyy').format(picked.end)}';
          _controller.text = rangeText;
          widget.onRangeSelected?.call(picked);
        }
      }
    } else {
      final picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: widget.firstDate,
        lastDate: widget.lastDate,
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(primary: Colors.blue),
            ),
            child: child!,
          );
        },
      );

      if (picked != null) {
        _controller.text = DateFormat('dd-MM-yyyy').format(picked);
        widget.onDateSelected?.call(picked);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: AbsorbPointer(
        child: TextFormField(
          controller: _controller,
          style: widget.valueStyle ??
              const TextStyle(fontSize: 14, color: Colors.black87),
          decoration: InputDecoration(
            labelText: widget.label,
            labelStyle: widget.labelStyle,
            suffixIcon: const Icon(Icons.calendar_today),
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey, width: 0.0),
            ),
            disabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey, width: 0.0),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey, width: 0.0),
            ),
            focusedErrorBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey, width: 0.0),
            ),
            errorBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.red, width: 0.0),
            ),
          ),
          readOnly: true,
        ),
      ),
    );
  }
}

class RequiredLabel extends StatelessWidget {
  final String label;
  final bool isRequired;
  final TextStyle? style;

  const RequiredLabel({
    super.key,
    required this.label,
    this.isRequired = false,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(text: label, style: TextStyles.labelStyle, children: [
        if (isRequired)
          TextSpan(
            text: " *",
            style: TextStyles.labelStyle.copyWith(
              color: Colors.red,
            ),
          )
      ]),
    );
  }
}
