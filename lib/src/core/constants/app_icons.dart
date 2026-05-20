/// Centralized SVG icon path constants for the entire app.
///
/// Usage:
/// ```dart
/// SvgPicture.asset(AppIcons.home)
/// ```
abstract final class AppIcons {
  AppIcons._();
  static const String _base = 'assets/icons';

  // --- Navigation ---
  static const String home = '$_base/home.svg';
  static const String dashboard = '$_base/dashboard.svg';
  static const String menu = '$_base/menu.svg';

  // --- Quick Menu Items ---
  static const String duAn = '$_base/du_an.svg';
  static const String bangHang = '$_base/bang_hang.svg';
  static const String ctv = '$_base/ctv.svg';
  static const String khachHang = '$_base/khach_hang.svg';
  static const String quanTri = '$_base/quan_tri.svg';
  static const String chamCong = '$_base/cham_cong.svg';

  // --- Auth ---
  static const String fingerprint = '$_base/fingerprint.svg';
  static const String eye = '$_base/eye.svg';
  static const String eyeOff = '$_base/eye_off.svg';
  static const String lock = '$_base/lock.svg';
  static const String phone = '$_base/phone.svg';

  // --- Actions ---
  static const String search = '$_base/search.svg';
  static const String searchGold = '$_base/search_gold.svg';
  static const String filter = '$_base/filter.svg';
  static const String plus = '$_base/plus.svg';
  static const String edit = '$_base/edit.svg';
  static const String delete = '$_base/delete.svg';
  static const String deleteDialog = '$_base/delete_dialog.svg';
  static const String close = '$_base/close.svg';
  static const String back = '$_base/back.svg';
  static const String chevronRight = '$_base/chevron_right.svg';
  static const String chevronDown = '$_base/chevron_down.svg';
  static const String more = '$_base/more.svg';
  static const String refresh = '$_base/refresh.svg';
  static const String xClose = '$_base/x-close.svg';
  static const String addFab = '$_base/add_fab.svg';

  // --- Status & Feedback ---
  static const String success = '$_base/success.svg';
  static const String error = '$_base/error.svg';
  static const String warning = '$_base/warning.svg';
  static const String info = '$_base/info.svg';
  static const String notification = '$_base/notification.svg';

  // --- User & Profile ---
  static const String user = '$_base/user.svg';
  static const String settings = '$_base/settings.svg';
  static const String logout = '$_base/account_logout.svg';

  // --- Finance / Dashboard ---
  static const String money = '$_base/money.svg';
  static const String chart = '$_base/chart.svg';
  static const String wallet = '$_base/wallet.svg';
  static const String transfer = '$_base/transfer.svg';
  static const String deposit = '$_base/deposit.svg';
  static const String withdraw = '$_base/withdraw.svg';
  static const String history = '$_base/history.svg';
  static const String report = '$_base/report.svg';
  static const String arrowUp = '$_base/arrow_up.svg';
  static const String arrowDown = '$_base/arrow_down.svg';

  // --- Misc ---
  static const String calendar = '$_base/calendar.svg';
  static const String document = '$_base/document.svg';
  static const String share = '$_base/share.svg';
  static const String download = '$_base/download.svg';
  static const String upload = '$_base/upload.svg';
  static const String copy = '$_base/copy.svg';
  static const String scan = '$_base/scan.svg';
  static const String location = '$_base/location.svg';
  static const String email = '$_base/email.svg';

  // --- Features App Bar ---
  static const String appBarBack = '$_base/app_bar/back.svg';
  static const String appBarNotification = '$_base/app_bar/notification.svg';
  static const String appBarFilter = '$_base/app_bar/filter.svg';
  static const String appBarAdd = '$_base/app_bar/add.svg';
  static const String appBarSearch = '$_base/app_bar/search.svg';

  // --- Khach Hang Filter ---
  static const String khachHangFilterSharp =
      '$_base/khach_hang_filter/filter_sharp.svg';
  static const String khachHangSearch = '$_base/khach_hang_filter/search.svg';
  static const String khachHangSave = '$_base/khach_hang_filter/save.svg';
  static const String khachHangClock = '$_base/khach_hang_filter/clock.svg';

  // --- Bang Hang ---
  static const String bangHangSearch = '$_base/bang_hang_search.svg';
  static const String bangHangFilter = '$_base/bang_hang_filter.svg';

  // --- Khach Hang Card ---
  static const String khCardChevronRight =
      '$_base/khach_hang_card/arrow_right.svg';
  static const String khCardPhone = '$_base/khach_hang_card/phone.svg';
  static const String khCardFinance = '$_base/khach_hang_card/finance.svg';
  static const String khCardPerson = '$_base/khach_hang_card/person.svg';
  static const String khCardActionChat = '$_base/khach_hang_card/chat.svg';
  static const String khCardActionZalo = '$_base/khach_hang_card/zalo.svg';
  static const String khCardActionEdit = '$_base/khach_hang_card/edit.svg';
  static const String khCardActionDelete = '$_base/khach_hang_card/delete.svg';

  // --- Bottom Nav New ---
  static const String homeNav = '$_base/home_nav.svg';
  static const String bangHangNav = '$_base/bang_hang_nav.svg';
  static const String ctvNav = '$_base/ctv_nav.svg';
  static const String khachHangNav = '$_base/khach_hang_nav.svg';
  static const String aiAssistant = '$_base/ai_assistant.svg';
  static const String aiSearch = '$_base/ai_search.svg';
  static const String bdsSearchTab = '$_base/bds_search_tab.svg';
  static const String chatbotTab = '$_base/chatbot_tab.svg';
  static const String thunder = '$_base/thunder.svg';
  static const String thunderSolid = '$_base/thunder_solid.svg';
}
