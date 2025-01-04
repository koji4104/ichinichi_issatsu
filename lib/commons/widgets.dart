import 'package:flutter/material.dart';
import 'dart:io';

BorderRadiusGeometry DEF_BORDER_RADIUS = BorderRadius.circular(3);
const EdgeInsetsGeometry DEF_MENU_PADDING = EdgeInsets.fromLTRB(8, 16, 8, 0);

const double DEF_APPBAR_HEIGHT = 40.0;
const double DEF_VIEW_SCROLL_WIDTH = 40.0;
const double DEF_VIEW_PADDING_W = 30.0;
const double DEF_VIEW_PADDING_H = 40.0;
const EdgeInsetsGeometry DEF_VIEW_PADDING_TB =
    EdgeInsets.fromLTRB(DEF_VIEW_PADDING_W, 0, DEF_VIEW_PADDING_W, 0);
const EdgeInsetsGeometry DEF_VIEW_PADDING_RL =
    EdgeInsets.fromLTRB(0, DEF_VIEW_PADDING_H, 0, DEF_VIEW_PADDING_H);

const double DEF_VIEW_LINE_WIDTH = DEF_VIEW_PADDING_W + DEF_VIEW_PADDING_W + 4;
const double DEF_VIEW_LINE_HEIGHT = DEF_VIEW_PADDING_H + DEF_VIEW_PADDING_H + DEF_APPBAR_HEIGHT + 4;

// ON OFF button
Color btnOn = Colors.white;
Color btnNg = Colors.grey;
Color btnNl = Colors.white;

ThemeData myTheme = myLightTheme;

Color COL_DARK_TEXT = Color(0xffFFFFFF);
Color COL_DARK_CARD = Color(0xff333333);
Color COL_DARK_BACK = Color(0xff000000);

Color COL_LIGHT_TEXT = Color(0xff000000);
Color COL_LIGHT_CARD = Color(0xffFFFFFF);
Color COL_LIGHT_BACK = Color(0xffe0e0e0);

Color COL_TEST = Color(0xFF00FFFF);

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

/// e.g.
/// - myTheme.backgroundColor
/// - myTheme.cardColor
/// - myTheme.textTheme.bodyMedium (size 14)
/// - myTheme.textTheme.titleMedium (size 16)
ThemeData myDarkTheme = ThemeData.dark().copyWith(
  pageTransitionsTheme: MyPageTransitionsTheme(),
  dialogBackgroundColor: COL_DARK_BACK,
  scaffoldBackgroundColor: COL_DARK_BACK,
  canvasColor: COL_DARK_CARD,
  cardColor: COL_DARK_CARD,
  disabledColor: COL_DARK_TEXT,
  primaryColor: Color(0xFF444444),
  primaryColorDark: Color(0xFF333333),
  dividerColor: Color(0xFF808080),
  highlightColor: Color(0xFF3366CC),
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
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: COL_DARK_TEXT,
      backgroundColor: COL_DARK_CARD,
      shape: RoundedRectangleBorder(borderRadius: DEF_BORDER_RADIUS),
    ),
  ),
  iconButtonTheme: IconButtonThemeData(
    style: IconButton.styleFrom(
      iconSize: 28,
      foregroundColor: COL_DARK_TEXT,
      backgroundColor: Colors.black.withOpacity(0.0),
      //padding: EdgeInsets.fromLTRB(2, 2, 2, 2),
      //shape: RoundedRectangleBorder(borderRadius: DEF_BORDER_RADIUS),
    ),
  ),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: Color(0xFF222222),
    actionTextColor: COL_DARK_TEXT,
    contentTextStyle: ThemeData.dark().textTheme.bodyMedium!.copyWith(),
  ),
  appBarTheme: AppBarTheme(
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
  disabledColor: COL_LIGHT_TEXT,
  primaryColor: Color(0xFFffffff),
  dividerColor: Color(0xFF808080),
  highlightColor: Color(0xFFAADDFF),
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
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      padding: EdgeInsets.fromLTRB(8, 0, 8, 0),
      foregroundColor: COL_LIGHT_TEXT,
      backgroundColor: COL_LIGHT_CARD,
      shape: RoundedRectangleBorder(borderRadius: DEF_BORDER_RADIUS),
    ),
  ),
  iconButtonTheme: IconButtonThemeData(
    style: IconButton.styleFrom(
      iconSize: 28,
      foregroundColor: COL_LIGHT_TEXT,
      //backgroundColor: COL_LIGHT_BACK,
      //padding: EdgeInsets.fromLTRB(8, 8, 8, 8),
      //shape: RoundedRectangleBorder(borderRadius: DEF_BORDER_RADIUS),
    ),
  ),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: Color(0xFFeeeeee),
    actionTextColor: COL_LIGHT_TEXT,
    contentTextStyle:
        ThemeData.dark().textTheme.bodyMedium!.copyWith(fontSize: 14.0, color: COL_LIGHT_TEXT),
  ),
  appBarTheme: AppBarTheme(
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

Widget MyLabel(String label, {int? size, Color? color}) {
  return Align(
    alignment: Alignment.centerLeft,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Text(label, style: TextStyle(fontSize: 14, color: Colors.white)),
    ),
  );
}

