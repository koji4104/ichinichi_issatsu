import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '/constants.dart';

const double DEF_RADIUS = 3;
BorderRadiusGeometry DEF_BORDER_RADIUS = BorderRadius.circular(3);
BorderRadiusGeometry DEF_RADIUS_BOTTOMBAR = BorderRadius.circular(6);
const EdgeInsetsGeometry DEF_MENU_PADDING = EdgeInsets.fromLTRB(8, 16, 8, 0);

const double DEF_APPBAR_HEIGHT = 40.0;
const double DEF_VIEW_SCROLL_WIDTH = 40.0;
const double DEF_VIEW_PADDING_W = 20.0;
const double DEF_VIEW_PADDING_H = 60.0;

// 横書き
const EdgeInsetsGeometry DEF_VIEW_PADDING_TB =
    EdgeInsets.fromLTRB(DEF_VIEW_PADDING_W, 40, DEF_VIEW_PADDING_W, 40);
// 縦書き
const EdgeInsetsGeometry DEF_VIEW_PADDING_RL =
    EdgeInsets.fromLTRB(0, DEF_VIEW_PADDING_H + 10, 0, DEF_VIEW_PADDING_H - 10.0);

const ICON_BUTTON_SIZE = 24.0;

const double DEF_VIEW_LINE_WIDTH = DEF_VIEW_PADDING_W + DEF_VIEW_PADDING_W + 10;
const double DEF_VIEW_LINE_HEIGHT = DEF_VIEW_PADDING_H + DEF_VIEW_PADDING_H + 100;

// ON OFF button
Color btnOn = Colors.white;
Color btnNg = Colors.grey;
Color btnNl = Colors.white;

ThemeData myTheme = myLightTheme;
double myTextScale = 1.0;

Color COL_DARK_TEXT = Color(0xffFFFFFF);
Color COL_DARK_CARD = Color(0xff303030);
Color COL_DARK_BACK = Color(0xff000000);

Color COL_LIGHT_TEXT = Color(0xff000000);
Color COL_LIGHT_CARD = Color(0xffFFFFFF);
Color COL_LIGHT_BACK = Color(0xFFf8f8ff);

Color COL_TEST = Color(0xFF00FFFF);

Color COL_FLAG1 = Color(0xff0000FF);
Color COL_FLAG2 = Color(0xff00FF00);
Color COL_FLAG3 = Color(0xffFF0000);
Color COL_FLAG4 = Color(0xff00FFFF);
Color COL_FLAG5 = Color(0xffFF00FF);
Color COL_FLAG6 = Color(0xffFFFF00);

List<Color?> COL_FLAG_LIST = [
  null,
  COL_FLAG1,
  COL_FLAG2,
  COL_FLAG3,
  COL_FLAG4,
  COL_FLAG5,
  COL_FLAG6
];

TextStyle TEXTSTYLE_DARK_SMALL =
    ThemeData.dark().textTheme.bodySmall!.copyWith(fontSize: 12.0, color: COL_DARK_TEXT);
TextStyle TEXTSTYLE_DARK_MEDIUM =
    ThemeData.dark().textTheme.bodyMedium!.copyWith(fontSize: 14.0, color: COL_DARK_TEXT);
TextStyle TEXTSTYLE_DARK_LARGE =
    ThemeData.dark().textTheme.bodyLarge!.copyWith(fontSize: 16.0, color: COL_DARK_TEXT);

TextStyle TEXTSTYLE_LIGHT_SMALL =
    ThemeData.light().textTheme.bodySmall!.copyWith(fontSize: 12.0, color: COL_LIGHT_TEXT);
TextStyle TEXTSTYLE_LIGHT_MEDIUM =
    ThemeData.light().textTheme.bodyMedium!.copyWith(fontSize: 14.0, color: COL_LIGHT_TEXT);
TextStyle TEXTSTYLE_LIGHT_LARGE =
    ThemeData.light().textTheme.bodyLarge!.copyWith(fontSize: 16.0, color: COL_LIGHT_TEXT);

