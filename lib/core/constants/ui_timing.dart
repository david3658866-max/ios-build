/// UI 时序常量，与 im-uniapp 对齐。
abstract final class UiTiming {
  /// group-edit / group-invite 成功 Toast 后 `setTimeout(..., 1000)` 再导航。
  static const toastThenNavigate = Duration(milliseconds: 1000);

  /// group-info.vue 退群/解散后 `setTimeout(..., 1500)` 再跳转群列表。
  static const groupLeaveRedirect = Duration(milliseconds: 1500);
}
