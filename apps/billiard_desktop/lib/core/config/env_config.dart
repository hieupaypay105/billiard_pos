/// Config class loading environment variables using `String.fromEnvironment`.
class EnvConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://poscrm.dev.an-holdings.vn/api',
  );

  static const String userLogin = String.fromEnvironment(
    'USER_LOGIN',
    defaultValue: '/user/login',
  );

  static const String userRefresh = String.fromEnvironment(
    'USER_REFRESH',
    defaultValue: '/user/refresh',
  );

  static const String userInfo = String.fromEnvironment(
    'USER_INFO',
    defaultValue: '/user/info',
  );

  static const String userList = String.fromEnvironment(
    'USER_LIST',
    defaultValue: '/user/list',
  );

  static const String tableAreas = String.fromEnvironment(
    'TABLE_AREAS',
    defaultValue: '/table/areas',
  );

  static const String tableList = String.fromEnvironment(
    'TABLE_LIST',
    defaultValue: '/table/list',
  );

  static const String tablePrices = String.fromEnvironment(
    'TABLE_PRICES',
    defaultValue: '/table/prices',
  );

  static const String productCategories = String.fromEnvironment(
    'PRODUCT_CATEGORIES',
    defaultValue: '/product/categories',
  );

  static const String productList = String.fromEnvironment(
    'PRODUCT_LIST',
    defaultValue: '/product/list',
  );

  static const String memberSearch = String.fromEnvironment(
    'MEMBER_SEARCH',
    defaultValue: '/member/search',
  );

  static const String memberList = String.fromEnvironment(
    'MEMBER_LIST',
    defaultValue: '/member/list',
  );

  static const String shiftOpen = String.fromEnvironment(
    'SHIFT_OPEN',
    defaultValue: '/shift/open',
  );

  static const String shiftClose = String.fromEnvironment(
    'SHIFT_CLOSE',
    defaultValue: '/shift/close',
  );

  static const String shiftCurrent = String.fromEnvironment(
    'SHIFT_CURRENT',
    defaultValue: '/shift/current',
  );

  static const String orderOpen = String.fromEnvironment(
    'ORDER_OPEN',
    defaultValue: '/order/open',
  );

  static const String orderActive = String.fromEnvironment(
    'ORDER_ACTIVE',
    defaultValue: '/order/active',
  );

  static const String orderAddDetail = String.fromEnvironment(
    'ORDER_ADD_DETAIL',
    defaultValue: '/order/addDetail',
  );

  static const String orderUpdateDetail = String.fromEnvironment(
    'ORDER_UPDATE_DETAIL',
    defaultValue: '/order/updateDetail',
  );

  static const String orderDeleteDetail = String.fromEnvironment(
    'ORDER_DELETE_DETAIL',
    defaultValue: '/order/deleteDetail',
  );

  static const String orderCheckout = String.fromEnvironment(
    'ORDER_CHECKOUT',
    defaultValue: '/order/checkout',
  );

  static const String orderVoid = String.fromEnvironment(
    'ORDER_VOID',
    defaultValue: '/order/void',
  );

  static const String orderHistory = String.fromEnvironment(
    'ORDER_HISTORY',
    defaultValue: '/order/history',
  );

  static const String orderStopPlay = String.fromEnvironment(
    'ORDER_STOP_PLAY',
    defaultValue: '/order/stopPlay',
  );

  static const String iotConfigs = String.fromEnvironment(
    'IOT_CONFIGS',
    defaultValue: '/iot/configs',
  );

  static const String iotForceAction = String.fromEnvironment(
    'IOT_FORCE_ACTION',
    defaultValue: '/iot/forceAction',
  );

  static const String syncDesktop = String.fromEnvironment(
    'SYNC_DESKTOP',
    defaultValue: '/sync/desktop',
  );

  static const String tableTypes = String.fromEnvironment(
    'TABLE_TYPES',
    defaultValue: '/table/types',
  );

  static const String membershipTiers = String.fromEnvironment(
    'MEMBERSHIP_TIERS',
    defaultValue: '/member/tiers',
  );
}
