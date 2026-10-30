import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctro_patient/Chat/loading_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../const/Palette.dart';
import '../../const/app_string.dart';
import '../../localization/localization_constant.dart';
import '../../model/course_model.dart';
import '../../const/prefConstatnt.dart';
import '../../const/preference.dart';

class CourseDetail extends StatelessWidget {
  final CourseData course;

  CourseDetail({required this.course});

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            size: 20,
            color: Palette.dark_blue,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        centerTitle: true,
        backgroundColor: Palette.white,
        title: Text(
          getTranslated(context, AppString.courses_detail_title).toString(),
          style: TextStyle(fontSize: 18, color: Palette.dark_blue, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Palette.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Palette.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: course.fullImage ?? '',
                  height: width * 0.55,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Center(
                    child: SpinKitFadingCircle(color: Palette.blue),
                  ),
                  errorWidget: (context, url, error) => Image.asset(
                    "assets/images/no_image.jpg",
                    fit: BoxFit.cover,
                    height: width * 0.55,
                    width: double.infinity,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                course.title ?? '',
                style: TextStyle(
                  fontSize: 20,
                  color: Palette.dark_blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _infoChip(
                    context,
                    Icons.schedule,
                    getTranslated(context, AppString.courses_duration).toString(),
                    course.duration ?? '-',
                  ),
                  _infoChip(
                    context,
                    Icons.payments_outlined,
                    getTranslated(context, AppString.courses_amount).toString(),
                    (SharedPreferenceHelper.getString(Preferences.currency_symbol) ?? '') + _formatAmount(course.amount),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                getTranslated(context, AppString.courses_summary).toString(),
                style: TextStyle(
                  fontSize: 16,
                  color: Palette.dark_blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Html(
                data: course.summary ?? '',
              ),
            ),
            SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                getTranslated(context, AppString.courses_details).toString(),
                style: TextStyle(
                  fontSize: 16,
                  color: Palette.dark_blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Html(
                data: course.details ?? '',
              ),
            ),
            SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _launchPurchase(context, course.link);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Palette.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    getTranslated(context, AppString.courses_purchase).toString(),
                    style: TextStyle(fontSize: 16, color: Palette.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(BuildContext context, IconData icon, String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Palette.light_blue.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Palette.blue),
          SizedBox(width: 6),
          Text(
            '$label: $value',
            style: TextStyle(
              fontSize: 13,
              color: Palette.dark_blue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(num? amount) {
    final value = amount ?? 0;
    return value.toStringAsFixed(2);
  }

  Future<void> _launchPurchase(BuildContext context, String? link) async {
    if (link == null || link.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(getTranslated(context, AppString.courses_link_missing).toString()),
        ),
      );
      return;
    }
    final uri = Uri.parse(link);
    await launchUrl(uri);
  }
}
