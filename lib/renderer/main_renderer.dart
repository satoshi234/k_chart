import 'package:flutter/material.dart';

import '../entity/candle_entity.dart';
import '../k_chart_widget.dart' show MainState;
import 'base_chart_renderer.dart';

enum VerticalTextAlignment {
  left,
  right,
  ;
}

//For TrendLine
double? trendLineMax;
double? trendLineScale;
double? trendLineContentRec;

/// ローソク足のチャートを描画するために使用されます。
class MainRenderer extends BaseChartRenderer<CandleEntity> {
  /// ローソク足の幅
  late double mCandleWidth;

  /// ローソク足の線の幅を表します。
  late double mCandleLineWidth;

  /// チャートの状態
  MainState state;

  /// ラインチャートであるか
  /// true: ラインチャート
  /// false: ローソク足チャート
  bool isLine;

  /// チャートの表示領域を表すRect
  /// * コンストラクタで渡されたchartRectから、上下のパディングを除いた領域
  ///   このchartRectには、上部のテキスト描画領域は含まれていない
  late Rect _contentRect;

  /// チャートの表示領域の上下のパディング
  /// * 現状、この値は、チャート描画時に正しく参照されていないので、使用しないこと。
  double _contentPadding = 5.0;

  /// 移動平均線の日数リスト
  List<int> maDayList;

  /// チャートのスタイル
  final ChartStyle chartStyle;

  /// チャートの色
  final ChartColors chartColors;

  /// ラインチャートの線の幅
  /// * 最終的に、0.1 ~ 1.0の値に丸められる。
  final double mLineStrokeWidth = 1.0;

  /// チャートのX軸のスケール
  double scaleX;

  /// ラインチャートの線のペイント
  late Paint mLinePaint;

  /// 垂直方向のテキストの配置
  final VerticalTextAlignment verticalTextAlignment;

  MainRenderer(
      Rect mainRect,
      double maxValue,
      double minValue,
      double topPadding,
      this.state,
      this.isLine,
      int fixedLength,
      this.chartStyle,
      this.chartColors,
      this.scaleX,
      this.verticalTextAlignment,
      [this.maDayList = const [5, 10, 20]])
      : super(
          chartRect: mainRect,
          maxValue: maxValue,
          minValue: minValue,
          topPadding: topPadding,
          fixedLength: fixedLength,
          gridColor: chartColors.gridColor,
        ) {
    mCandleWidth = this.chartStyle.candleWidth;
    mCandleLineWidth = this.chartStyle.candleLineWidth;

    mLinePaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = mLineStrokeWidth
      ..color = this.chartColors.kLineColor;

    // 指定されたチャートの表示領域から、上下のパディングを除いた領域を計算する。
    // それを、本チャートの表示領域とする。
    _contentRect = Rect.fromLTRB(
      chartRect.left,
      chartRect.top + _contentPadding,
      chartRect.right,
      chartRect.bottom - _contentPadding,
    );

    if (maxValue == minValue) {
      // maxValueとminValueが等しい場合
      // ゼロでの除算を避けるために調整する。
      maxValue *= 1.5;
      minValue /= 2;
    }

    // Y座標の最大値と最小値の差、およびチャート表示領域の高さから、scaleYを計算する。
    scaleY = _contentRect.height / (maxValue - minValue);
  }

  @override
  void drawText(Canvas canvas, CandleEntity data, double x) {
    if (isLine == true) {
      // ラインチャートの場合は、テキストを描画しない。
      return;
    }

    // インジケータの各値を表示するテキスト
    TextSpan? span;
    if (state == MainState.MA) {
      // 移動平均線の場合
      span = TextSpan(
        children: _createMATextSpan(data),
      );
    } else if (state == MainState.BOLL) {
      // ボリンジャーバンドの場合
      span = TextSpan(
        children: [
          if (data.up != 0)
            TextSpan(
              text: "BOLL:${format(data.mb)}    ",
              style: getTextStyle(this.chartColors.ma5Color),
            ),
          if (data.mb != 0)
            TextSpan(
              text: "UB:${format(data.up)}    ",
              style: getTextStyle(this.chartColors.ma10Color),
            ),
          if (data.dn != 0)
            TextSpan(
              text: "LB:${format(data.dn)}    ",
              style: getTextStyle(this.chartColors.ma30Color),
            ),
        ],
      );
    }

    if (span == null) {
      // テキストがない場合は、描画しない。
      return;
    }

    // テキストの描画
    TextPainter tp = TextPainter(text: span, textDirection: TextDirection.ltr);

    // チャート群の描画領域の上部の、テキスト表示領域に描画する。
    // * テキスト表示領域の高さは、topPaddingとなる。
    tp.layout();
    tp.paint(canvas, Offset(x, chartRect.top - topPadding));
  }

