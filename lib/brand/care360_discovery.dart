import 'care360_services_roadmap.dart';
import 'package:flutter/material.dart';
import '../Screen/Screens/LabResults.dart';
import 'package:flutter/services.dart';
import 'package:html/parser.dart' as html;
import '../model/display_offer_model.dart';

/// Public discovery shortcuts stay available even before campaigns are added.
class Care360Discovery extends StatelessWidget {
  const Care360Discovery({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Discover more', style: TextStyle(fontSize: 20,
        fontWeight: FontWeight.w800, color: Color(0xFF123E4D))),
      const SizedBox(height: 8),
      Card(child: Column(children: [
        ListTile(leading: const Icon(Icons.grid_view_outlined), title: const Text('More Care360 services'), subtitle: const Text('Training, Health Wallet and Family Care roadmap'), trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const Care360ServicesRoadmap()))),
        const Divider(height: 1),
        ListTile(minVerticalPadding: 14,
          leading: const Icon(Icons.science_outlined, color: Color(0xFF087D76)),
          title: const Text('My laboratory results'),
          subtitle: const Text('Booking progress and released test reports'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const LabResultsScreen()))),
        const Divider(height: 1),
        ListTile(minVerticalPadding: 14,
          leading: const Icon(Icons.favorite_outline, color: Color(0xFF087D76)),
          title: const Text('Health tips'),
          subtitle: const Text('Practical wellbeing advice and published articles'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.pushNamed(context, 'HealthTips')),
        const Divider(height: 1, indent: 16, endIndent: 16),
        ListTile(minVerticalPadding: 14,
          leading: const Icon(Icons.local_offer_outlined, color: Color(0xFF087D76)),
          title: const Text('Offers'),
          subtitle: const Text('Browse current codes, terms and eligible services'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.pushNamed(context, 'Offer')),
      ])),
    ]),
  );
}

class Care360OfferCard extends StatelessWidget {
  const Care360OfferCard({super.key, required this.offer, required this.currency});
  final OfferModel offer;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final code = (offer.offerCode ?? '').trim();
    final amount = offer.isFlat == 1 ? offer.flatDiscount : offer.discount;
    final discount = offer.discountType == 'percentage'
        ? '${offer.discount ?? 0}% discount'
        : '$currency${amount ?? 0} discount';
    return Card(margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(padding: const EdgeInsets.all(18), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.local_offer_outlined, color: Color(0xFF087D76)),
          const SizedBox(height: 8),
          Text(offer.name ?? 'Care360 offer', style: const TextStyle(
            fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(discount, style: const TextStyle(fontSize: 18,
            color: Color(0xFF087D76), fontWeight: FontWeight.w700)),
          if ((offer.terms ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 10), Text(html.parseFragment(offer.terms!).text ?? ''),
          ],
          if ((offer.validity ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 8), Text('Valid: ${offer.validity}'),
          ],
          if (offer.discountCap != null) ...[
            const SizedBox(height: 8),
            Text('Maximum discount: $currency${offer.discountCap}'),
          ],
          const SizedBox(height: 10),
          const Text('For eligible patients and selected clinicians. Enter the '
            'code during booking; eligibility and the final discount are '
            'confirmed before payment.'),
          if (code.isNotEmpty) ...[
            const SizedBox(height: 12), SelectableText(code,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            TextButton.icon(icon: const Icon(Icons.copy),
              label: const Text('Copy offer code'), onPressed: () async {
                await Clipboard.setData(ClipboardData(text: code));
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Offer code copied')));
              }),
          ],
        ])),
    );
  }
}
