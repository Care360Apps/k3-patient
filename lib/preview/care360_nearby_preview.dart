import 'package:flutter/material.dart';

/// Synthetic, self-contained UI design study for BlueStacks.
/// Not a map provider, geolocation system, or real Care360 service directory.
class Care360NearbyPreview extends StatefulWidget {
  const Care360NearbyPreview({super.key});

  @override
  State<Care360NearbyPreview> createState() => _Care360NearbyPreviewState();
}

class _Care360NearbyPreviewState extends State<Care360NearbyPreview> {
  static const _navy = Color(0xFF112E45);
  static const _teal = Color(0xFF08785E);
  String _category = 'All';
  bool _acceptingOnly = false;
  int _selected = 0;

  static const _examples = [
    _ExampleProfessional('Sample Doctor A', 'Doctor', 2.4, true,
        Alignment(-0.60, -0.32), Icons.medical_services_outlined),
    _ExampleProfessional('Sample Care Provider B', 'Care Provider', 3.8, true,
        Alignment(0.45, -0.06), Icons.home_outlined),
    _ExampleProfessional('Sample Doctor C', 'Doctor', 6.1, false,
        Alignment(0.14, 0.60), Icons.medical_services_outlined),
    _ExampleProfessional('Sample Care Provider D', 'Care Provider', 8.2, false,
        Alignment(-0.45, 0.38), Icons.home_outlined),
  ];

  List<int> get _visible {
    final indices = <int>[];
    for (var i = 0; i < _examples.length; i++) {
      final p = _examples[i];
      if ((_category == 'All' || _category == p.type) &&
          (!_acceptingOnly || p.accepting)) {
        indices.add(i);
      }
    }
    return indices;
  }

  void _select(int index) => setState(() => _selected = index);

