import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_providers.dart';
import '../core/http/api_result.dart';
import 'im_feedback.dart';

/// 图形验证码校验结果：通过后返回验证码 id 与用户输入的 code。
typedef CaptchaResult = ({String id, String code});

/// 图形验证码弹窗。对应 im-uniapp components/captcha-image。
/// 流程：POST /captcha/img/code 取图 → 用户输入 → GET /captcha/img/vertify 校验，
/// 通过则返回 (id, code)，供后续发短信等防盗刷。
class ImageCaptchaDialog extends ConsumerStatefulWidget {
  const ImageCaptchaDialog({super.key});

  /// 打开弹窗，校验通过返回 (id, code)，取消返回 null。
  static Future<CaptchaResult?> show(BuildContext context) {
    return showDialog<CaptchaResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const ImageCaptchaDialog(),
    );
  }

  @override
  ConsumerState<ImageCaptchaDialog> createState() => _ImageCaptchaDialogState();
}

class _ImageCaptchaDialogState extends ConsumerState<ImageCaptchaDialog> {
  final _codeCtrl = TextEditingController();
  String _id = '';
  Uint8List? _imageBytes;
  bool _loading = false;
  bool _verifying = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadImage() async {
    setState(() => _loading = true);
    try {
      final data = await ref.read(authApiProvider).imageCaptcha();
      _id = (data['id'] ?? '').toString();
      final b64 = (data['image'] ?? '').toString();
      _imageBytes = b64.isEmpty ? null : base64Decode(b64);
    } catch (e) {
      _imageBytes = null;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirm() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) {
      _toast('请输入验证码');
      return;
    }
    setState(() => _verifying = true);
    try {
      final ok = await ref.read(authApiProvider).verifyImageCaptcha(_id, code);
      if (!mounted) return;
      if (ok) {
        Navigator.pop<CaptchaResult>(context, (id: _id, code: code));
      } else {
        _toast('验证码错误');
        _loadImage();
      }
    } on ApiException catch (e) {
      if (!e.silent) _toast(e.message);
    } catch (e) {
      _toast('校验失败：${asApiException(e).message}');
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ImFeedback.toast(context, msg);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('图形验证码'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _loading ? null : _loadImage,
            child: Container(
              width: 180,
              height: 70,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : (_imageBytes != null
                      ? Image.memory(_imageBytes!, fit: BoxFit.contain)
                      : const Text('点击重新获取')),
            ),
          ),
          const SizedBox(height: 6),
          const Text('点击图片刷新', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 12),
          TextField(
            controller: _codeCtrl,
            autofocus: true,
            onSubmitted: (_) => _confirm(),
            decoration: const InputDecoration(
              labelText: '验证码（不区分大小写）',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _verifying ? null : () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _verifying ? null : _confirm,
          child: _verifying
              ? const SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('确定'),
        ),
      ],
    );
  }
}
