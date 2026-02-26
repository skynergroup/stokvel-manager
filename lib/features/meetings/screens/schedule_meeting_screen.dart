import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';

class ScheduleMeetingScreen extends StatefulWidget {
  final String groupId;
  const ScheduleMeetingScreen({super.key, required this.groupId});

  @override
  State<ScheduleMeetingScreen> createState() => _ScheduleMeetingScreenState();
}

class _ScheduleMeetingScreenState extends State<ScheduleMeetingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _linkController = TextEditingController();
  final _agendaController = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);
  bool _isInPerson = true;
  bool _notifyWhatsApp = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _linkController.dispose();
    _agendaController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (time != null) setState(() => _selectedTime = time);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    // TODO: Save meeting to Firestore
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _isLoading = false);
        context.pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Meeting'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextField(
                  label: 'Meeting Title',
                  hint: 'March Monthly Meeting',
                  controller: _titleController,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Required' : null,
                ),
                const Gap(20),
                Text('Date & Time',
                    style: Theme.of(context).textTheme.labelLarge),
                const Gap(8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _pickDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(),
                          child: Text(dateFormat.format(_selectedDate)),
                        ),
                      ),
                    ),
                    const Gap(12),
                    Expanded(
                      child: InkWell(
                        onTap: _pickTime,
                        child: InputDecorator(
                          decoration: const InputDecoration(),
                          child: Text(_selectedTime.format(context)),
                        ),
                      ),
                    ),
                  ],
                ),
                const Gap(20),
                Text('Location',
                    style: Theme.of(context).textTheme.labelLarge),
                const Gap(8),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<bool>(
                        title: const Text('In Person'),
                        value: true,
                        groupValue: _isInPerson,
                        onChanged: (v) =>
                            setState(() => _isInPerson = v ?? true),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<bool>(
                        title: const Text('Virtual'),
                        value: false,
                        groupValue: _isInPerson,
                        onChanged: (v) =>
                            setState(() => _isInPerson = v ?? false),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
                const Gap(8),
                if (_isInPerson)
                  AppTextField(
                    hint: "Mam' Nkosi's house",
                    controller: _locationController,
                    suffix: const Icon(Icons.location_on_outlined),
                  )
                else
                  AppTextField(
                    hint: 'Meeting link (Zoom, Google Meet, etc.)',
                    controller: _linkController,
                    keyboardType: TextInputType.url,
                    suffix: const Icon(Icons.link),
                  ),
                const Gap(20),
                AppTextField(
                  label: 'Agenda',
                  hint:
                      '1. February finances\n2. New member vote\n3. Year-end plans',
                  controller: _agendaController,
                  maxLines: 5,
                ),
                const Gap(20),
                CheckboxListTile(
                  value: _notifyWhatsApp,
                  onChanged: (v) =>
                      setState(() => _notifyWhatsApp = v ?? true),
                  title: const Text('Send via WhatsApp'),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                const Gap(24),
                AppButton(
                  label: 'Schedule Meeting',
                  onPressed: _save,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
