import 'dart:async';

import 'package:flutter/material.dart';
import 'package:k_chart/chart_translations.dart';
import 'package:k_chart/extension/map_ext.dart';
import 'package:k_chart/flutter_k_chart.dart';

/// Mainチャートの状態
enum MainState {
  /// MA
  MA,

  /// ボリンジャーバンド
  BOLL,

  /// なし
  NONE,
  ;
}

/// Secondaryチャートの状態
enum SecondaryState {
  /// MACD
  MACD,

  /// KDJ
  KDJ,

  /// RSI
  RSI,

  /// WR
  WR,

  /// CCI
  CCI,

  /// なし
  NONE,
  ;
}

class TimeFormat {
  static const List<String> YEAR_MONTH_DAY = [yyyy, '-', mm, '-', dd];
  static const List<String> YEAR_MONTH_DAY_WITH_HOUR = [
    yyyy,
    '-',
    mm,
    '-',
    dd,
    ' ',
    HH,
    ':',
    nn
  ];
}

class KChartWidget extends StatefulWidget {
  final List<KLineEntity>? datas;
  final MainState mainState;
  final bool volHidden;
  final SecondaryState secondaryState;
  final Function()? onSecondaryTap;
  final bool isLine;
  final bool isTapShowInfoDialog; //是否开启单击显示详情数据
  final bool hideGrid;
  @Deprecated('Use `translations` instead.')
  final bool isChinese;
  final bool showNowPrice;
  final bool showInfoDialog;
  final bool materialInfoDialog; // Material风格的信息弹窗
  final Map<String, ChartTranslations> translations;
  final List<String> timeFormat;

  //当屏幕滚动到尽头会调用，真为拉到屏幕右侧尽头，假为拉到屏幕左侧尽头
  final Function(bool)? onLoadMore;

  final int fixedLength;
  final List<int> maDayList;
  final int flingTime;
  final double flingRatio;
  final Curve flingCurve;
  final Function(bool)? isOnDrag;
  final ChartColors chartColors;
  final ChartStyle chartStyle;
  final VerticalTextAlignment verticalTextAlignment;
  final bool isTrendLine;
  final double xFrontPadding;

  KChartWidget(
    this.datas,
    this.chartStyle,
    this.chartColors, {
    required this.isTrendLine,
    this.xFrontPadding = 100,
    this.mainState = MainState.MA,
    this.secondaryState = SecondaryState.MACD,
    this.onSecondaryTap,
    this.volHidden = false,
    this.isLine = false,
    this.isTapShowInfoDialog = false,
    this.hideGrid = false,
    @Deprecated('Use `translations` instead.') this.isChinese = false,
    this.showNowPrice = true,
    this.showInfoDialog = true,
    this.materialInfoDialog = true,
    this.translations = kChartTranslations,
    this.timeFormat = TimeFormat.YEAR_MONTH_DAY,
    this.onLoadMore,
    this.fixedLength = 2,
    this.maDayList = const [5, 10, 20],
    this.flingTime = 600,
    this.flingRatio = 0.5,
    this.flingCurve = Curves.decelerate,
    this.isOnDrag,
    this.verticalTextAlignment = VerticalTextAlignment.left,
  });

  @override
  _KChartWidgetState createState() => _KChartWidgetState();
}

