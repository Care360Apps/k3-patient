import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctro_patient/Chat/loading_view.dart';
import 'package:doctro_patient/Screen/Courses/CourseDetail.dart';
import 'package:flutter/material.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import '../../api/base_model.dart';
import '../../api/network_api.dart';
import '../../api/retrofit_Api.dart';
import '../../api/server_error.dart';
import '../../const/Palette.dart';
import '../../const/app_string.dart';
import '../../localization/localization_constant.dart';
import '../../model/course_model.dart';
import '../../const/prefConstatnt.dart';
import '../../const/preference.dart';

class CourseList extends StatefulWidget {
  @override
  _CourseListState createState() => _CourseListState();
}

class _CourseListState extends State<CourseList> {
  bool loading = false;
  List<CourseData> courses = [];

  @override
  void initState() {
    super.initState();
    callApiCourses();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return ModalProgressHUD(
      inAsyncCall: loading,
      opacity: 0.5,
      progressIndicator: SpinKitFadingCircle(
        color: Palette.blue,
        size: 50.0,
      ),
      child: Scaffold(
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
            getTranslated(context, AppString.courses_title).toString(),
            style: TextStyle(fontSize: 18, color: Palette.dark_blue, fontWeight: FontWeight.bold),
          ),
        ),
        body: courses.isEmpty
            ? Container(
                alignment: AlignmentDirectional.center,
                margin: EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                child: Text(
                  getTranslated(context, AppString.courses_empty).toString(),
                  style: TextStyle(fontSize: width * 0.04, color: Palette.grey, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              )
            : Padding(
                padding: EdgeInsets.symmetric(horizontal: width * 0.04, vertical: 12),
                child: GridView.builder(
                  itemCount: courses.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.82,
                  ),
                  itemBuilder: (context, index) {
                    final course = courses[index];
                    final summary = _plainText(course.summary);
                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CourseDetail(course: course),
                          ),
                        );
                      },
                      child: Container(
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                              child: CachedNetworkImage(
                                imageUrl: course.fullImage ?? '',
                                height: 120,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Center(
                                  child: SpinKitFadingCircle(color: Palette.blue),
                                ),
                                errorWidget: (context, url, error) => Image.asset(
                                  "assets/images/no_image.jpg",
                                  fit: BoxFit.cover,
                                  height: 120,
                                  width: double.infinity,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    course.title ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Palette.dark_blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    summary,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Palette.grey,
                                      height: 1.3,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(Icons.payments_outlined, size: 16, color: Palette.blue),
                                      SizedBox(width: 6),
                                      Text(
                                        (SharedPreferenceHelper.getString(Preferences.currency_symbol) ?? '') + _formatAmount(course.amount),
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Palette.dark_blue,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }

  String _plainText(String? value) {
    if (value == null) return '';
    final stripped = value.replaceAll(RegExp(r'<[^>]*>'), '').trim();
    return stripped.isEmpty ? '-' : stripped;
  }

  String _formatAmount(num? amount) {
    final value = amount ?? 0;
    return value.toStringAsFixed(2);
  }

  Future<BaseModel<CoursesResponse>> callApiCourses() async {
    CoursesResponse response;
    setState(() {
      loading = true;
    });
    try {
      response = await RestClient(RetroApi2().dioData2()).coursesRequest();
      setState(() {
        loading = false;
        if (response.success == true) {
          courses = response.data ?? [];
        }
      });
    } catch (error, stacktrace) {
      setState(() {
        loading = false;
      });
      print("Exception occur: $error stackTrace: $stacktrace");
      return BaseModel()..setException(ServerError.withError(error: error));
    }
    return BaseModel()..data = response;
  }
}