  /// 各移動平均線の値を表示するテキストを作成する。
  List<InlineSpan> _createMATextSpan(CandleEntity data) {
    final result = <InlineSpan>[];
    for (int i = 0; i < (data.maValueList?.length ?? 0); i++) {
      if (data.maValueList?[i] != 0) {
        final numberOfTimePeriods = maDayList[i];
        final maValue = format(data.maValueList![i]);
        final textStyle = getTextStyle(
          this.chartColors.getMAColor(i),
        );

        var item = TextSpan(
          text: "MA$numberOfTimePeriods:$maValue    ",
          style: textStyle,
        );

        result.add(item);
      }
    }

    return result;
  }

  /// チャートを描画する
  @override
  void drawChart(
    CandleEntity lastPoint,
    CandleEntity curPoint,
    double lastX,
    double curX,
    Size size,
    Canvas canvas,
  ) {
    if (isLine) {
      // ラインチャートの場合
      drawPolyline(lastPoint.close, curPoint.close, canvas, lastX, curX);
    } else {
      // ローソク足チャートの場合
      drawCandle(curPoint, canvas, curX);
      if (state == MainState.MA) {
        drawMaLine(lastPoint, curPoint, canvas, lastX, curX);
      } else if (state == MainState.BOLL) {
        drawBollLine(lastPoint, curPoint, canvas, lastX, curX);
      }
    }
  }

  Shader? mLineFillShader;
  Path? mLinePath, mLineFillPath;
  Paint mLineFillPaint = Paint()
    ..style = PaintingStyle.fill
    ..isAntiAlias = true;

  /// ラインチャートを描画する
  drawPolyline(
    double lastPrice,
    double curPrice,
    Canvas canvas,
    double lastX,
    double curX,
  ) {
//    drawLine(lastPrice + 100, curPrice + 100, canvas, lastX, curX, ChartColors.kLineColor);
    mLinePath ??= Path();

//    if (lastX == curX) {
//      mLinePath.moveTo(lastX, getY(lastPrice));
//    } else {
////      mLinePath.lineTo(curX, getY(curPrice));
//      mLinePath.cubicTo(
//          (lastX + curX) / 2, getY(lastPrice), (lastX + curX) / 2, getY(curPrice), curX, getY(curPrice));
//    }
    if (lastX == curX) {
      lastX = 0;
    }
    mLinePath!.moveTo(lastX, getY(lastPrice));
    mLinePath!.cubicTo((lastX + curX) / 2, getY(lastPrice), (lastX + curX) / 2,
        getY(curPrice), curX, getY(curPrice));

    // チャート表示領域全体に上部から下部へ向けて、グラデーションをかける。
    mLineFillShader ??= LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      tileMode: TileMode.clamp,
      colors: [
        this.chartColors.lineFillColor,
        this.chartColors.lineFillInsideColor
      ],
    ).createShader(
      Rect.fromLTRB(
        chartRect.left,
        chartRect.top,
        chartRect.right,
        chartRect.bottom,
      ),
    );
    mLineFillPaint..shader = mLineFillShader;

    mLineFillPath ??= Path();

    mLineFillPath!.moveTo(lastX, chartRect.height + chartRect.top);
    mLineFillPath!.lineTo(lastX, getY(lastPrice));
    mLineFillPath!.cubicTo(
      (lastX + curX) / 2,
      getY(lastPrice),
      (lastX + curX) / 2,
      getY(curPrice),
      curX,
      getY(curPrice),
    );
    mLineFillPath!.lineTo(curX, chartRect.height + chartRect.top);
    mLineFillPath!.close();

    canvas.drawPath(mLineFillPath!, mLineFillPaint);
    mLineFillPath!.reset();

