import 'package:bhagavad_gita/Constant/app_colors.dart';
import 'package:bhagavad_gita/Constant/app_size_config.dart';
import 'package:bhagavad_gita/Constant/http_link_string.dart';
import 'package:bhagavad_gita/Constant/static_model.dart';
import 'package:bhagavad_gita/Constant/string_constant.dart';
import 'package:bhagavad_gita/models/color_selection_model.dart';
import 'package:bhagavad_gita/localization/demo_localization.dart';
import 'package:bhagavad_gita/models/notes_model.dart';
import 'package:bhagavad_gita/models/verse_detail_model.dart';
import 'package:bhagavad_gita/routes/route_names.dart';
import 'package:bhagavad_gita/screens/bottom_navigation_menu/bottom_navigation_screen.dart';
import 'package:bhagavad_gita/screens/setting_screens/open_setting_screen.dart';
import 'package:bhagavad_gita/services/navigator_service.dart';
import 'package:bhagavad_gita/services/shared_preferences.dart';
import 'package:bhagavad_gita/widgets/add_notes_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_share/flutter_share.dart';
import 'package:flutter_svg/svg.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../locator.dart';

class ContinueReading extends StatefulWidget {
  const ContinueReading({
    Key? key,
    required this.verseID,
  }) : super(key: key);

  @override
  _ContinueReadingState createState() => _ContinueReadingState();
  final String verseID;
}

class _ContinueReadingState extends State<ContinueReading> {
  final NavigationService navigationService = locator<NavigationService>();
  final HttpLink httpLink = HttpLink(strGitaHttpLink);
  late ValueNotifier<GraphQLClient> client;
  late String verseDetailQuery;

  bool isVerseSaved = false;
  VerseNotes? verseNotes;
  int versId = 1;

  LastReadVerse? lastReadVerse;

  //// Customisation
  double lineSpacing = 1.5;
  String fontFamily = 'Inter';
  double fontSize = 16;
  FormatingColor formatingColor = whiteFormatingColor;
  late VerseCustomissation verseCustomissation;

  bool showTraliteration = true;
  bool showTranslation = true;
  bool showCommentry = true;

  @override
  void initState() {
    super.initState();
    setState(() {
      versId = int.parse(widget.verseID);
      getVersDetails();
    });

    SharedPref.getSavedVerseListCustomisation().then((value) {
      verseCustomissation = value;
      setState(() {
        lineSpacing = value.lineSpacing;
        fontFamily = value.fontfamily;
        fontSize = value.fontsize.toDouble();
        if (value.colorId == "1") {
          formatingColor = whiteFormatingColor;
        } else if (value.colorId == "2") {
          formatingColor = orangeFormatingColor;
        } else if (value.colorId == "3") {
          formatingColor = blackFormatingColor;
        }
      });
    });

    getAllToggelValueFormShowingContent();
  }

  getAllToggelValueFormShowingContent() {
    SharedPref.getSavedBoolValue(PreferenceConstant.verseTransliterationSetting)
        .then((value) {
      setState(() {
        showTraliteration = value;
      });
    });
    SharedPref.getSavedBoolValue(PreferenceConstant.verseTranslationSetting)
        .then((value) {
      setState(() {
        showTranslation = value;
      });
    });
    SharedPref.getSavedBoolValue(PreferenceConstant.verseCommentarySetting)
        .then((value) {
      setState(() {
        showCommentry = value;
      });
    });
  }

  getVersDetails() {
    client = ValueNotifier<GraphQLClient>(
        GraphQLClient(link: httpLink, cache: GraphQLCache()));

    print('object-------$versId');
    //print("Languade : ${savedVerseTranslation.language}");
    String language1 = savedVerseTranslation.language ?? "english";
    String language2 = savedVerseCommentary.language ?? "english";

    String auther1 = savedVerseTranslation.authorName ?? "Swami Sivananda";
    String auther2 = savedVerseCommentary.authorName ?? "Swami Sivananda";

    verseDetailQuery = """
  query GetVerseDetailsById {
    gitaVerseById(id: $versId) {
      chapterNumber
      verseNumber
      text
      gitaTranslationsByVerseId(condition: { language: "$language1", authorName: "$auther1" }) {
        nodes {
          description
        }
      }
      gitaCommentariesByVerseId(condition: { language: "$language2", authorName: "$auther2" }) {
        nodes {
          description
        }
      }
    }
  }
  """;

    print("Query : $verseDetailQuery");
    getVerseNotes();
  }

