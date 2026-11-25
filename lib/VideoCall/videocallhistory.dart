import 'package:cached_network_image/cached_network_image.dart';
import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import 'package:doctro_patient/Chat/loading_view.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import '../Screen/AppointmentRelatedScreen/Bookappointment.dart';
import '../api/retrofit_Api.dart';
import '../api/base_model.dart';
import '../api/network_api.dart';
import '../api/server_error.dart';
import '../const/Palette.dart';
import '../const/app_string.dart';
import '../localization/localization_constant.dart';
import '../model/show_video_call_history_model.dart';

class VideoCallHistory extends StatefulWidget {
  const VideoCallHistory({Key? key}) : super(key: key);

  @override
  _VideoCallHistoryState createState() => _VideoCallHistoryState();
}

class _VideoCallHistoryState extends State<VideoCallHistory> {
  bool loading = false;
  List<Data> callHistory = [];
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    callApiShowVideoCallHistory();
  }

  @override
  Widget build(BuildContext context) {
    double width;
    double height;
    width = MediaQuery.of(context).size.width;
    height = MediaQuery.of(context).size.height;
    return ModalProgressHUD(
      inAsyncCall: loading,
      opacity: 0,
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
            getTranslated(context, AppString.call_history).toString(),
            style: TextStyle(fontSize: 18, color: Palette.dark_blue, fontWeight: FontWeight.bold),
          ),
        ),
        body: loading && callHistory.isEmpty
            ? const SizedBox.shrink()
            : _loadFailed
                ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Text('Unable to load call history.'),
                    TextButton(onPressed: callApiShowVideoCallHistory, child: const Text('Retry')),
                  ]))
                : callHistory.isNotEmpty
            ? ListView.builder(
                itemCount: callHistory.length,
                scrollDirection: Axis.vertical,
                itemBuilder: (context, index) {
                  final entry = callHistory[index];
                  final seconds = int.tryParse(entry.duration ?? '');
                  final elapsed = Duration(seconds: seconds != null && seconds >= 0 ? seconds : 0);
                  final duration = seconds == null || seconds < 0
                      ? '—'
                      : '${elapsed.inHours}h ${elapsed.inMinutes.remainder(60)}m ${elapsed.inSeconds.remainder(60)}s';
                  final date = DateTime.tryParse(entry.date ?? '');
                  return Column(
                    children: [
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: width * 0.01, vertical: width * 0.02),
                        child: Row(
                          children: [
                            Container(
                              width: width * 0.15,
                              alignment: AlignmentDirectional.center,
                              margin: EdgeInsets.symmetric(horizontal: width * 0.01, vertical: width * 0.02),
                              child: Column(
                                children: [
                                  SizedBox(
                                    width: width * 0.15,
                                    height: height * 0.065,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: CachedNetworkImage(
                                        alignment: Alignment.center,
                                        imageUrl: entry.doctor?.fullImage ?? '',
                                        fit: BoxFit.fitHeight,
                                        placeholder: (context, url) => const SpinKitFadingCircle(color: Palette.blue),
                                        errorWidget: (context, url, error) => ClipRRect(
                                          borderRadius: BorderRadius.circular(15),
                                          child: Image.asset("assets/images/no_image.jpg"),
                                        ),
                                        width: width * 0.15,
                                        height: height * 0.065,
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                            SizedBox(
                              width: width * 0.8,
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                child: Column(
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 5),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            entry.doctor?.name ?? '—',
                                            style: TextStyle(fontSize: width * 0.04, color: Palette.dark_blue, fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            entry.startTime?.toLowerCase() ?? '—',
                                            style: TextStyle(
                                              fontSize: width * 0.03,
                                              color: Palette.dark_blue,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      alignment: AlignmentDirectional.topStart,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "$duration",
                                            style: TextStyle(
                                              fontSize: width * 0.035,
                                              color: Palette.dark_blue,
                                            ),
                                          ),
                                          Text(
                                            date == null ? '—' : DateUtil().formattedDate(date),
                                            style: TextStyle(
                                              fontSize: width * 0.035,
                                              color: Palette.dark_blue,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        child: Column(
                          children: const [
                            DottedLine(
                              direction: Axis.horizontal,
                              lineLength: double.infinity,
                              lineThickness: 1.0,
                              dashLength: 3.0,
                              dashColor: Palette.blue,
                              dashRadius: 0.0,
                              dashGapLength: 1.0,
                              dashGapColor: Palette.transparent,
                              dashGapRadius: 0.0,
                            )
                          ],
                        ),
                      ),
                    ],
                  );
                },
              )
            : Container(
                child: Center(
                  child: Text(
                    getTranslated(context, AppString.no_callHistory).toString(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Palette.dark_blue,
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Future<BaseModel<ShowVideoCallHistoryModel>> callApiShowVideoCallHistory() async {
    if (!mounted || loading) return BaseModel();
    setState(() {
      loading = true;
      _loadFailed = false;
    });
    try {
      final response = await RestClient(RetroApi().dioData()).showVideoCallHistoryRequest();
      if (mounted) {
        setState(() {
          _loadFailed = response.success != true || response.data == null;
          if (!_loadFailed) {
            callHistory = response.data!.reversed.toList();
          }
        });
      }
      return BaseModel()..data = response;
    } catch (error) {
      if (mounted) setState(() => _loadFailed = true);
      return BaseModel()..setException(ServerError.withError(error: error));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }
}