    canvas.drawPath(
      mLinePath!,
      mLinePaint..strokeWidth = (mLineStrokeWidth / scaleX).clamp(0.1, 1.0),
    );
    mLinePath!.reset();
  }

  void drawMaLine(CandleEntity lastPoint, CandleEntity curPoint, Canvas canvas,
      double lastX, double curX) {
    for (int i = 0; i < (curPoint.maValueList?.length ?? 0); i++) {
      if (i == 3) {
        break;
      }
      if (lastPoint.maValueList?[i] != 0) {
        drawLine(lastPoint.maValueList?[i], curPoint.maValueList?[i], canvas,
            lastX, curX, this.chartColors.getMAColor(i));
      }
    }
  }

  void drawBollLine(CandleEntity lastPoint, CandleEntity curPoint,
      Canvas canvas, double lastX, double curX) {
    if (lastPoint.up != 0) {
      drawLine(lastPoint.up, curPoint.up, canvas, lastX, curX,
          this.chartColors.ma10Color);
    }
    if (lastPoint.mb != 0) {
      drawLine(lastPoint.mb, curPoint.mb, canvas, lastX, curX,
          this.chartColors.ma5Color);
    }
    if (lastPoint.dn != 0) {
      drawLine(lastPoint.dn, curPoint.dn, canvas, lastX, curX,
          this.chartColors.ma30Color);
    }
  }

  /// ロウソク足を描画する
  void drawCandle(CandleEntity curPoint, Canvas canvas, double curX) {
    var highY = getY(curPoint.high);
    var lowY = getY(curPoint.low);
    var openY = getY(curPoint.open);
    var closeY = getY(curPoint.close);

    double r = mCandleWidth / 2;
    double lineR = mCandleLineWidth / 2;
    if (openY >= closeY) {
      // 陽線 * Y軸は下向きが正のため、Y座標の値が大きいほど下にある。
      chartPaint.color = this.chartColors.upColor;

      // ロウソク足実体部分の高さ
      final candleHigh = openY - closeY;
      if (candleHigh < mCandleLineWidth) {
        // ロウソク足実体部分の高さがCandleLineWidthより小さい場合
        // 高さをCandleLineWidthにする。
        openY = closeY + mCandleLineWidth;
      }

      // ロウソク足実体部分を描画する。
      canvas.drawRect(
        Rect.fromLTRB(curX - r, closeY, curX + r, openY),
        chartPaint,
      );
      // ロウソク足の中心線を描画する。
      canvas.drawRect(
        Rect.fromLTRB(curX - lineR, highY, curX + lineR, lowY),
        chartPaint,
      );
    } else {
      // 陰線
      chartPaint.color = this.chartColors.dnColor;

      final candleHigh = closeY - openY;
      if (candleHigh < mCandleLineWidth) {
        // ロウソク足実体部分の高さがCandleLineWidthより小さい場合
        // 高さをCandleLineWidthにする。
        openY = closeY - mCandleLineWidth;
      }

      // ロウソク足実体部分を描画する。
      canvas.drawRect(
        Rect.fromLTRB(curX - r, openY, curX + r, closeY),
        chartPaint,
      );
      // ロウソク足の中心線を描画する。
      canvas.drawRect(
        Rect.fromLTRB(curX - lineR, highY, curX + lineR, lowY),
        chartPaint,
      );
    }
  }

  /// グリッドの各横線の値を描画する
  @override
  void drawVerticalText(canvas, textStyle, int gridRows) {
    double rowSpace = chartRect.height / gridRows;
    for (var i = 0; i <= gridRows; ++i) {
      // 上から数えて、i+1番目の横線の値を描画する。
      double value = (gridRows - i) * rowSpace / scaleY + minValue;
      TextSpan span = TextSpan(text: "${format(value)}", style: textStyle);
      TextPainter tp =
          TextPainter(text: span, textDirection: TextDirection.ltr);
      tp.layout();

      final double offsetX;
      switch (verticalTextAlignment) {
        case VerticalTextAlignment.left:
          offsetX = 0;
          break;
        case VerticalTextAlignment.right:
          offsetX = chartRect.width - tp.width;
          break;
      }

      if (i == 0) {
        // 一番上の横線の場合は、横線の下部に描画する。
        tp.paint(
          canvas,
          Offset(offsetX, topPadding),
        );
      } else {
        // 一番上以外の横線の場合は、横線の上部に描画する。
        tp.paint(
          canvas,
          Offset(offsetX, topPadding + rowSpace * i - tp.height),
        );
      }
    }
  }

  /// グリッドを描画する
  @override
  void drawGrid(Canvas canvas, int gridRows, int gridColumns) {
    // 横線を描画する。
    double rowSpace = chartRect.height / gridRows;
    for (int i = 0; i <= gridRows; i++) {
      canvas.drawLine(
        Offset(0, rowSpace * i + topPadding),
        Offset(chartRect.width, rowSpace * i + topPadding),
        gridPaint,
      );
    }

    // 縦線を描画する。
    double columnSpace = chartRect.width / gridColumns;
    for (int i = 0; i <= columnSpace; i++) {
      canvas.drawLine(
        Offset(columnSpace * i, topPadding / 3),
        Offset(columnSpace * i, chartRect.bottom),
        gridPaint,
      );
    }
  }

  /// 引数の値を持つ点のY座標を返す。
  @override
  double getY(double y) {
    //For TrendLine
    updateTrendLineData();

    return (maxValue - y) * scaleY + _contentRect.top;
  }

  void updateTrendLineData() {
    trendLineMax = maxValue;
    trendLineScale = scaleY;
    trendLineContentRec = _contentRect.top;
  }
}
