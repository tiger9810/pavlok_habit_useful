/// レイアウト定数
/// 
/// アプリ全体で使用するレイアウト定数を定義します。
class LayoutConstants {
  // ホーム画面のレイアウト定数
  static const double homeLeftPadding = 16.0;
  static const double homeCircleSize = 10.0;
  static const double homeCircleGap = 10.0;
  static const double homeTitleAreaWidth = 130.0; // 円形パーツ + タイトル分
  static const double homeDateColumnWidth = 50.0; // 各日のカラム幅
  static const double homeRightPadding = 8.0;
  static const double homeStatusCellHeight = 44.0; // ステータスセルの高さ
  
  // プライベートコンストラクタ（インスタンス化を防ぐ）
  LayoutConstants._();
}