  void _showDetails(_ExampleProfessional p) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(p.name),
        content: Text(
          'Illustrative profile only. A verified professional would show '
          'credentials, supported services, actual appointment slots, '
          'fees and a booking request here. No patient data or live '
          'provider location is used in this preview.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    final active = visible.contains(_selected)
        ? _selected : (visible.isEmpty ? -1 : visible.first);
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _navy,
        title: const Text('Nearby Care · design preview'),
      ),
      body: SafeArea(
        child: ListView(
          key: const Key('nearby-preview-scroll'),
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1D6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.science_outlined,
                    color: Color(0xFF785310)),
                  SizedBox(width: 10),
                  Expanded(child: Text(
                    'SYNTHETIC DEMO — sample professionals, sample '
                    'distances and schematic roads. Not real availability.',
                    style: TextStyle(fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5D431A)),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text('Care closer to you',
              style: TextStyle(color: _navy, fontSize: 23,
                fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text(
              'Explore the map, compare nearby care and request the '
              'right service from a verified professional.',
              style: TextStyle(color: Color(0xFF536774), height: 1.4),
            ),
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                for (final category in const ['All', 'Doctor', 'Care Provider'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      key: Key('sample-nearby-filter-${category.toLowerCase().replaceAll(' ', '-')}'),
                      selected: _category == category,
                      label: Text(category),
                      onSelected: (_) => setState(() => _category = category),
                    ),
                  ),
              ]),
            ),
            SwitchListTile.adaptive(
              key: const Key('sample-accepting-requests'),
              value: _acceptingOnly,
              contentPadding: EdgeInsets.zero,
              title: const Text('Accepting requests',
                style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Only simulated on-duty professionals'),
              onChanged: (value) =>
                setState(() => _acceptingOnly = value),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                height: 290,
                child: Stack(
                  children: [
                    const Positioned.fill(
                      child: CustomPaint(painter: _SchematicMapPainter()),
                    ),
                    const Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.all(Radius.circular(8))),
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: Text('Illustrative map · Keffi pilot concept',
                              style: TextStyle(color: _navy, fontSize: 11,
                                fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                    ),
                    for (final index in visible)
                      Align(
                        alignment: _examples[index].position,
                        child: Tooltip(
                          message: '${_examples[index].name}, sample '
                            '${_examples[index].distanceKm} km',
                          child: InkResponse(
                            key: Key('sample-pin-$index'),
                            onTap: () => _select(index),
                            radius: 27,
                            child: CircleAvatar(
                              radius: active == index ? 23 : 18,
                              backgroundColor: _examples[index].accepting
                                ? _teal : _navy,
                              child: Icon(_examples[index].icon,
                                color: Colors.white,
                                size: active == index ? 25 : 21),
                            ),
                          ),
                        ),
                      ),
                    const Align(
                      alignment: Alignment(0, 0.11),
                      child: IgnorePointer(
                        child: Icon(Icons.my_location,
                          size: 25, color: Color(0xFF2478C1)),
                      ),
                    ),
                    const Positioned(
                      left: 12, bottom: 12,
                      child: Text('Visual concept, not real streets or GPS',
                        style: TextStyle(color: _navy, fontSize: 10)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Closest suitable professionals',
              style: TextStyle(color: _navy, fontSize: 17,
                fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('Example straight-line distances · '
                'actual booking requires confirmation',
              style: TextStyle(fontSize: 12, color: Color(0xFF5D6C78))),
            const SizedBox(height: 12),
            if (visible.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Center(child: Text('No sample professionals match.')),
              )
            else
              for (final index in visible)
                Card(
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                  child: ListTile(
                    key: Key('sample-professional-$index'),
                    onTap: () => _select(index),
                    selected: active == index,
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFE0F1E9),
                      child: Icon(_examples[index].icon, color: _teal)),
                    title: Text(_examples[index].name,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(
                      '${_examples[index].type} · '
                      '${_examples[index].distanceKm.toStringAsFixed(1)} km '
                      '(example)\n'
                      '${_examples[index].accepting
                          ? 'Accepting requests (sample)'
                          : 'Not accepting requests (sample)'}',
                      style: const TextStyle(height: 1.5)),
                    isThreeLine: true,
                    trailing: IconButton(
                      tooltip: 'Preview professional details',
                      icon: const Icon(Icons.arrow_forward_ios, size: 17),
                      onPressed: () => _showDetails(_examples[index]),
                    ),
                  ),
                ),
            const SizedBox(height: 12),
            const Text(
              'A live version must verify the professional, their '
              'service area, supported consultation type and available '
              'appointment before confirming a request.',
              style: TextStyle(color: Color(0xFF506573), fontSize: 12,
                height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExampleProfessional {
  const _ExampleProfessional(this.name, this.type, this.distanceKm,
      this.accepting, this.position, this.icon);
  final String name;
  final String type;
  final double distanceKm;
  final bool accepting;
  final Alignment position;
  final IconData icon;
}

/// Deliberately imaginary roads: neither Google Maps data nor real geography.
class _SchematicMapPainter extends CustomPainter {
  const _SchematicMapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size,
      Paint()..color = const Color(0xFFE2F0E8));
    final green = Paint()..color = const Color(0xFFCCE4D4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.04, size.height * 0.32,
          size.width * 0.33, size.height * 0.42),
        const Radius.circular(25)),
      green);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.60, size.height * 0.07,
          size.width * 0.33, size.height * 0.38),
        const Radius.circular(30)),
      green);

    final roadBorder = Paint()
      ..color = const Color(0xFFC9D9D2)
      ..strokeWidth = 29
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final road = Paint()
      ..color = Colors.white
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(-20, size.height * 0.86)
      ..cubicTo(size.width * 0.24, size.height * 0.64,
          size.width * 0.72, size.height * 0.18,
          size.width + 20, size.height * 0.14);
    canvas.drawPath(path, roadBorder);
    canvas.drawPath(path, road);
    final crossing = Path()
      ..moveTo(size.width * 0.28, -20)
      ..lineTo(size.width * 0.42, size.height + 20);
    canvas.drawPath(crossing, roadBorder);
    canvas.drawPath(crossing, road);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
