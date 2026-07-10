import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../theme/rpx.dart';

/// 服务协议与隐私政策弹层。对齐 policy.vue 布局与文案。
class PolicyConsentPanel extends StatelessWidget {
  const PolicyConsentPanel({
    super.key,
    required this.onAgree,
    required this.onDecline,
    required this.onOpenProtocol,
    required this.onOpenPrivacy,
  });

  final VoidCallback onAgree;
  final VoidCallback onDecline;
  final VoidCallback onOpenProtocol;
  final VoidCallback onOpenPrivacy;

  @override
  Widget build(BuildContext context) {
    final linkStyle = TextStyle(
      fontSize: rpx(context, 30),
      color: const Color(0xFF007AFF),
      height: 1.35,
    );
    final bodyStyle = TextStyle(
      fontSize: rpx(context, 30),
      color: const Color(0xFF333333),
      height: 1.35,
    );

    return Material(
      color: Colors.black.withValues(alpha: 0.4),
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () {},
              behavior: HitTestBehavior.opaque,
              child: const SizedBox.expand(),
            ),
          ),
          Align(
            alignment: const Alignment(0, 0.2),
            child: FractionallySizedBox(
              widthFactor: 0.8,
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(rpx(context, 16)),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: rpx(context, 20)),
                      child: Text(
                        '服务协议和隐私政策',
                        style: TextStyle(
                          fontSize: rpx(context, 34),
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1F2432),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        rpx(context, 30),
                        rpx(context, 30),
                        rpx(context, 30),
                        rpx(context, 40),
                      ),
                      child: RichText(
                        text: TextSpan(
                          style: bodyStyle,
                          children: [
                            const TextSpan(
                              text:
                                  '请你务必认真阅读、充分理解“服务协议”和“隐私政策”各条款，包括但不限于：为了向你提供数据、分享等服务所要获取的权限信息。',
                            ),
                            const TextSpan(text: '\n'),
                            TextSpan(
                              text: '你可以阅读',
                              style: bodyStyle,
                            ),
                            TextSpan(
                              text: '《用户协议》',
                              style: linkStyle,
                              recognizer: TapGestureRecognizer()
                                ..onTap = onOpenProtocol,
                            ),
                            TextSpan(text: '和', style: bodyStyle),
                            TextSpan(
                              text: '《隐私政策》',
                              style: linkStyle,
                              recognizer: TapGestureRecognizer()
                                ..onTap = onOpenPrivacy,
                            ),
                            TextSpan(
                              text:
                                  '了解详细信息。如您同意，请点击"同意"开始接受我们的服务。',
                              style: bodyStyle,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: const Color(0xFFF2F2F2),
                    ),
                    SizedBox(
                      height: rpx(context, 100),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: onDecline,
                              child: Center(
                                child: Text(
                                  '暂不使用',
                                  style: TextStyle(
                                    fontSize: rpx(context, 34),
                                    color: const Color(0xFF333333),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: onAgree,
                              child: Center(
                                child: Text(
                                  '同意',
                                  style: TextStyle(
                                    fontSize: rpx(context, 34),
                                    color: const Color(0xFF333333),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
