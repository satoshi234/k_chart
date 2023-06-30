import 'package:flutter/material.dart';

export '../chart_style.dart';

abstract class BaseChartRenderer<T> {
  /// チャートデータの最大値と最小値
  double maxValue, minValue;

  /// Y軸の1単位ごとの高さ
  late double scaleY;

  /// チャートの表示領域の上部の余白
  /// * この値が、テキスト表示領域の高さとなる。
  double topPadding;

  /// チャートの境界
  Rect chartRect;

  /// チャートデータに表示する小数点以下の桁数
  int fixedLength;

  /// チャートを描画するために使用されるPaintオブジェクト
  Paint chartPaint = Paint()
    ..isAntiAlias = true
    ..filterQuality = FilterQuality.high
    ..strokeWidth = 1.0
    ..color = Colors.red;

  /// グリッド線を描画するために使用されるPaintオブジェクト
  Paint gridPaint = Paint()
    ..isAntiAlias = true
    ..filterQuality = FilterQuality.high
    ..strokeWidth = 0.5
    ..color = Color(0xff4c5c74);

  BaseChartRenderer({
    required this.chartRect,
    required this.maxValue,
    required this.minValue,
    required this.topPadding,
    required this.fixedLength,
    required Color gridColor,
  }) {
    if (maxValue == minValue) {
      // maxValueとminValueが等しい場合
      // ゼロでの除算を避けるために調整する。
      maxValue *= 1.5;
      minValue /= 2;
    }

    // maxValue、minValue、およびchartRectプロパティに基づいてscaleYプロパティを初期化
    scaleY = chartRect.height / (maxValue - minValue);

    // gridPaint.colorは、指定されたgridColorに設定
    gridPaint.color = gridColor;

    // // debug
    // print(
    //   "===== maxValue: ${maxValue.toString()}" +
    //       ", minValue: ${minValue.toString()}" +
    //       ", scaleY: ${scaleY.toString()}",
    // );
  }

  /// 値に基づいてチャート上の点のy座標を計算するために使用する
  double getY(double y) => (maxValue - y) * scaleY + chartRect.top;

  /// 数値を指定された小数点以下の桁数でフォーマットするために使用する
  String format(double? n) {
    if (n == null || n.isNaN) {
      return "0.00";
    } else {
      return n.toStringAsFixed(fixedLength);
    }
  }

  void drawGrid(Canvas canvas, int gridRows, int gridColumns);

  void drawText(Canvas canvas, T data, double x);

  void drawVerticalText(canvas, textStyle, int gridRows);

  void drawChart(
    T lastPoint,
    T curPoint,
    double lastX,
    double curX,
    Size size,
    Canvas canvas,
  );

  /// 2つの点の間に線を描画するために使用されます。
  void drawLine(
    double? lastPrice,
    double? curPrice,
    Canvas canvas,
    double lastX,
    double curX,
    Color color,
  ) {
    if (lastPrice == null || curPrice == null) {
      // lastPriceまたはcurPriceがnullの場合は、線を描画しない
      return;
    }

    // debug
    // print("lasePrice==" + lastPrice.toString() + "==curPrice==" + curPrice.toString());

    // lastPriceとcurPriceのy座標を取得
    double lastY = getY(lastPrice);
    double curY = getY(curPrice);

    // debug
    // print("lastX-----==" + lastX.toString() + "==lastY==" + lastY.toString() + "==curX==" + curX.toString() + "==curY==" + curY.toString());

    // (lastX, lastY) から (curX, curY) まで線を描画
    canvas.drawLine(
      Offset(lastX, lastY),
      Offset(curX, curY),
      chartPaint..color = color,
    );
  }

  /// 指定された色が設定されたテキストスタイルを取得する
  TextStyle getTextStyle(Color color) {
    return TextStyle(fontSize: 10.0, color: color);
  }
}
