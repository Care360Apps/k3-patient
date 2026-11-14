import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../api/network_api.dart';
import '../../api/retrofit_Api.dart';
import '../../brand/care360_health_essentials.dart';
import '../../brand/care360_partner_showcase.dart';
import '../../model/health_tip_model.dart' as tips;

class HealthTipsDetail extends StatefulWidget {
  const HealthTipsDetail({super.key, this.id, this.bundled});
  final int? id;
  final tips.Data? bundled;
  @override
  State<HealthTipsDetail> createState() => _HealthTipsDetailState();
}

class _HealthTipsDetailState extends State<HealthTipsDetail> {
  bool _loading = false;
  bool _failed = false;
  String _title = '';
  String _body = '';
  String _reference = '';
  @override
  void initState() {
    super.initState();
    final local = widget.bundled;
    if (local != null) {
      _title = local.title ?? ''; _body = local.desc ?? '';
      _reference = local.blogRef ?? '';
    } else { _load(); }
  }

  Future<void> _load() async {
    if (mounted) setState(() { _loading = true; _failed = false; });
    try {
      final result = await RestClient(RetroApi2().dioData2()).healthTipDetailRequest(widget.id);
      if (result.success != true || result.data == null) throw StateError('Unavailable');
      if (!mounted) return;
      setState(() {
        _title = result.data!.title ?? ''; _body = result.data!.desc ?? '';
        _reference = result.data!.blogRef ?? '';
      });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _source() async {
    final url = Care360PartnerSlide.safeDestination(
      care360HealthSources[widget.id] ?? _reference);
    if (url == null) return;
    var opened = false;
    try { opened = await launchUrl(url, mode: LaunchMode.externalApplication); }
    catch (_) { /* Show a readable error without logging URLs. */ }
    if (!opened && mounted) ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open the source. Check your connection.')));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Health article')),
    body: SafeArea(child: _loading ? const Center(child: CircularProgressIndicator())
      : _failed ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('This article is unavailable or no longer published.'),
          TextButton(onPressed: _load, child: const Text('Try again')),
        ])) : SingleChildScrollView(padding: const EdgeInsets.all(20),
        child: SelectionArea(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_title, style: const TextStyle(fontSize: 26,
              fontWeight: FontWeight.w800, color: Color(0xFF123E4D))),
            const SizedBox(height: 12), Text(_reference),
            const SizedBox(height: 16),
            // Editorial HTML is text-only. Remote images, iframes and tracking
            // links are not loaded while a patient reads an article.
            Html(data: _body, onlyRenderTheseTags: {
              'html', 'body', 'p', 'div', 'span', 'br', 'h1', 'h2', 'h3',
              'ul', 'ol', 'li', 'strong', 'b', 'em', 'i', 'blockquote',
            }),
            if (Care360PartnerSlide.safeDestination(
              care360HealthSources[widget.id] ?? _reference) != null)
              TextButton.icon(onPressed: _source, icon: const Icon(Icons.open_in_new),
                label: const Text('Read the source')),
            const Divider(height: 32),
            const Text('Health information supports informed conversations; '
              'it does not replace individual assessment or treatment. '
              'For an urgent health concern, seek local emergency care.'),
          ])))),
  );
}
