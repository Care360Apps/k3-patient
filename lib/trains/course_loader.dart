import '../api/retrofit_Api.dart';
import '../api/network_api.dart';
import '../model/course_model.dart';

Future<List<CourseData>> loadTrainsCourses() async {
  final response = await RestClient(RetroApi().dioData()).coursesRequest();
  if (response.success != true) throw StateError('Catalogue unavailable');
  return response.data ?? [];
}