ThemeData myDarkTheme = ThemeData.dark().copyWith(
  pageTransitionsTheme: MyPageTransitionsTheme(),
  dialogBackgroundColor: COL_DARK_BACK,
  scaffoldBackgroundColor: COL_DARK_BACK,
  canvasColor: COL_DARK_CARD,
  cardColor: COL_DARK_CARD,
  disabledColor: Color(0xFF909090),
  primaryColor: Color(0xFF444444),
  primaryColorDark: Color(0xFF333333),
  dividerColor: Color(0xFF808080),
  highlightColor: Color(0xFF3366CC),
  iconTheme: IconThemeData(color: COL_DARK_TEXT),
  checkboxTheme: CheckboxThemeData(
    fillColor: WidgetStateProperty.all(Color(0xFF333333)),
    checkColor: WidgetStateProperty.all(Color(0xFFFFFFFF)),
    overlayColor: WidgetStateProperty.all(Color(0xFF555555)),
  ),
  textTheme: TextTheme(
    bodySmall: TEXTSTYLE_DARK_SMALL,
    bodyMedium: TEXTSTYLE_DARK_MEDIUM,
    bodyLarge: TEXTSTYLE_DARK_LARGE,
  ),
  buttonTheme: ButtonThemeData(
    buttonColor: Color(0xFF808080),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      textStyle: TEXTSTYLE_DARK_MEDIUM,
      foregroundColor: COL_DARK_TEXT,
      backgroundColor: COL_DARK_CARD,
      padding: EdgeInsets.fromLTRB(8, 0, 8, 0),
      shape: RoundedRectangleBorder(borderRadius: DEF_BORDER_RADIUS),
    ),
  ),
  iconButtonTheme: IconButtonThemeData(
    style: IconButton.styleFrom(
      foregroundColor: COL_DARK_TEXT,
      iconSize: ICON_BUTTON_SIZE,
      padding: EdgeInsets.all(0),
      minimumSize: Size(0, 0),
    ),
  ),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: Color(0xFF222222),
    actionTextColor: COL_DARK_TEXT,
    contentTextStyle: ThemeData.dark().textTheme.bodyMedium!.copyWith(),
  ),
  appBarTheme: AppBarTheme(
    iconTheme: IconThemeData(size: ICON_BUTTON_SIZE),
    backgroundColor: COL_DARK_BACK,
    titleTextStyle: ThemeData.dark().textTheme.bodyMedium!.copyWith(),
    toolbarHeight: DEF_APPBAR_HEIGHT,
  ),
);

ThemeData myLightTheme = ThemeData.light().copyWith(
  pageTransitionsTheme: MyPageTransitionsTheme(),
  dialogBackgroundColor: COL_LIGHT_BACK,
  scaffoldBackgroundColor: COL_LIGHT_BACK,
  canvasColor: COL_LIGHT_CARD,
  cardColor: COL_LIGHT_CARD,
  disabledColor: Color(0xFF808080),
  primaryColor: Color(0xFFffffff),
  dividerColor: Color(0xFFA0A0A0),
  highlightColor: Color(0xFFAADDFF),
  iconTheme: IconThemeData(color: COL_LIGHT_TEXT),
  checkboxTheme: CheckboxThemeData(
    fillColor: WidgetStateProperty.all(Color(0xFF333333)),
    checkColor: WidgetStateProperty.all(Color(0xFFFFFFFF)),
    overlayColor: WidgetStateProperty.all(Color(0xFF555555)),
  ),
  textTheme: TextTheme(
    bodySmall: TEXTSTYLE_LIGHT_SMALL,
    bodyMedium: TEXTSTYLE_LIGHT_MEDIUM,
    bodyLarge: TEXTSTYLE_LIGHT_LARGE,
  ),
  buttonTheme: ButtonThemeData(
    buttonColor: Color(0xFF808080),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      textStyle: TEXTSTYLE_LIGHT_MEDIUM,
      foregroundColor: COL_LIGHT_TEXT,
      backgroundColor: COL_LIGHT_CARD,
      padding: EdgeInsets.fromLTRB(8, 0, 8, 0),
      shape: RoundedRectangleBorder(borderRadius: DEF_BORDER_RADIUS),
    ),
  ),
  iconButtonTheme: IconButtonThemeData(
    style: IconButton.styleFrom(
      foregroundColor: COL_LIGHT_TEXT,
      iconSize: ICON_BUTTON_SIZE,
      padding: EdgeInsets.all(0),
      minimumSize: Size(0, 0),
    ),
  ),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: Color(0xFFeeeeee),
    actionTextColor: COL_LIGHT_TEXT,
    contentTextStyle:
        ThemeData.dark().textTheme.bodyMedium!.copyWith(fontSize: 14.0, color: COL_LIGHT_TEXT),
  ),
  appBarTheme: AppBarTheme(
    iconTheme: IconThemeData(size: ICON_BUTTON_SIZE),
    backgroundColor: COL_LIGHT_BACK,
    titleTextStyle: ThemeData.light().textTheme.bodyMedium!.copyWith(),
    toolbarHeight: DEF_APPBAR_HEIGHT,
  ),
);