  getVerseNotes() {
    setState(() {
      isVerseSaved = false;
      verseNotes = null;
    });
    Future.delayed(Duration(milliseconds: 200), () async {
      var result = await SharedPref.checkVerseIsSavedOrNot("$versId");
      var resultVerseNotes =
          await SharedPref.checkVerseNotesIsSavedOrNot("$versId");
      setState(() {
        isVerseSaved = result;
        verseNotes = resultVerseNotes;
      });
    });
  }

  changeVersePage() {
    setState(() {
      versId = versId + 1;
      getVersDetails();
    });
  }

  reverschangeVersePage() {
    setState(() {
      versId = versId - 1;
      getVersDetails();
    });
  }

  Future<void> shareVerse() async {
    await FlutterShare.share(
      title: 'Transaltion',
      text: lastReadVerse!.gitaVerseById!.gitaTranslationsByVerseId!.nodes![0]
              .description ??
          "",
      linkUrl: "https://bhagavadgita.graphcdn.app/",
    );
  }

  @override
  Widget build(BuildContext context) {
    height = MediaQuery.of(context).size.height;
    width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: false,
        backgroundColor: formatingColor.bgColor,
        leading: InkWell(
          onTap: () {
            Navigator.of(context).pop(true);
          },
          child: Center(
            child: SvgPicture.asset("assets/icons/icon_back_arrow.svg",
                width: 20, color: formatingColor.naviagationIconColor),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                print('Bottom Navigation Menu');
                _onPressedEditButton(context);
              });
            },
            child: Text(
              StringConstant.strAa,
              style: Theme.of(context).textTheme.headline1!.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w100,
                  color: formatingColor.naviagationIconColor),
            ),
          ),
          SizedBox(
            width: kPadding,
          ),
          InkWell(
            onTap: () async {
              var temp = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingScreen(),
                ),
              );
              if (temp) {
                getAllToggelValueFormShowingContent();
                setState(() {
                  getVersDetails();
                });
              }
            },
            child: Container(
              width: 40,
              child: Center(
                child: SvgPicture.asset('assets/icons/icon_setting_nonsele.svg',
                    color: formatingColor.naviagationIconColor),
              ),
            ),
          ),
          SizedBox(
            width: kDefaultPadding,
          )
        ],
      ),
      backgroundColor: formatingColor.bgColor,
      body: GraphQLProvider(
        client: client,
        child: SafeArea(
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              SingleChildScrollView(
                child: Query(
                  options: QueryOptions(document: gql(verseDetailQuery)),
                  builder: (
                    QueryResult result, {
                    Refetch? refetch,
                    FetchMore? fetchMore,
                  }) {
                    if (result.hasException) {
                      print("ERROR : ${result.exception.toString()}");
                    }
                    if (result.data == null) {
                      return Container(
                        height: 200,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: primaryColor,
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    }
                    print("SSSSSS : ${result.data}");
                    Map<String, dynamic>? verse = result.data;
                    VerseDetailData data = VerseDetailData.fromJson(verse!);
                    if (data.gitaVerseById == null) {
                      return Container();
                    }
                    lastReadVerse = LastReadVerse(
                        verseID: widget.verseID,
                        gitaVerseById: data.gitaVerseById!);
                    SharedPref.saveLastRead(lastReadVerse!);
                    return Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: kDefaultPadding),
                      child: Column(
                        children: [
                          SizedBox(
                            height: kDefaultPadding,
                          ),
                          Text(
                              "${data.gitaVerseById!.chapterNumber ?? 0}.${data.gitaVerseById!.verseNumber}",
                              style: Theme.of(context)
                                  .textTheme
                                  .headline1!
                                  .copyWith(
                                      fontFamily: fontFamily,
                                      fontSize: fontSize + 10,
                                      color: formatingColor.textColor)),
                          SizedBox(
                            height: kDefaultPadding,
                          ),
                          Text(
                            "${data.gitaVerseById!.text}",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontFamily: fontFamily,
                                color: formatingColor.style1,
                                fontSize: fontSize,
                                fontWeight: FontWeight.w400),
                          ),
                          showTraliteration
                              ? Column(
                                  children: [
                                    SizedBox(
                                      height: kPadding * 3,
                                    ),
                                    Text(
                                      "dhṛitarāśhtra uvācha\ndharma-kṣhetre kuru-kṣhetre\nsamavetā yuyutsavaḥ\nmāmakāḥ pāṇḍavāśhchaiva\nkimakurvata sañjaya",
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .subtitle1!
                                          .copyWith(
                                              fontSize: fontSize,
                                              height: lineSpacing,
                                              color: formatingColor.textColor,
                                              fontFamily: fontFamily),
                                    ),
                                    SizedBox(
                                      height: kDefaultPadding * 2,
                                    ),
                                    Text(
                                      "dhṛitarāśhtraḥ uvācha—Dhritarashtra said;\ndharma-kṣhetre—the land of dharma;\nkuru-kṣhetre—at Kurukshetra;\nsamavetāḥ—having gathered;\nyuyutsavaḥ—desiring to fight;\nmāmakāḥ—my sons; pāṇḍavāḥ—the sons\nof Pandu; cha—and; eva—certainly;\nkim—what; akurvata—did they do;\nsañjaya—Sanjay",
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .subtitle1!
                                          .copyWith(
                                              fontSize: fontSize,
                                              height: lineSpacing,
                                              color: formatingColor.textColor,
                                              fontFamily: fontFamily),
                                    ),
                                    SizedBox(height: kDefaultPadding * 2)
                                  ],
                                )
                              : Text(''),
                          showTranslation
                              ? Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SvgPicture.asset(
                                            "assets/icons/icon_left_rtansection.svg"),
                                        SizedBox(width: kDefaultPadding),
                                        Text(
                                          DemoLocalization.of(context)!
                                              .getTranslatedValue('translation')
                                              .toString(),
                                          style: Theme.of(context)
                                              .textTheme
                                              .subtitle1!
                                              .copyWith(
                                                fontFamily: fontFamily,
                                                fontSize: fontSize - 2,
                                                color: formatingColor.textColor,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                        SizedBox(width: kDefaultPadding),
                                        SvgPicture.asset(
                                            "assets/icons/icon_right_translation.svg")
                                      ],
                                    ),
                                    SizedBox(height: kDefaultPadding),
                                    Text(
                                      data
                                                  .gitaVerseById!
                                                  .gitaTranslationsByVerseId!
                                                  .nodes!
                                                  .length >
                                              0
                                          ? data
                                              .gitaVerseById!
                                              .gitaTranslationsByVerseId!
                                              .nodes![0]
                                              .description!
                                          : "---",
                                      style: Theme.of(context)
                                          .textTheme
                                          .subtitle1!
                                          .copyWith(
                                              height: lineSpacing,
                                              fontSize: fontSize,
                                              color: formatingColor.textColor,
                                              fontFamily: fontFamily),
                                    ),
                                  ],
                                )
                              : Text(''),
                          SizedBox(height: kDefaultPadding * 2),
                          showCommentry
                              ? Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SvgPicture.asset(
                                            "assets/icons/icon_left_rtansection.svg"),
                                        SizedBox(width: kDefaultPadding),
                                        Text(
                                          DemoLocalization.of(context)!
                                              .getTranslatedValue('commentry')
                                              .toString(),
                                          style: Theme.of(context)
                                              .textTheme
                                              .subtitle1!
                                              .copyWith(
                                                  fontFamily: fontFamily,
                                                  fontSize: fontSize - 2,
                                                  color:
                                                      formatingColor.textColor,
                                                  fontWeight: FontWeight.w700),
                                        ),
                                        SizedBox(width: kDefaultPadding),
                                        SvgPicture.asset(
                                            "assets/icons/icon_right_translation.svg")
                                      ],
                                    ),
                                    SizedBox(
                                      height: kDefaultPadding,
                                    ),
                                    Text(
                                      data
                                                  .gitaVerseById!
                                                  .gitaCommentariesByVerseId!
                                                  .nodes!
                                                  .length >
                                              0
                                          ? data
                                              .gitaVerseById!
                                              .gitaCommentariesByVerseId!
                                              .nodes![0]
                                              .description!
                                          : "---",
                                      style: Theme.of(context)
                                          .textTheme
                                          .subtitle1!
                                          .copyWith(
                                              height: lineSpacing,
                                              fontSize: fontSize,
                                              color: formatingColor.textColor,
                                              fontFamily: fontFamily),
                                    ),
                                  ],
                                )
                              : Container(),
                          SizedBox(height: kDefaultPadding * 5)
                        ],
                      ),
                    );
                  },
                ),
              ),
              versId == 1
                  ? Container()
                  : Positioned(
                      top: MediaQuery.of(context).size.height / 100 * 71,
                      left: kDefaultPadding,
                      child: Container(
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                          color: whiteColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: editBoxBorderColor,
                              blurRadius: 10,
                            )
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          shape: CircleBorder(),
                          clipBehavior: Clip.hardEdge,
                          child: InkWell(
                            onTap: () {
                              versId == 1
                                  ? versId = 1
                                  : reverschangeVersePage();
                            },
                            child: Expanded(
                              child: Center(
                                child: SvgPicture.asset(
                                  "assets/icons/icon_slider_verse.svg",
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
              versId == 701
                  ? Container()
                  : Positioned(
                      top: MediaQuery.of(context).size.height / 100 * 71,
                      right: kDefaultPadding,
                      child: Container(
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                          color: whiteColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: editBoxBorderColor,
                              blurRadius: 10,
                            )
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          shape: CircleBorder(),
                          clipBehavior: Clip.hardEdge,
                          child: InkWell(
                            onTap: () {
                              changeVersePage();
                            },
                            child: Expanded(
                              child: Center(
                                child: SvgPicture.asset(
                                  "assets/icons/Icon_slider_verseNext.svg",
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
      //   changeVersePage
      bottomNavigationBar: BottomAppBar(
        elevation: 15,
        child: Container(
          height: 48,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              InkWell(
                onTap: () {
                  navigationService.pushNamed(r_ChapterTableView);
                },
                child: Container(
                  height: 48,
                  width: 70,
                  child: Center(
                    child:
                        SvgPicture.asset("assets/icons/Icon_menu_bottom.svg"),
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  shareVerse();
                },
                child: Container(
                  height: 48,
                  width: 70,
                  child: Center(
                    child:
                        SvgPicture.asset("assets/icons/Icon_shear_bottom.svg"),
                  ),
                ),
              ),
              InkWell(
                onTap: () async {
                  if (verseNotes == null) {
                    VerseNotes temp = VerseNotes(
                        verseID: widget.verseID,
                        gitaVerseById: lastReadVerse!.gitaVerseById,
                        verseNote: "");
                    bool saved = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddNotesWidget(verseNotes: temp),
                      ),
                    );
                    if (saved) {
                      getVerseNotes();
                    }
                  } else {
                    bool saved = await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              AddNotesWidget(verseNotes: verseNotes!)),
                    );
                    if (saved) {
                      getVerseNotes();
                    }
                  }
                },
                child: Container(
                  height: 48,
                  width: 70,
                  child: Center(
                      child: verseNotes == null
                          ? SvgPicture.asset(
                              "assets/icons/Icon_write_bottom.svg")
                          : SvgPicture.asset(
                              'assets/icons/Icon_fill_addNote.svg')),
                ),
              ),
              InkWell(
                onTap: () async {
                  if (lastReadVerse != null) {
                    if (isVerseSaved) {
                      await SharedPref.removeVerseFromSaved(widget.verseID);
                      setState(() {
                        isVerseSaved = !isVerseSaved;
                      });
                    } else {
                      await SharedPref.saveBookmarkVerse(lastReadVerse!);
                      setState(() {
                        isVerseSaved = !isVerseSaved;
                      });
                    }
                  }
                },
                child: Container(
                  height: 48,
                  width: 70,
                  child: Center(
                    child: isVerseSaved
                        ? SvgPicture.asset("assets/icons/Icon_saved_bottom.svg")
                        : SvgPicture.asset("assets/icons/Icon_save_bottom.svg"),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _onPressedEditButton(context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          color: Color(0XFF737373),
          height: 350,
          child: Container(
            child: BottomNavigationMenu(
              lineSpacing: (double value) {
                setState(() {
                  lineSpacing = value;
                });
                verseCustomissation.lineSpacing = value;
                SharedPref.saveVerseListCustomisation(verseCustomissation);
              },
              initialLineSpacing: lineSpacing,
              selectedFontFamily: (String strFontFamily) {
                setState(() {
                  fontFamily = strFontFamily;
                });
                verseCustomissation.fontfamily = strFontFamily;
                SharedPref.saveVerseListCustomisation(verseCustomissation);
              },
              selectedFontSize: (int) {},
              fontName: fontFamily,
              fontSizeIncrease: (bool increase) {
                if (increase) {
                  setState(() {
                    fontSize = fontSize + 1;
                  });
                } else {
                  setState(() {
                    fontSize = fontSize - 1;
                  });
                }
                verseCustomissation.fontsize = fontSize.toInt();
                SharedPref.saveVerseListCustomisation(verseCustomissation);
              },
              formatingColorSelection: (FormatingColor colorMode) {
                setState(() {
                  formatingColor = colorMode;
                });
                verseCustomissation.colorId = colorMode.id;
                SharedPref.saveVerseListCustomisation(verseCustomissation);
              },
              formatingColor: formatingColor,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).canvasColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
          ),
        );
      },
    );
  }
}
