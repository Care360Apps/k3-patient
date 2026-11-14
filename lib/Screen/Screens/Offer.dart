import 'package:flutter/material.dart';
import '../../api/network_api.dart';
import '../../api/retrofit_Api.dart';
import '../../brand/care360_discovery.dart';
import '../../const/prefConstatnt.dart';
import '../../const/preference.dart';
import '../../model/display_offer_model.dart';

class Offer extends StatefulWidget {
  const Offer({super.key, this.loadOffers});
  final Future<DisplayOffer> Function()? loadOffers;
  @override
  State<Offer> createState() => _OfferState();
}

class _OfferState extends State<Offer> {
  List<OfferModel> _offers = [];
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    if (!_loading && mounted) setState(() => _loading = true);
    try {
      final result = await (widget.loadOffers?.call() ??
        RestClient(RetroApi2().dioData2()).displayOfferRequest());
      if (result.success != true) throw StateError('Offers unavailable');
      if (!mounted) return;
      setState(() { _offers = result.data ?? []; _failed = false; });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stored = SharedPreferenceHelper.getString(Preferences.currency_symbol);
    final currency = stored == null || stored == 'N_A' ? '' : stored;
    return Scaffold(backgroundColor: const Color(0xFFF5F8F7),
      appBar: AppBar(title: const Text('Offers')),
      body: SafeArea(child: RefreshIndicator(onRefresh: _load,
        child: ListView(padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(), children: [
            const Text('More value for your care', style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text('Current promotions published by Care360. '
              'Pull down to check for updates.'),
            if (_loading) const Padding(padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator())),
            if (_failed) Card(child: Padding(padding: const EdgeInsets.all(20),
              child: Column(children: [
                const Text('We could not refresh offers. Check your connection.'),
                TextButton(onPressed: _loading ? null : _load,
                  child: const Text('Try again')),
              ]))),
            if (!_loading && !_failed && _offers.isEmpty)
              const Card(child: Padding(padding: EdgeInsets.all(24),
                child: Column(children: [Icon(Icons.local_offer_outlined, size: 40),
                  SizedBox(height: 12), Text('No offers available right now',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  SizedBox(height: 8), Text('Check back here for new promotions. '
                    'You can still book available care at the displayed price.',
                    textAlign: TextAlign.center),
                ]))),
            for (final offer in _offers) Care360OfferCard(offer: offer, currency: currency),
          ]))),
    );
  }
}
