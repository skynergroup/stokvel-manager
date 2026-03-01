import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../auth/providers/auth_provider.dart';
import '../../groups/providers/groups_provider.dart';
import '../providers/meeting_provider.dart';

class MeetingDetailScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String meetingId;

  const MeetingDetailScreen({
    super.key,
    required this.groupId,
    required this.meetingId,
  });

  @override
  ConsumerState<MeetingDetailScreen> createState() =>
      _MeetingDetailScreenState();
}

class _MeetingDetailScreenState extends ConsumerState<MeetingDetailScreen> {
  final _minutesController = TextEditingController();
  bool _editingMinutes = false;

  @override
  void dispose() {
    _minutesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final meetingAsync = ref.watch(
      meetingDetailProvider(
          (stokvelId: widget.groupId, meetingId: widget.meetingId)),
    );
    final membersAsync = ref.watch(stokvelMembersProvider(widget.groupId));
    final groupAsync = ref.watch(stokvelDetailProvider(widget.groupId));
    final authState = ref.watch(authStateProvider);
    final dateFormat = DateFormat('EEE d MMM yyyy, HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meeting Detail'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: meetingAsync.when(
        loading: () => const Center(child: LoadingIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (meeting) {
          if (meeting == null) {
            return const Center(child: Text('Meeting not found'));
          }

          final groupName = groupAsync.valueOrNull?.name ?? '';
          final members = membersAsync.valueOrNull ?? [];
          final currentUserId = authState.user?.uid;
          final isOrganizer = meeting.createdBy == currentUserId;
          final isPast = meeting.date.isBefore(DateTime.now());

          // User's current RSVP
          final userRsvp = currentUserId != null
              ? meeting.rsvps[currentUserId]
              : null;

          // Build RSVP lists
          final yesMembers = <String>[];
          final noMembers = <String>[];
          final maybeMembers = <String>[];
          for (final entry in meeting.rsvps.entries) {
            final member =
                members.where((m) => m.userId == entry.key).toList();
            final name = member.isNotEmpty
                ? member.first.displayName
                : entry.key;
            switch (entry.value) {
              case 'yes':
                yesMembers.add(name);
              case 'no':
                noMembers.add(name);
              case 'maybe':
                maybeMembers.add(name);
            }
          }

          if (!_editingMinutes && meeting.minutes != null) {
            _minutesController.text = meeting.minutes!;
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.info.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            meeting.isVirtual
                                ? Icons.videocam_outlined
                                : Icons.location_on_outlined,
                            color: AppColors.info,
                            size: 24,
                          ),
                        ),
                        const Gap(12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(meeting.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge),
                              if (groupName.isNotEmpty)
                                Text(groupName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Gap(16),
                    Row(
                      children: [
                        const Icon(Icons.schedule,
                            size: 18, color: AppColors.textSecondaryLight),
                        const Gap(8),
                        Text(dateFormat.format(meeting.date)),
                      ],
                    ),
                    const Gap(8),
                    if (meeting.isInPerson) ...[
                      Row(
                        children: [
                          const Icon(Icons.place,
                              size: 18, color: AppColors.textSecondaryLight),
                          const Gap(8),
                          Expanded(child: Text(meeting.locationName!)),
                        ],
                      ),
                    ],
                    if (meeting.isVirtual) ...[
                      Row(
                        children: [
                          const Icon(Icons.link,
                              size: 18, color: AppColors.textSecondaryLight),
                          const Gap(8),
                          Expanded(
                            child: Text(
                              meeting.virtualLink!,
                              style: TextStyle(color: AppColors.info),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const Gap(16),

              // RSVP buttons (if upcoming)
              if (!isPast && currentUserId != null) ...[
                Text('Your RSVP',
                    style: Theme.of(context).textTheme.titleLarge),
                const Gap(8),
                Row(
                  children: [
                    _RsvpButton(
                      label: 'Yes',
                      icon: Icons.check_circle_outline,
                      isSelected: userRsvp == 'yes',
                      color: AppColors.success,
                      onTap: () => _updateRsvp('yes'),
                    ),
                    const Gap(8),
                    _RsvpButton(
                      label: 'No',
                      icon: Icons.cancel_outlined,
                      isSelected: userRsvp == 'no',
                      color: AppColors.error,
                      onTap: () => _updateRsvp('no'),
                    ),
                    const Gap(8),
                    _RsvpButton(
                      label: 'Maybe',
                      icon: Icons.help_outline,
                      isSelected: userRsvp == 'maybe',
                      color: AppColors.warning,
                      onTap: () => _updateRsvp('maybe'),
                    ),
                  ],
                ),
                const Gap(16),
              ],

              // Agenda
              if (meeting.agenda != null && meeting.agenda!.isNotEmpty) ...[
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Agenda',
                          style: Theme.of(context).textTheme.titleLarge),
                      const Gap(8),
                      Text(meeting.agenda!),
                    ],
                  ),
                ),
                const Gap(16),
              ],

              // RSVP list
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('RSVPs',
                        style: Theme.of(context).textTheme.titleLarge),
                    const Gap(8),
                    _RsvpSection(
                      label: 'Yes (${yesMembers.length})',
                      names: yesMembers,
                      color: AppColors.success,
                      icon: Icons.check_circle,
                    ),
                    const Gap(8),
                    _RsvpSection(
                      label: 'No (${noMembers.length})',
                      names: noMembers,
                      color: AppColors.error,
                      icon: Icons.cancel,
                    ),
                    const Gap(8),
                    _RsvpSection(
                      label: 'Maybe (${maybeMembers.length})',
                      names: maybeMembers,
                      color: AppColors.warning,
                      icon: Icons.help,
                    ),
                  ],
                ),
              ),
              const Gap(16),

              // Minutes section
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Minutes',
                            style: Theme.of(context).textTheme.titleLarge),
                        if (isOrganizer && !_editingMinutes)
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: () {
                              setState(() => _editingMinutes = true);
                            },
                          ),
                      ],
                    ),
                    const Gap(8),
                    if (_editingMinutes) ...[
                      TextField(
                        controller: _minutesController,
                        maxLines: 8,
                        decoration: const InputDecoration(
                          hintText: 'Record meeting minutes here...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const Gap(12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () =>
                                setState(() => _editingMinutes = false),
                            child: const Text('Cancel'),
                          ),
                          const Gap(8),
                          AppButton(
                            label: 'Save',
                            fullWidth: false,
                            onPressed: () async {
                              await ref
                                  .read(meetingServiceProvider)
                                  .recordMinutes(
                                    stokvelId: widget.groupId,
                                    meetingId: widget.meetingId,
                                    minutes: _minutesController.text,
                                  );
                              if (context.mounted) {
                                setState(() => _editingMinutes = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Minutes saved')),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ] else if (meeting.minutes != null &&
                        meeting.minutes!.isNotEmpty)
                      Text(meeting.minutes!)
                    else
                      Text('No minutes recorded yet',
                          style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _updateRsvp(String response) {
    final userId = ref.read(authStateProvider).user?.uid;
    if (userId == null) return;

    ref.read(rsvpProvider.notifier).updateRsvp(
          stokvelId: widget.groupId,
          meetingId: widget.meetingId,
          userId: userId,
          response: response,
        );
  }
}

class _RsvpButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _RsvpButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.15) : null,
            border: Border.all(
              color: isSelected ? color : AppColors.divider,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? color : AppColors.textSecondaryLight),
              const Gap(4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? color : AppColors.textSecondaryLight,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RsvpSection extends StatelessWidget {
  final String label;
  final List<String> names;
  final Color color;
  final IconData icon;

  const _RsvpSection({
    required this.label,
    required this.names,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const Gap(6),
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: color, fontSize: 13)),
          ],
        ),
        if (names.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 22, top: 4),
            child: Text(names.join(', '),
                style: Theme.of(context).textTheme.bodySmall),
          ),
      ],
    );
  }
}
