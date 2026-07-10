import '../core/http/dio_client.dart';
import '../models/login_dto.dart';
import '../models/login_info.dart';
import '../models/register_dto.dart';

/// 认证 / 账号接口。对应后端 LoginController + CaptchaController。
/// （refreshToken 由 DioClient 内部处理，不在此暴露。）
class AuthApi {
  AuthApi(this._c);

  final DioClient _c;

  /// 登录。POST /login。
  Future<LoginInfo> login(LoginDTO dto) async {
    final data = await _c.post<Map<String, dynamic>>('/login', data: dto.toJson());
    return LoginInfo.fromJson(data);
  }

  /// 注册。POST /register。
  Future<void> register(RegisterDTO dto) =>
      _c.post<dynamic>('/register', data: dto.toJson());

  /// 修改密码。PUT /modifyPwd（body: ModifyPwdDTO，字段以后端为准）。
  Future<void> modifyPwd(Map<String, dynamic> body) =>
      _c.put<dynamic>('/modifyPwd', data: body);

  /// 重置密码。PUT /resetPwd（body: ResetPwdDTO）。
  Future<void> resetPwd(Map<String, dynamic> body) =>
      _c.put<dynamic>('/resetPwd', data: body);

  // ---- 图形/短信/邮箱验证码 ----

  /// 图形验证码。POST /captcha/img/code → {id, image(base64 gif)}。
  Future<Map<String, dynamic>> imageCaptcha() =>
      _c.post<Map<String, dynamic>>('/captcha/img/code');

  /// 校验图形验证码。GET /captcha/img/vertify?id=&code= → bool。
  Future<bool> verifyImageCaptcha(String id, String code) async {
    final r = await _c.get<dynamic>(
      '/captcha/img/vertify',
      query: {'id': id, 'code': code},
    );
    return r == true;
  }

  /// 短信验证码。POST /captcha/sms/code。
  Future<void> sendSmsCode(Map<String, dynamic> body) =>
      _c.post<dynamic>('/captcha/sms/code', data: body);

  /// 邮箱验证码。POST /captcha/mail/code。
  Future<void> sendMailCode(Map<String, dynamic> body) =>
      _c.post<dynamic>('/captcha/mail/code', data: body);

  // ---- 扫码登录 ----

  /// 生成二维码。POST /qrLogin/generate → {qrCode, ...}。
  Future<Map<String, dynamic>> qrGenerate() =>
      _c.post<Map<String, dynamic>>('/qrLogin/generate');

  /// 查询扫码状态。GET /qrLogin/status/{qrCode}。
  Future<Map<String, dynamic>> qrStatus(String qrCode) =>
      _c.get<Map<String, dynamic>>('/qrLogin/status/$qrCode');

  /// 移动端扫描二维码。POST /qrLogin/scan（body: {qrCode}）。
  Future<void> qrScan(String qrCode) =>
      _c.post<dynamic>('/qrLogin/scan', data: {'qrCode': qrCode});

  /// 确认扫码登录。POST /qrLogin/confirm（body: {qrCode}）→ LoginInfo。
  Future<LoginInfo> qrConfirm(String qrCode) async {
    final data = await _c
        .post<Map<String, dynamic>>('/qrLogin/confirm', data: {'qrCode': qrCode});
    return LoginInfo.fromJson(data);
  }

  /// 取消扫码登录。DELETE /qrLogin/cancel/{qrCode}。
  Future<void> qrCancel(String qrCode) =>
      _c.delete<dynamic>('/qrLogin/cancel/$qrCode');
}
