import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sayfoods_app/src/features/admin/presentation/admin_order_detail_screen.dart'; // ridersListProvider
import 'package:sayfoods_app/src/features/admin/application/rider_schedule_provider.dart';
import 'package:sayfoods_app/src/shared/widgets/sayfoods_modal.dart';

class ManageRiderSchedulesScreen extends ConsumerStatefulWidget {
  const ManageRiderSchedulesScreen({super.key});

  @override
  ConsumerState<ManageRiderSchedulesScreen> createState() =>
      _ManageRiderSchedulesScreenState();
}

class _ManageRiderSchedulesScreenState
    extends ConsumerState<ManageRiderSchedulesScreen> {
  static const _purple = Color(0xFF5B1380);
  static const _bg = Color(0xFFFCFCFC);

  String? _selectedRiderId;
  String? _selectedRiderName;

  Future<void> _pickAndAddShift() async {
    if (_selectedRiderId == null) return;

    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _purple,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    try {
      await ref
          .read(riderScheduleNotifierProvider.notifier)
          .addShift(_selectedRiderId!, picked);

      // Refresh the schedule list
      ref.invalidate(riderSchedulesProvider(_selectedRiderId!));

      if (mounted) {
        SayfoodsModal.show(
          context: context,
          type: SayfoodsModalType.success,
          title: 'Shift Added',
          subtitle:
              '${DateFormat('EEE, MMM d').format(picked)} assigned to $_selectedRiderName.',
        );
      }
    } catch (e) {
      if (mounted) {
        SayfoodsModal.show(
          context: context,
          type: SayfoodsModalType.error,
          title: 'Error',
          subtitle: e.toString().contains('duplicate')
              ? '$_selectedRiderName is already scheduled for that date.'
              : 'Failed to add shift: $e',
        );
      }
    }
  }

  Future<void> _toggleShift(String scheduleId, bool newValue) async {
    try {
      await ref
          .read(riderScheduleNotifierProvider.notifier)
          .toggleActive(scheduleId, newValue);
      ref.invalidate(riderSchedulesProvider(_selectedRiderId!));
    } catch (e) {
      if (mounted) {
        SayfoodsModal.show(
          context: context,
          type: SayfoodsModalType.error,
          title: 'Error',
          subtitle: 'Failed to update shift: $e',
        );
      }
    }
  }

  Future<void> _deleteShift(String scheduleId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Shift'),
        content:
            const Text('Are you sure you want to permanently delete this shift?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ref
          .read(riderScheduleNotifierProvider.notifier)
          .deleteShift(scheduleId);
      ref.invalidate(riderSchedulesProvider(_selectedRiderId!));
      if (mounted) {
        SayfoodsModal.show(
          context: context,
          type: SayfoodsModalType.success,
          title: 'Deleted',
          subtitle: 'Shift removed successfully.',
        );
      }
    } catch (e) {
      if (mounted) {
        SayfoodsModal.show(
          context: context,
          type: SayfoodsModalType.error,
          title: 'Error',
          subtitle: 'Failed to delete shift: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ridersAsync = ref.watch(ridersListProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Rider Schedules'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(
            color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
      ),
      floatingActionButton: _selectedRiderId != null
          ? FloatingActionButton.extended(
              onPressed: _pickAndAddShift,
              backgroundColor: _purple,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Add Shift',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Rider Selector ──────────────────────────────────────
            const Text('Select Rider',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ridersAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Could not load riders: $e',
                  style: const TextStyle(color: Colors.red)),
              data: (riders) {
                if (riders.isEmpty) {
                  return const Text(
                    'No riders found. Make sure profiles have role = "rider".',
                    style: TextStyle(color: Colors.grey),
                  );
                }
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: const Text('Choose a rider...'),
                      value: _selectedRiderId,
                      items: riders.map((r) {
                        return DropdownMenuItem<String>(
                          value: r['id'].toString(),
                          child: Text(r['full_name'] ?? 'Unnamed Rider'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        final match =
                            riders.firstWhere((r) => r['id'] == val);
                        setState(() {
                          _selectedRiderId = val;
                          _selectedRiderName =
                              match['full_name']?.toString();
                        });
                      },
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // ── Schedule List ───────────────────────────────────────
            if (_selectedRiderId != null) ...[
              Text('Shifts for $_selectedRiderName',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Expanded(
                child: _buildScheduleList(),
              ),
            ] else
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_month,
                          size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Select a rider above to manage their schedule.',
                          style: TextStyle(color: Colors.grey, fontSize: 15)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleList() {
    final schedulesAsync = ref.watch(riderSchedulesProvider(_selectedRiderId!));

    return schedulesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
          child:
              Text('Error loading schedules: $e', style: const TextStyle(color: Colors.red))),
      data: (schedules) {
        if (schedules.isEmpty) {
          return const Center(
            child: Text('No shifts scheduled yet.\nTap "Add Shift" to create one.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 15)),
          );
        }

        return ListView.builder(
          itemCount: schedules.length,
          itemBuilder: (context, index) {
            final shift = schedules[index];
            final date = DateTime.parse(shift['shift_date'].toString());
            final isActive = shift['is_active'] as bool? ?? true;
            final isPast = date.isBefore(
                DateTime.now().subtract(const Duration(days: 1)));
            final isToday = DateFormat('yyyy-MM-dd').format(date) ==
                DateFormat('yyyy-MM-dd').format(DateTime.now());

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isToday
                      ? _purple.withValues(alpha: 0.4)
                      : Colors.grey.shade100,
                  width: isToday ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  // Date icon
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isPast
                          ? Colors.grey.shade100
                          : isToday
                              ? _purple.withValues(alpha: 0.1)
                              : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('d').format(date),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: isPast ? Colors.grey : _purple,
                          ),
                        ),
                        Text(
                          DateFormat('MMM').format(date),
                          style: TextStyle(
                            fontSize: 10,
                            color: isPast ? Colors.grey : _purple,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isToday
                              ? 'Today'
                              : DateFormat('EEEE').format(date),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isPast ? Colors.grey : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            fontSize: 12,
                            color: isActive ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Toggle
                  Switch(
                    value: isActive,
                    activeColor: Colors.green,
                    onChanged: (val) =>
                        _toggleShift(shift['id'].toString(), val),
                  ),

                  // Delete
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.red, size: 22),
                    onPressed: () => _deleteShift(shift['id'].toString()),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
