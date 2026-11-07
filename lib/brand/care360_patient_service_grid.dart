import 'package:flutter/material.dart';

/// A single discovery surface for existing care routes and the protected
/// Workforce preview. Existing clinical pages keep their own authorization,
/// booking, payment, consent and patient-data access checks.
class Care360PatientServiceGrid extends StatelessWidget {
  const Care360PatientServiceGrid({
    super.key,
    required this.onHospitals,
    required this.onPharmacies,
    required this.onDoctors,
    required this.onProviders,
    required this.onLabs,
    required this.onWorkforce,
  });

  final VoidCallback onHospitals;
  final VoidCallback onPharmacies;
  final VoidCallback onDoctors;
  final VoidCallback onProviders;
  final VoidCallback onLabs;
  final VoidCallback onWorkforce;

  static const _navy = Color(0xFF123E4D);
  static const _teal = Color(0xFF087D76);

  @override
  Widget build(BuildContext context) {
    final services = <_PatientService>[
      _PatientService('Hospitals', Icons.local_hospital_outlined, onHospitals),
      _PatientService('Pharmacies', Icons.medication_outlined, onPharmacies),
      _PatientService('Doctors', Icons.stethoscope_outlined, onDoctors),
      _PatientService('Providers', Icons.medical_services_outlined, onProviders),
      _PatientService('Labs', Icons.science_outlined, onLabs),
      _PatientService('Workforce', Icons.groups_2_outlined, onWorkforce),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Healthcare & opportunities',
            key: Key('care360-services-heading'),
            style: TextStyle(fontSize: 19, height: 1.2,
                color: _navy, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'Choose where you would like to go.',
            style: TextStyle(color: Color(0xFF526B72), fontSize: 13),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final count = constraints.maxWidth < 350 ? 2 : 3;
              return GridView.builder(
                key: const Key('care360-patient-service-grid'),
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: services.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: count,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  mainAxisExtent: 110,
                ),
                itemBuilder: (context, index) {
                  final service = services[index];
                  return Semantics(
                    button: true,
                    label: 'Open ${service.title}',
                    child: Material(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Color(0xFFDCE8E5)),
                      ),
                      child: InkWell(
                        key: Key('care360-service-${service.title.toLowerCase()}'),
                        borderRadius: BorderRadius.circular(16),
                        onTap: service.open,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 11),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 43,
                                height: 43,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE6F4EF),
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: Icon(service.icon, size: 24,
                                    color: _teal),
                              ),
                              const SizedBox(height: 9),
                              Flexible(child: Text(
                                service.title,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _navy,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  height: 1.1,
                                ),
                              )),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PatientService {
  const _PatientService(this.title, this.icon, this.open);
  final String title;
  final IconData icon;
  final VoidCallback open;
}
