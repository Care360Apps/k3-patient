import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../api/apis.dart';
import '../../const/preference.dart';
import '../../const/prefConstatnt.dart';
import '../../security/care360_lab_results_client.dart';

class LabResultsScreen extends StatefulWidget {
  const LabResultsScreen({super.key});
  @override
  State<LabResultsScreen> createState() => _LabResultsScreenState();
}

class _LabResultsScreenState extends State<LabResultsScreen> {
  late final Care360LabResultsClient _client;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  int _page = 1;
  int _lastPage = 1;
  List<Map<String, dynamic>> _results = [];
  @override
  void initState() {
    super.initState();
    _client = Care360LabResultsClient(
      base: Uri.parse(Apis.baseUrl),
      readToken: () =>
          SharedPreferenceHelper.getSecureString(Preferences.auth_token),
      allowLoopbackHttp: true,
    );
    _load();
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _client.list(_page);
      if (!mounted) return;
      setState(() {
        _results = (data['data'] as List)
            .whereType<Map>()
            .map((r) => Map<String, dynamic>.from(r))
            .toList();
        _lastPage = (data['last_page'] as num?)?.toInt() ?? 1;
      });
    } catch (_) {
      if (mounted)
        setState(
          () => _error =
              'Unable to load your laboratory bookings. Please try again.',
        );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save(int id) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final result = await _client.download(id);
      if (!mounted) return;
      await FilePicker.platform.saveFile(
        dialogTitle: 'Save laboratory result',
        fileName: 'care360-lab-$id.${result.extension}',
        type: FileType.custom,
        allowedExtensions: [result.extension],
        bytes: result.bytes,
      );
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Result could not be saved. Please retry or contact your laboratory.',
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('My laboratory results')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!),
                TextButton(onPressed: _load, child: const Text('Retry')),
              ],
            ),
          )
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Track your tests and save results after your laboratory releases them. Ask your treating clinician to explain your findings and next steps.',
                ),
                if (_results.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No laboratory bookings found.'),
                  ),
                for (final result in _results)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (result['report_id'] ?? 'Laboratory booking')
                                .toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('Date: ${result['date'] ?? ''}'),
                          Text(
                            'Status: ${(result['workflow_status'] ?? 'booked').toString().replaceAll('_', ' ')}',
                          ),
                          if (result['workflow_status'] == 'released')
                            TextButton.icon(
                              onPressed: _saving
                                  ? null
                                  : () => _save((result['id'] as num).toInt()),
                              icon: const Icon(Icons.download_outlined),
                              label: Text(
                                _saving ? 'Preparing result…' : 'Save result',
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: _page > 1
                          ? () {
                              _page--;
                              _load();
                            }
                          : null,
                      child: const Text('Previous'),
                    ),
                    Text('Page $_page of $_lastPage'),
                    TextButton(
                      onPressed: _page < _lastPage
                          ? () {
                              _page++;
                              _load();
                            }
                          : null,
                      child: const Text('Next'),
                    ),
                  ],
                ),
              ],
            ),
          ),
  );
}
