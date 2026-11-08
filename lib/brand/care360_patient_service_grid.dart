import 'package:flutter/material.dart';

/// Existing Patient destinations, not additional APIs or clinical privileges.
enum Care360ServiceDestination {
  hospitals,
  doctors,
  providers,
  pharmacies,
  laboratories,
  appointments,
}

/// Presentation-only discovery grid. It never reads a user's health data,
/// geolocation, access token, or employer credentials.
class Care360PatientServiceGrid extends StatelessWidget {
  const Care360PatientServiceGrid({
    super.key,
    required this.onOpen,
  });

  final ValueChanged<Care360ServiceDestination> onOpen;

  static const _navy = Color(0xFF123E4D);
  static const _teal = Color(0xFF087D76);

  static const _services = <_ServiceItem>[
    _ServiceItem(Care360ServiceDestination.hospitals, 'Hospitals',
        'Find facilities', Icons.local_hospital_outlined),
    _ServiceItem(Care360ServiceDestination.doctors, 'Doctors',
        'Find a specialist', Icons.medical_services_outlined),
    _ServiceItem(Care360ServiceDestination.providers, 'Providers',
        'Explore care', Icons.health_and_safety_outlined),
    _ServiceItem(Care360ServiceDestination.pharmacies, 'Pharmacies',
        'Explore medicines', Icons.local_pharmacy_outlined),
    _ServiceItem(Care360ServiceDestination.laboratories, 'Laboratories',
        'Browse tests', Icons.biotech_outlined),
    _ServiceItem(Care360ServiceDestination.appointments, 'Appointments',
        'Review bookings', Icons.event_available_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final columns = screenWidth >= 610 ? 3 : 2;
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final height = textScale > 1.0 ? 128.0 + 28 * (textScale - 1) : 128.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Explore healthcare',
            key: Key('care360-services-heading'),
            style: TextStyle(
              color: _navy,
              fontSize: 21,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Choose a service to continue.',
            style: TextStyle(color: Color(0xFF526F77), fontSize: 13),
          ),
          const SizedBox(height: 14),
          GridView.builder(
            key: const Key('care360-services-grid'),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _services.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 11,
              mainAxisSpacing: 11,
              mainAxisExtent: height,
            ),
            itemBuilder: (context, index) {
              final service = _services[index];
              return Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  key: Key('care360-service-${service.destination.name}'),
                  onTap: () => onOpen(service.destination),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE2EBEA)),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.fromLTRB(13, 11, 11, 9),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 37,
                          height: 37,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE7F4F1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(service.icon, color: _teal, size: 21),
                        ),
                        const Spacer(),
                        Text(
                          service.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: _navy,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          service.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF526F77),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ServiceItem {
  const _ServiceItem(this.destination, this.title, this.subtitle, this.icon);

  final Care360ServiceDestination destination;
  final String title;
  final String subtitle;
  final IconData icon;
}
