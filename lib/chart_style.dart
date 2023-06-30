import 'package:flutter/material.dart' show Color;

class ChartColors {
  List<Color> bgColor = [Color(0xff18191d), Color(0xff18191d)];

  Color kLineColor = Color(0xff4C86CD);
  Color lineFillColor = Color(0x554C86CD);
  Color lineFillInsideColor = Color(0x00000000);
  Color ma5Color = Color(0xffC9B885);
  Color ma10Color = Color(0xff6CB0A6);
  Color ma30Color = Color(0xff9979C6);
  Color upColor = Color(0xff4DAA90);
  Color dnColor = Color(0xffC15466);
  Color volColor = Color(0xff4729AE);

  Color macdColor = Color(0xff4729AE);
  Color difColor = Color(0xffC9B885);
  Color deaColor = Color(0xff6CB0A6);

  Color kColor = Color(0xffC9B885);
  Color dColor = Color(0xff6CB0A6);
  Color jColor = Color(0xff9979C6);
  Color rsiColor = Color(0xffC9B885);

  Color defaultTextColor = Color(0xff60738E);

  Color nowPriceUpColor = Color(0xff4DAA90);
  Color nowPriceDnColor = Color(0xffC15466);
  Color nowPriceTextColor = Color(0xffffffff);

  Color depthBuyColor = Color(0xff60A893);
  Color depthSellColor = Color(0xffC15866);

  Color selectBorderColor = Color(0xff6C7A86);

  Color selectFillColor = Color(0xff0D1722);

  Color gridColor = Color(0xff4c5c74);

  Color infoWindowNormalColor = Color(0xffffffff);
  Color infoWindowTitleColor = Color(0xffffffff);
  Color infoWindowUpColor = Color(0xff00ff00);
  Color infoWindowDnColor = Color(0xffff0000);

  Color hCrossColor = Color(0xffffffff);
  Color vCrossColor = Color(0x1Effffff);
  Color crossTextColor = Color(0xffffffff);

  Color maxColor = Color(0xffffffff);
  Color minColor = Color(0xffffffff);

  Color getMAColor(int index) {
    switch (index % 3) {
      case 1:
        return ma10Color;
      case 2:
        return ma30Color;
      default:
        return ma5Color;
    }
  }
}

class ChartStyle {
  /// チャート群の描画領域の上のパディング
  double topPadding = 30.0;

  /// チャート群の描画領域の下のパディング
  /// * ここに日付が表示する
  double bottomPadding = 20.0;

  /// ひとつ上のチャートとの間隔
  double childPadding = 12.0;

  // 各データの間隔
  double pointWidth = 11.0;

  /// ロウソク足の幅
  double candleWidth = 8.5;

  /// ロウソク足の線の幅
  double candleLineWidth = 1.5;

  /// volバーの幅
  double volWidth = 8.5;

  /// macdバーの幅
  double macdWidth = 3.0;

  /// 十字線の縦線の幅
  double vCrossWidth = 8.5;

  /// 十字線の横線の幅
  double hCrossWidth = 0.5;

  /// 現在価格の破線の線分の長さ
  double nowPriceLineLength = 5;

  /// 現在価格の破線の間隔
  double nowPriceLineSpan = 1;

  /// 現在価格の破線の幅
  double nowPriceLineWidth = 1;

  /// チャートのグリッドの行数
  int gridRows = 4;

  /// チャートのグリッドの列数
  int gridColumns = 5;

  /// チャートの日付のフォーマット文字列
  /// ex) HH:mm
  List<String>? dateTimeFormat;
}
