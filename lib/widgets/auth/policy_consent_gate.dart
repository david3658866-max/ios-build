import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_constants.dart';
import '../../core/di/app_providers.dart';
import '../../core/utils/policy_consent_util.dart';
import '../../router/app_router.dart';
import 'policy_consent_panel.dart';

/// 登录页协议门禁。对齐 login.vue `<policy>`。
class PolicyConsentGate extends ConsumerStatefulWidget {
  const PolicyConsentGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PolicyConsentGate> createState() => _PolicyConsentGateState();
}

class _PolicyConsentGateState extends ConsumerState<PolicyConsentGate> {
  bool _showConsent = false;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshConsentState());
  }

  void _refreshConsentState() {
    final kv = ref.read(kvStoreProvider);
    final show = PolicyConsentUtil.shouldShowConsent(kv: kv);
    if (!mounted) return;
    setState(() {
      _checked = true;
      _showConsent = show;
    });
  }

  Future<void> _onAgree() async {
    await PolicyConsentUtil.markAccepted(ref.read(kvStoreProvider));
    if (!mounted) return;
    setState(() => _showConsent = false);
  }

  void _onDecline() => SystemNavigator.pop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_checked && _showConsent)
          Positioned.fill(
            child: PolicyConsentPanel(
              onAgree: _onAgree,
              onDecline: _onDecline,
              onOpenProtocol: () => context.push(
                AppRoutes.externalLinkPath(AppConstants.protocolUrl),
              ),
              onOpenPrivacy: () => context.push(
                AppRoutes.externalLinkPath(AppConstants.privacyUrl),
              ),
            ),
          ),
      ],
    );
  }
}
