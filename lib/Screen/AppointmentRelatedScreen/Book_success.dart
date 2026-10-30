import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../const/Palette.dart';
import '../../const/app_string.dart';
import '../../localization/localization_constant.dart';

class BookSuccess extends StatefulWidget {
  @override
  _BookSuccessState createState() => _BookSuccessState();
}

class _BookSuccessState extends State<BookSuccess> {
  String? passBookDate = "";
  String? passBookTime = "";
  String? passBookID = "";
  bool isProviderBooking = false;

  @override
  void initState() {
    super.initState();
    getDateTime();
    new Future.delayed(const Duration(seconds: 5), () {
      Navigator.pushReplacementNamed(context, 'Appointment');
    });
  }

  getDateTime() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      passBookDate = prefs.getString('BookDate');
      passBookTime = prefs.getString('BookTime');
      passBookID = prefs.getString('BookID');
      isProviderBooking = prefs.getString('BookIsProvider') == '1';
    });
  }

  @override
  Widget build(BuildContext context) {
    double width;
    width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Palette.dark_white, Palette.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: GestureDetector(
              onTap: () {
                FocusScope.of(context).requestFocus(new FocusNode());
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 24,
                  ),
                  decoration: BoxDecoration(
                    color: Palette.white,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: Palette.blue.withOpacity(0.12),
                        blurRadius: 24,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: width * 0.18,
                        width: width * 0.18,
                        decoration: BoxDecoration(
                          color: Palette.tabBar,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          color: Palette.blue,
                          size: width * 0.1,
                        ),
                      ),
                      SizedBox(height: width * 0.04),
                      Image.asset(
                        'assets/images/paysuccess.png',
                        height: width * 0.42,
                        width: width * 0.62,
                        fit: BoxFit.contain,
                      ),
                      SizedBox(height: width * 0.04),
                      Text(
                        getTranslated(
                          context,
                          isProviderBooking
                              ? AppString.bookSuccess_text_provider
                              : AppString.bookSuccess_text,
                        ).toString(),
                        style: TextStyle(
                          fontSize: width * 0.05,
                          color: Palette.dark_blue,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: width * 0.05),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildInfoPill(width: width, text: '$passBookDate'),
                          SizedBox(width: width * 0.03),
                          _buildInfoPill(width: width, text: '$passBookTime'),
                        ],
                      ),
                      SizedBox(height: width * 0.05),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Palette.dark_white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              getTranslated(
                                context,
                                AppString.bookSuccess_bookingId,
                              ).toString(),
                              style: TextStyle(
                                fontSize: width * 0.035,
                                color: Palette.dark_blue,
                              ),
                            ),
                            Text(
                              ' $passBookID',
                              style: TextStyle(
                                fontSize: width * 0.035,
                                color: Palette.blue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoPill({required double width, required String text}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: width * 0.04,
        vertical: width * 0.025,
      ),
      decoration: BoxDecoration(
        color: Palette.blue,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Palette.blue.withOpacity(0.2),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: width * 0.03,
          color: Palette.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
