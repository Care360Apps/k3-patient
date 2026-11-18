import 'package:flutter/material.dart';
import '../../api/network_api.dart';
import '../../api/retrofit_Api.dart';
import '../../brand/care360_health_essentials.dart';
import '../../model/health_tip_model.dart' as tips;
import 'HealthTipsDetail.dart';

class HealthTips extends StatefulWidget {
  const HealthTips({super.key, this.loadTips});
  final Future<tips.HealthTip> Function()? loadTips;
  @override
  State<HealthTips> createState() => _HealthTipsState();
}

class _HealthTipsState extends State<HealthTips> {
  List<tips.Data> _published = [];
  bool _loading = true;
  bool _failed = false;
  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      final result = await (widget.loadTips?.call() ??
        RestClient(RetroApi2().dioData2()).healthTipRequest());
      if (result.success != true) throw StateError('Articles unavailable');
      if (!mounted) return;
      setState(() { _published = result.data ?? []; _failed = false; });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _tile(tips.Data tip, {bool bundled = false}) => Card(
    child: ListTile(contentPadding: const EdgeInsets.all(16),
      leading: const Icon(Icons.menu_book_outlined, color: Color(0xFF087D76)),
      title: Text(tip.title ?? 'Health article', style: const TextStyle(
        fontWeight: FontWeight.w700, fontSize: 18)),
      subtitle: Padding(padding: const EdgeInsets.only(top: 6),
        child: Text(tip.blogRef ?? 'Care360 editorial')),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.push(context, MaterialPageRoute<void>(
        builder: (_) => HealthTipsDetail(id: tip.id,
          bundled: bundled ? tip : null))),
    ));

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF5F8F7),
    appBar: AppBar(title: const Text('Health tips')),
    body: SafeArea(child: RefreshIndicator(onRefresh: _load,
      child: ListView(padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(), children: [
          const Text('Small steps for everyday wellbeing', style: TextStyle(
            fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('General education. For advice about your own health, '
            'speak with a qualified clinician.'),
          const SizedBox(height: 18),
          const Text('Care360 essentials • available offline', style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w700)),
          for (final tip in care360HealthEssentials) _tile(tip, bundled: true),
          const SizedBox(height: 18),
          const Text('Latest articles', style: TextStyle(fontSize: 18,
            fontWeight: FontWeight.w700)),
          if (_loading) const Center(child: Padding(padding: EdgeInsets.all(20),
            child: CircularProgressIndicator())),
          if (_failed) Column(children: [
            const Text('Latest articles could not be refreshed. '
              'The essentials above are still available.'),
            TextButton(onPressed: _loading ? null : _load, child: const Text('Try again')),
          ]),
          if (!_loading && !_failed && _published.isEmpty)
            const Padding(padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('New articles will appear here when published.')),
          for (final tip in _published) _tile(tip),
        ]))),
  );
}