// Swipe to cancel. From left to right.
class MyPageTransitionsTheme extends PageTransitionsTheme {
  const MyPageTransitionsTheme();

  static const PageTransitionsBuilder builder = CupertinoPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return builder.buildTransitions<T>(route, context, animation, secondaryAnimation, child);
  }
}

Widget MyText(String text, {int? maxLength, int? maxLines, bool? noScale, bool? center}) {
  double scale = myTextScale;
  if (noScale != null && scale > 1.3) {
    scale = 1.3;
  }
  if (maxLength == null) maxLength = 40;
  if (maxLines == null) maxLines = 2;
  if (text.length > maxLength) {
    text = text.substring(0, maxLength) + '...';
    scale -= 0.2;
  }
  return Text(
    text,
    overflow: TextOverflow.ellipsis,
    maxLines: maxLines,
    textScaler: TextScaler.linear(scale),
    textAlign: center != null ? TextAlign.center : null,
  );
}

Widget MyIconLabelButton({
  required Icon icon,
  String? label,
  Color? color,
  Function()? onPressed,
}) {
  return Column(children: [
    IconButton(
      icon: icon,
      color: color,
      onPressed: onPressed,
      padding: EdgeInsets.all(0),
    ),
    if (label != null)
      Text(
        label,
        style: TextStyle(color: color, fontSize: 9),
        textAlign: TextAlign.center,
      ),
  ]);
}

/// MyTextButton
/// - title
/// - onPressed
/// - width: default 300
Widget MyTextButton({
  required String title,
  required void Function()? onPressed,
  double? width,
  bool? commit,
  bool? delete,
  bool? noScale,
  double? scaleRatio,
}) {
  double fsize = myTheme.textTheme.bodyMedium!.fontSize!;
  Color? fgcol = myTheme.textTheme.bodyMedium!.color!;
  Color? bgcol = null;
  Color? bdcol = myTheme.dividerColor;

  if (commit != null) {
    fgcol = Color(0xFFFFFFFF);
    bgcol = Colors.blueAccent;
    bdcol = bgcol;
  } else if (delete != null) {
    fgcol = Color(0xFFFFFFFF);
    bgcol = Colors.redAccent;
    bdcol = bgcol;
  }
  double scale = myTextScale;
  if (noScale != null) {
    if (scale > 1.3) scale = 1.3;
  }
  if (scaleRatio != null) {
    scale *= scaleRatio;
  }

  return Container(
    width: width != null ? width : 300,
    child: TextButton(
      style: TextButton.styleFrom(
        backgroundColor: bgcol,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(DEF_RADIUS))),
        side: bdcol != null ? BorderSide(color: bdcol) : null,
      ),
      child: Text(
        title,
        style: TextStyle(color: fgcol, fontSize: fsize),
        textAlign: TextAlign.center,
        textScaler: TextScaler.linear(scale),
      ),
      onPressed: onPressed,
    ),
  );
}