class _KChartWidgetState extends State<KChartWidget>
    with TickerProviderStateMixin {
  double mScaleX = 1.0, mScrollX = 0.0, mSelectX = 0.0;
  StreamController<InfoWindowEntity?>? mInfoWindowStream;
  double mHeight = 0, mWidth = 0;
  AnimationController? _controller;
  Animation<double>? aniX;

  //For TrendLine
  List<TrendLine> lines = [];
  double? changeinXposition;
  double? changeinYposition;
  double mSelectY = 0.0;
  bool waitingForOtherPairofCords = false;
  bool enableCordRecord = false;

  // チャート群表示領域の高さに占める、Secondaryチャートの高さの比率
  double _mSecondaryScale = 0.2;

  double getMinScrollX() {
    return mScaleX;
  }

  double _lastScale = 1.0;
  bool isScale = false, isDrag = false, isLongPress = false, isOnTap = false;

  // gesture
  bool? _isVertical;

  @override
  void initState() {
    super.initState();
    mInfoWindowStream = StreamController<InfoWindowEntity?>();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    mInfoWindowStream?.close();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.datas != null && widget.datas!.isEmpty) {
      mScrollX = mSelectX = 0.0;
      mScaleX = 1.0;
    }

    final _painter = ChartPainter(
      widget.chartStyle,
      widget.chartColors,
      lines: lines, //For TrendLine
      xFrontPadding: widget.xFrontPadding,
      isTrendLine: widget.isTrendLine, //For TrendLine
      selectY: mSelectY, //For TrendLine
      datas: widget.datas,
      scaleX: mScaleX,
      scrollX: mScrollX,
      selectX: mSelectX,
      isLongPass: isLongPress,
      isOnTap: isOnTap,
      isTapShowInfoDialog: widget.isTapShowInfoDialog,
      mainState: widget.mainState,
      volHidden: widget.volHidden,
      secondaryState: widget.secondaryState,
      secondaryScale: _mSecondaryScale,
      isLine: widget.isLine,
      hideGrid: widget.hideGrid,
      showNowPrice: widget.showNowPrice,
      sink: mInfoWindowStream?.sink,
      fixedLength: widget.fixedLength,
      maDayList: widget.maDayList,
      verticalTextAlignment: widget.verticalTextAlignment,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        mHeight = constraints.maxHeight;
        mWidth = constraints.maxWidth;

        return GestureDetector(
          onTapUp: (details) {
            print('onTapUp');

            if (!widget.isTrendLine &&
                _painter.isInSecondaryRect(details.localPosition)) {
              if (widget.onSecondaryTap != null) {
                widget.onSecondaryTap!();
              }
            }

            if (!widget.isTrendLine &&
                _painter.isInMainRect(details.localPosition)) {
              isOnTap = true;
              if (mSelectX != details.localPosition.dx &&
                  widget.isTapShowInfoDialog) {
                mSelectX = details.localPosition.dx;
                notifyChanged();
              }
            }

            if (widget.isTrendLine && !isLongPress && enableCordRecord) {
              enableCordRecord = false;
              Offset p1 = Offset(getTrendLineX(), mSelectY);
              if (!waitingForOtherPairofCords) {
                lines.add(
                  TrendLine(
                    p1,
                    Offset(-1, -1),
                    trendLineMax!,
                    trendLineScale!,
                  ),
                );
              }

              if (waitingForOtherPairofCords) {
                var a = lines.last;
                lines.removeLast();
                lines.add(TrendLine(a.p1, p1, trendLineMax!, trendLineScale!));
                waitingForOtherPairofCords = false;
              } else {
                waitingForOtherPairofCords = true;
              }

              notifyChanged();
            }
          },
          // onHorizontalDragDown: (details) {
          //   isOnTap = false;
          //   _stopAnimation();
          //   _onDragChanged(true);
          // },
          // onHorizontalDragUpdate: (details) {
          //   print('onHorizontalDragUpdate');

          //   if (isScale || isLongPress) return;
          //   mScrollX = ((details.primaryDelta ?? 0) / mScaleX + mScrollX)
          //       .clamp(0.0, ChartPainter.maxScrollX)
          //       .toDouble();
          //   notifyChanged();
          // },
          // onHorizontalDragEnd: (DragEndDetails details) {
          //   var velocity = details.velocity.pixelsPerSecond.dx;
          //   _onFling(velocity);
          // },
          // onHorizontalDragCancel: () {
          //   print('onHorizontalDragCancel');

          //   _onDragChanged(false);
          // },
          onScaleStart: (details) {
            // スケール変更開始
            print('onScaleStart');

            _stopAnimation();

            isOnTap = false;
            _isVertical = null;
            if (details.pointerCount == 1) {
              // _onDragChanged(true);
              isDrag = true;
              isScale = false;
            } else if (details.pointerCount == 2) {
              // _onDragChanged(false);
              isDrag = false;
              isScale = true;
            } else {
              // _onDragChanged(true);
              isDrag = true;
              isScale = false;
            }
          },
          onScaleUpdate: (details) {
            print('onScaleUpdate');

            if (isLongPress) {
              return;
            }

            if (_isVertical == null) {
              // 初回のみ方向を判定する
              final dx = details.focalPointDelta.dx.abs();
              final dy = details.focalPointDelta.dy.abs();

              // y軸方向のスクロールの方が、x軸方向のそれよりも大きい場合は縦方向と判定する
              _isVertical ??= dy > dx;
            }

            if (isDrag) {
              // 1点ポインターである場合

              // print('delta: ${details.focalPointDelta}');

              if (_isVertical == true) {
                if (_painter.isInSecondaryRect(details.localFocalPoint)) {
                  // Secondaryチャートのスケールを変更する
                  // * ある一定値の中に収まるように調整する
                  final deltaScale = details.focalPointDelta.dy / mHeight;
                  _mSecondaryScale =
                      (_mSecondaryScale - deltaScale).clamp(0.1, 0.9);

                  notifyChanged();
                }
              } else if (_isVertical == false) {
                final dx = details.focalPointDelta.dx;

                mScrollX = (dx / mScaleX + mScrollX)
                    .clamp(0.0, ChartPainter.maxScrollX)
                    .toDouble();

                notifyChanged();
              }
            } else if (details.pointerCount == 2) {
              // 2点ポインターである場合

              // x軸のスケールを変更する
              // * ある一定値の中に収まるように調整する
              mScaleX = (_lastScale * details.scale).clamp(0.1, 2.2);
              notifyChanged();
            }
          },
          onScaleEnd: (details) {
            print('onScaleEnd');

            if (isDrag && _isVertical == true) {
              // 水平方向スクロールの場合
              final velocity = details.velocity.pixelsPerSecond.dx;
              _onFling(velocity);
            }

            // スケール変更終了
            isOnTap = false;
            isScale = false;
            isDrag = false;

            // スケールの値を保存する
            _lastScale = mScaleX;
          },
          onLongPressStart: (details) {
            print('onLongPressStart');

            isOnTap = false;
            isLongPress = true;
            if ((mSelectX != details.localPosition.dx ||
                    mSelectY != details.globalPosition.dy) &&
                !widget.isTrendLine) {
              mSelectX = details.localPosition.dx;
              notifyChanged();
            }
            //For TrendLine
            if (widget.isTrendLine && changeinXposition == null) {
              mSelectX = changeinXposition = details.localPosition.dx;
              mSelectY = changeinYposition = details.globalPosition.dy;
              notifyChanged();
            }
            //For TrendLine
            if (widget.isTrendLine && changeinXposition != null) {
              changeinXposition = details.localPosition.dx;
              changeinYposition = details.globalPosition.dy;
              notifyChanged();
            }
          },
          onLongPressMoveUpdate: (details) {
            if ((mSelectX != details.localPosition.dx ||
                    mSelectY != details.globalPosition.dy) &&
                !widget.isTrendLine) {
              mSelectX = details.localPosition.dx;
              mSelectY = details.localPosition.dy;
              notifyChanged();
            }
            if (widget.isTrendLine) {
              mSelectX =
                  mSelectX + (details.localPosition.dx - changeinXposition!);
              changeinXposition = details.localPosition.dx;
              mSelectY =
                  mSelectY + (details.globalPosition.dy - changeinYposition!);
              changeinYposition = details.globalPosition.dy;
              notifyChanged();
            }
          },
          onLongPressEnd: (details) {
            isLongPress = false;
            enableCordRecord = true;
            mInfoWindowStream?.sink.add(null);
            notifyChanged();
          },
          child: Stack(
            children: <Widget>[
              CustomPaint(
                size: Size(double.infinity, double.infinity),
                painter: _painter,
              ),
              if (widget.showInfoDialog) _buildInfoDialog()
            ],
          ),
        );
      },
    );
  }

  void _stopAnimation({bool needNotify = true}) {
    if (_controller != null && _controller!.isAnimating) {
      _controller!.stop();
      _onDragChanged(false);
      if (needNotify) {
        notifyChanged();
      }
    }
  }

  void _onDragChanged(bool isOnDrag) {
    isDrag = isOnDrag;
    if (widget.isOnDrag != null) {
      widget.isOnDrag!(isDrag);
    }
  }

  void _onFling(double x) {
    _controller = AnimationController(
      duration: Duration(milliseconds: widget.flingTime),
      vsync: this,
    );

    aniX = null;
    aniX = Tween<double>(
      begin: mScrollX,
      end: x * widget.flingRatio + mScrollX,
    ).animate(
      CurvedAnimation(parent: _controller!.view, curve: widget.flingCurve),
    );

    aniX!.addListener(() {
      mScrollX = aniX!.value;
      if (mScrollX <= 0) {
        mScrollX = 0;
        if (widget.onLoadMore != null) {
          widget.onLoadMore!(true);
        }
        _stopAnimation();
      } else if (mScrollX >= ChartPainter.maxScrollX) {
        mScrollX = ChartPainter.maxScrollX;
        if (widget.onLoadMore != null) {
          widget.onLoadMore!(false);
        }
        _stopAnimation();
      }
      notifyChanged();
    });
    aniX!.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        _onDragChanged(false);
        notifyChanged();
      }
    });

    _controller!.forward();
  }

  void notifyChanged() => setState(() {});

  late List<String> infos;

  Widget _buildInfoDialog() {
    return StreamBuilder<InfoWindowEntity?>(
      stream: mInfoWindowStream?.stream,
      builder: (context, snapshot) {
        if ((!isLongPress && !isOnTap) ||
            widget.isLine == true ||
            !snapshot.hasData ||
            snapshot.data?.kLineEntity == null) return Container();
        KLineEntity entity = snapshot.data!.kLineEntity;
        double upDown = entity.change ?? entity.close - entity.open;
        double upDownPercent = entity.ratio ?? (upDown / entity.open) * 100;
        final double? entityAmount = entity.amount;
        infos = [
          getDate(entity.time),
          entity.open.toStringAsFixed(widget.fixedLength),
          entity.high.toStringAsFixed(widget.fixedLength),
          entity.low.toStringAsFixed(widget.fixedLength),
          entity.close.toStringAsFixed(widget.fixedLength),
          "${upDown > 0 ? "+" : ""}${upDown.toStringAsFixed(widget.fixedLength)}",
          "${upDownPercent > 0 ? "+" : ''}${upDownPercent.toStringAsFixed(2)}%",
          if (entityAmount != null) entityAmount.toInt().toString()
        ];
        final dialogPadding = 4.0;
        final dialogWidth = mWidth / 3;
        return Container(
          margin: EdgeInsets.only(
              left: snapshot.data!.isLeft
                  ? dialogPadding
                  : mWidth - dialogWidth - dialogPadding,
              top: 25),
          width: dialogWidth,
          decoration: BoxDecoration(
            color: widget.chartColors.selectFillColor,
            border: Border.all(
              color: widget.chartColors.selectBorderColor,
              width: 0.5,
            ),
          ),
          child: ListView.builder(
            padding: EdgeInsets.all(dialogPadding),
            itemCount: infos.length,
            itemExtent: 14.0,
            shrinkWrap: true,
            itemBuilder: (context, index) {
              final translations = widget.translations.of(context);

              return _buildItem(
                infos[index],
                translations.byIndex(index),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildItem(String info, String infoName) {
    Color color = widget.chartColors.infoWindowNormalColor;
    if (info.startsWith("+")) {
      color = widget.chartColors.infoWindowUpColor;
    } else if (info.startsWith("-")) {
      color = widget.chartColors.infoWindowDnColor;
    }

    final infoWidget = Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: Text(
            "$infoName",
            style: TextStyle(
              color: widget.chartColors.infoWindowTitleColor,
              fontSize: 10.0,
            ),
          ),
        ),
        Text(
          info,
          style: TextStyle(
            color: color,
            fontSize: 10.0,
          ),
        ),
      ],
    );

    return widget.materialInfoDialog
        ? Material(color: Colors.transparent, child: infoWidget)
        : infoWidget;
  }

  String getDate(int? date) => dateFormat(
        DateTime.fromMillisecondsSinceEpoch(
          date ?? DateTime.now().millisecondsSinceEpoch,
        ),
        TimeFormat.YEAR_MONTH_DAY,
      );
}
