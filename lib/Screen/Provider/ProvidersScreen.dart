import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctro_patient/Screen/AppointmentRelatedScreen/Bookappointment.dart';
import 'package:doctro_patient/api/network_api.dart';
import 'package:doctro_patient/api/retrofit_Api.dart';
import 'package:doctro_patient/const/prefConstatnt.dart';
import 'package:doctro_patient/const/preference.dart';
import 'package:doctro_patient/model/providers_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../api/base_model.dart';
import '../../api/server_error.dart';
import '../../const/Palette.dart';
import '../../const/app_string.dart';
import '../../database/form_helper.dart';
import '../../localization/localization_constant.dart';

class ProvidersScreen extends StatefulWidget {
  @override
  _ProvidersScreenState createState() => _ProvidersScreenState();
}

class _ProvidersScreenState extends State<ProvidersScreen> {
  bool loading = false;
  String? _lat = "";
  String? _lang = "";
  List<ProviderModel> providers = [];

  @override
  void initState() {
    super.initState();
    _loadLocationAndProviders();
  }

  Future<void> _loadLocationAndProviders() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lat = prefs.getString('lat');
      _lang = prefs.getString('lang');
    });
    await _callApiProviders();
  }

  Future<BaseModel<Providers>> _callApiProviders() async {
    Providers response;
    final Map<String, dynamic> body = {
      "lat": _lat,
      "lang": _lang,
      "limit": 50,
    };
    setState(() {
      loading = true;
    });
    try {
      response = await RestClient(RetroApi2().dioData2()).providersRequest(body);
      setState(() {
        loading = false;
        providers.clear();
        if (response.data != null) {
          providers.addAll(response.data!);
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

  Future<void> _onRefresh() async {
    await _callApiProviders();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Palette.dark_white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Palette.white,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            size: 20,
            color: Palette.dark_blue,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Providers',
          style: TextStyle(
            fontSize: 18,
            color: Palette.dark_blue,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ModalProgressHUD(
        inAsyncCall: loading,
        opacity: 0.4,
        progressIndicator: SpinKitFadingCircle(
          color: Palette.blue,
          size: 50.0,
        ),
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: providers.isEmpty
              ? ListView(
                  children: [
                    SizedBox(height: height * 0.2),
                    Center(
                      child: Text(
                        getTranslated(context, AppString.home_notFound).toString(),
                        style: TextStyle(
                          fontSize: width * 0.04,
                          color: Palette.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: providers.length,
                  separatorBuilder: (_, __) => SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final provider = providers[index];
                    return GestureDetector(
                      onTap: () {
                        SharedPreferenceHelper.getBoolean(Preferences.is_logged_in) == true
                            ? Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BookAppointment(
                                    id: provider.id,
                                    isProvider: true,
                                  ),
                                ),
                              )
                            : FormHelper.showMessage(
                                context,
                                getTranslated(context, AppString.home_medicineOrder_alert_title).toString(),
                                getTranslated(context, AppString.home_medicineOrder_alert_text).toString(),
                                getTranslated(context, AppString.cancel).toString(),
                                () {
                                  Navigator.of(context).pop();
                                },
                                buttonText2: getTranslated(context, AppString.login).toString(),
                                isConfirmationDialog: true,
                                onPressed2: () {
                                  Navigator.pushNamed(context, 'SignIn');
                                },
                              );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Palette.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Palette.blue.withOpacity(0.06),
                              blurRadius: 16,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 90,
                              height: 90,
                              margin: const EdgeInsets.all(12),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: CachedNetworkImage(
                                  alignment: Alignment.center,
                                  imageUrl: provider.fullImage ?? provider.image ?? '',
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => SpinKitFadingCircle(color: Palette.blue),
                                  errorWidget: (context, url, error) => Image.asset(
                                    "assets/images/no_image.jpg",
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(4, 12, 12, 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            provider.name ?? '',
                                            style: TextStyle(
                                              fontSize: width * 0.045,
                                              color: Palette.dark_blue,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      provider.providerType?.name ?? 'Home service provider',
                                      style: TextStyle(
                                        fontSize: width * 0.035,
                                        color: Palette.grey,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 6),
                                    if ((provider.address ?? '').isNotEmpty)
                                      Text(
                                        provider.address!,
                                        style: TextStyle(
                                          fontSize: width * 0.032,
                                          color: Palette.grey,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        if ((provider.hourlyRate ?? 0) > 0)
                                          Text(
                                            '${SharedPreferenceHelper.getString(Preferences.currency_symbol) ?? ''}${provider.hourlyRate}/hr',
                                            style: TextStyle(
                                              fontSize: width * 0.035,
                                              color: Palette.blue,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          )
                                        else if ((provider.appointmentFees ?? '').isNotEmpty)
                                          Text(
                                            '${SharedPreferenceHelper.getString(Preferences.currency_symbol) ?? ''}${provider.appointmentFees}',
                                            style: TextStyle(
                                              fontSize: width * 0.035,
                                              color: Palette.blue,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        if (provider.distanceKm != null && provider.distanceKm!.isNotEmpty)
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.place_outlined,
                                                size: 16,
                                                color: Palette.grey,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                '${provider.distanceKm} km',
                                                style: TextStyle(
                                                  fontSize: width * 0.032,
                                                  color: Palette.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
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
}

