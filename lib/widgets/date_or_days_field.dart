import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DateOrDaysField extends StatefulWidget {
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;

  const DateOrDaysField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  State<DateOrDaysField> createState() => _DateOrDaysFieldState();
}

class _DateOrDaysFieldState extends State<DateOrDaysField> {
  final _daysCtrl = TextEditingController();
  bool _daysEditing = false;

  static const _quickDays = [7, 14, 30, 60, 90];

  @override
  void dispose() {
    _daysCtrl.dispose();
    super.dispose();
  }

  void _setDays(int days) {
    final date = DateTime.now().add(Duration(days: days));
    widget.onChanged(date);
    setState(() {
      _daysCtrl.text = days.toString();
      _daysEditing = false;
    });
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.value ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      widget.onChanged(picked);
      final diff = picked.difference(DateTime.now()).inDays;
      setState(() => _daysCtrl.text = diff.toString());
    }
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  int? get _currentDays {
    final v = widget.value;
    if (v == null) return null;
    return v.difference(DateTime.now()).inDays + 1;
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).primaryColor;
    final hasDate = widget.value != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date picker button
        OutlinedButton.icon(
          onPressed: _pickDate,
          icon: const Icon(Icons.calendar_today_outlined),
          label: Text(hasDate
              ? 'Möhleti: ${_fmt(widget.value!)}'
              : 'Möhletini saýlaň'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            foregroundColor: hasDate ? color : null,
            side: hasDate ? BorderSide(color: color) : null,
          ),
        ),
        const SizedBox(height: 10),

        // Quick day chips
        Row(
          children: [
            Text('Gün:',
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500)),
            const SizedBox(width: 8),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _quickDays.map((d) {
                    final selected = _currentDays != null &&
                        (_currentDays! - d).abs() <= 1 &&
                        !_daysEditing;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text('$d'),
                        selected: selected,
                        onSelected: (_) => _setDays(d),
                        selectedColor: color.withValues(alpha: 0.15),
                        labelStyle: TextStyle(
                          color: selected ? color : Colors.grey[700],
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 13,
                        ),
                        side: BorderSide(
                          color: selected
                              ? color
                              : Colors.grey[300]!,
                        ),
                        backgroundColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Custom days input
        Row(
          children: [
            SizedBox(
              width: 80,
              child: TextField(
                controller: _daysCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: '...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: color),
                  ),
                ),
                onChanged: (v) {
                  final n = int.tryParse(v);
                  if (n != null && n > 0) {
                    setState(() => _daysEditing = true);
                    widget.onChanged(
                        DateTime.now().add(Duration(days: n)));
                  }
                },
                onSubmitted: (_) => setState(() => _daysEditing = false),
              ),
            ),
            const SizedBox(width: 8),
            Text('gün',
                style: TextStyle(
                    fontSize: 14, color: Colors.grey[600])),
            if (hasDate && _daysCtrl.text.isNotEmpty) ...[
              const SizedBox(width: 12),
              Text(
                '→ ${_fmt(widget.value!)}',
                style: TextStyle(
                    fontSize: 13,
                    color: color,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