/// MyListTile
/// - title1
/// - title2
/// - onPressed
/// - multiline: null or true
Widget MyListTile({
  required Widget title1,
  Widget? title2,
  Function()? onPressed,
  bool? multiline,
  bool? textonly,
}) {
  Widget e = Expanded(child: SizedBox(width: 8));
  if (multiline != null) e = SizedBox(width: 8);
  Widget w = SizedBox(width: 10);
  Icon icon = Icon(Icons.arrow_forward_ios, size: 14.0, color: myTheme.textTheme.bodyMedium!.color);

  Widget txt;
  if (textonly != null) {
    txt = title1;
  } else if (title2 != null && onPressed != null) {
    txt = Row(children: [title1, e, title2, w, icon]);
  } else if (onPressed != null) {
    txt = Row(children: [e, title1, e, w, icon]);
  } else {
    txt = Row(children: [e, title1, e]);
  }
  return Container(
    height: 50,
    padding: EdgeInsets.symmetric(vertical: 1, horizontal: 1),
    child: TextButton(child: txt, onPressed: onPressed),
  );
}

Widget MyTocTile({
  required Widget title1,
  required Widget title2,
  required Function() onPressed,
  bool? check,
}) {
  Widget e = Expanded(child: SizedBox(width: 1));
  Widget w = SizedBox(width: 16);
  Icon icon = Icon(Icons.arrow_forward_ios, size: 14.0, color: myTheme.textTheme.bodyMedium!.color);
  Icon icon1 = Icon(Icons.circle, size: 10.0, color: Colors.blueAccent);

  Widget txt = Row(children: [
    (check != null && check == true) ? icon1 : SizedBox(width: 10),
    SizedBox(width: 8),
    Expanded(child: title1),
    w,
    title2,
    w,
    icon,
  ]);
  return Container(
    decoration: BoxDecoration(
      color: myTheme.cardColor,
      border: Border(bottom: BorderSide(color: myTheme.dividerColor, width: 0.5)),
    ),
    padding: EdgeInsets.fromLTRB(16, 1, 4, 1),
    child: TextButton(child: txt, onPressed: onPressed),
  );
}

Widget MyClipListTile({required String text, Function()? onPressed}) {
  Widget btn = IconButton(
    icon: Icon(Icons.delete, size: 24, color: myTheme.textTheme.bodyMedium!.color),
    onPressed: onPressed,
  );

  Widget wText = Text(
    text,
    maxLines: 10,
    overflow: TextOverflow.clip,
    textScaler: TextScaler.linear(myTextScale),
  );

  Widget child = Row(children: [
    Expanded(child: wText),
  ]);
  return Container(
    decoration: BoxDecoration(
      color: myTheme.cardColor,
      border: Border(bottom: BorderSide(color: myTheme.dividerColor, width: 1)),
    ),
    padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
    child: child,
  );
}

class MySlidableAction extends StatelessWidget {
  const MySlidableAction({
    super.key,
    required this.backgroundColor,
    this.foregroundColor,
    required this.onPressed,
    this.icon,
    this.label,
    this.borderRadius = BorderRadius.zero,
    this.spacing = 1.0,
    this.padding,
  });

  final int flex = 1;
  final Color backgroundColor;
  final Color? foregroundColor;
  final SlidableActionCallback? onPressed;
  final IconData? icon;
  final double spacing;
  final String? label;
  final EdgeInsets? padding;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    if (icon != null) {
      children.add(SizedBox(height: 4));
      children.add(
        Icon(icon, size: 20, color: foregroundColor),
      );
    }

    if (label != null) {
      if (children.isNotEmpty) {
        children.add(SizedBox(height: 4));
      }

      children.add(
        Text(
          label!,
          style: TextStyle(fontSize: 9),
          textAlign: TextAlign.center,
        ),
      );
    }

    final child = children.length == 1
        ? children.first
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...children.map(
                (child) => Flexible(
                  child: child,
                ),
              )
            ],
          );

    return CustomSlidableAction(
      borderRadius: BorderRadius.zero,
      padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
      onPressed: onPressed,
      autoClose: false,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      flex: flex,
      child: child,
    );
  }
}
