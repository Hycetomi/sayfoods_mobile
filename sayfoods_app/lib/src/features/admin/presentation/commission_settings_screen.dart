import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sayfoods_app/src/features/admin/application/system_settings_provider.dart';
import 'package:sayfoods_app/src/shared/widgets/sayfoods_modal.dart';

class CommissionSettingsScreen extends ConsumerStatefulWidget {
  const CommissionSettingsScreen({super.key});

  @override
  ConsumerState<CommissionSettingsScreen> createState() => _CommissionSettingsScreenState();
}

class _CommissionSettingsScreenState extends ConsumerState<CommissionSettingsScreen> {
  final _controller = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(systemSettingsProvider);
    if (settings is AsyncData) {
      _controller.text = settings.value?['commission_percentage']?.toString() ?? '60.0';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final val = double.tryParse(_controller.text);
    if (val == null || val < 0 || val > 100) {
      SayfoodsModal.show(
        context: context,
        type: SayfoodsModalType.error,
        title: 'Invalid Input',
        subtitle: 'Please enter a valid percentage between 0 and 100.',
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref.read(systemSettingsProvider.notifier).updateCommissionPercentage(val);
      if (mounted) {
        SayfoodsModal.show(
          context: context,
          type: SayfoodsModalType.success,
          title: 'Saved',
          subtitle: 'Commission percentage updated successfully.',
        );
      }
    } catch (e) {
      if (mounted) {
        SayfoodsModal.show(
          context: context,
          type: SayfoodsModalType.error,
          title: 'Error',
          subtitle: 'Failed to update settings: $e',
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFC),
      appBar: AppBar(
        title: const Text('Commission Settings'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rider Commission Split',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Set the global percentage of the delivery fee that riders will earn upon completing a delivery. Note that riders are guaranteed a minimum of ₦500 per delivery regardless of this percentage.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Percentage (%)',
                hintText: 'e.g. 60.0',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: const Icon(Icons.percent),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B1380),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save Settings', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