Widget MyText(String text) {
  if (text.length > 40) text = text.substring(0, 40) + '...';
  return Text(text, overflow: TextOverflow.ellipsis);
}

/// Invert colors with frame
Widget MyIconButton({
  required IconData icon,
  double? iconSize,
  required void Function()? onPressed,
}) {
  if (iconSize == null) iconSize = 24;
  return IconButton(
    icon: Icon(icon),
    style: IconButton.styleFrom(
      iconSize: iconSize,
      //fixedSize: Size(21, 21),
      //maximumSize: Size(22, 22),
      foregroundColor: myTheme.cardColor,
      backgroundColor: myTheme.textTheme.bodyMedium!.color!,
      padding: EdgeInsets.all(0),
      shape: RoundedRectangleBorder(borderRadius: DEF_BORDER_RADIUS),
    ),
    onPressed: onPressed,
  );
}

/// MyTextButton
/// - title
/// - onPressed
/// - width: default 300
Widget MyTextButton({
  required String title,
  required void Function()? onPressed,
  double? width,
  Icon? icon,
  bool? cancelStyle,
  bool? deleteStyle,
}) {
  Color fgcol = myTheme.cardColor;
  Color bgcol = myTheme.textTheme.bodyMedium!.color!;
  double fsize = myTheme.textTheme.bodyMedium!.fontSize!;
  if (cancelStyle != null && cancelStyle == true) {
    fgcol = Color(0xFFFFFFFF);
    bgcol = Color(0xFF707070);
  } else if (deleteStyle != null) {
    fgcol = Color(0xFFFFFFFF);
    bgcol = Colors.redAccent;
  }
  return Container(
    width: width != null ? width : 300,
    child: TextButton(
      style: TextButton.styleFrom(
        backgroundColor: bgcol,
        shape: RoundedRectangleBorder(borderRadius: DEF_BORDER_RADIUS),
      ),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 0, horizontal: 0),
        child: Row(
          children: [
            if (icon != null) icon,
            if (icon != null) SizedBox(width: 4),
            Expanded(
              child: Text(
                title,
                style: TextStyle(color: fgcol, fontSize: fsize),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
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
/// - radio: null or true or false
Widget MyListTile(
    {required Widget title1,
    Widget? title2,
    Function()? onPressed,
    bool? multiline,
    bool? radio,
    bool? textonly}) {
  Widget e = Expanded(child: SizedBox(width: 8));
  if (multiline != null) e = SizedBox(width: 8);
  Widget w = SizedBox(width: 8);
  Icon icon = Icon(Icons.arrow_forward_ios, size: 14.0, color: myTheme.textTheme.bodyMedium!.color);

  Widget txt;
  if (textonly != null) {
    txt = title1;
  } else if (radio != null) {
    //icon = Icon(Icons.circle_outlined, size: 26.0, color: myTheme.textTheme.bodyMedium!.color);
    icon = Icon(Icons.circle_outlined, size: 26.0);
    if (radio == true) {
      icon = Icon(Icons.check_circle, size: 26.0);
    }
    txt = Row(children: [title1, e, icon]);
  } else if (title2 != null && onPressed != null) {
    txt = Row(children: [title1, e, title2, w, icon]);
  } else if (onPressed != null) {
    txt = Row(children: [e, title1, e, w, icon]);
  } else {
    txt = Row(children: [e, title1, e]);
  }
  return Container(
    padding: EdgeInsets.symmetric(vertical: 3, horizontal: 8),
    child: TextButton(child: txt, onPressed: onPressed),
  );
}

Widget MyBookTile({required Widget title1, Function()? onPressed}) {
  Widget e = Expanded(child: SizedBox(width: 8));
  Icon icon = Icon(Icons.arrow_forward_ios, size: 14.0);

  Widget txt = Row(children: [title1, e, icon]);
  return Container(
    padding: EdgeInsets.symmetric(vertical: 2, horizontal: 2),
    child: TextButton(
      child: txt,
      onPressed: onPressed,
    ),
  );
}
