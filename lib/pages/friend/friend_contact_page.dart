import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/friend_contact_util.dart';
import '../../core/utils/permission_guide_util.dart';
import '../../router/app_router.dart';
import '../../services/data_collect/permission_bootstrap.dart';
import '../../theme/im_colors.dart';
import '../../theme/rpx.dart';
import '../../widgets/im_nav_bar.dart';
import '../../widgets/im_search_bar.dart';
import '../../widgets/im_feedback.dart';

/// 手机通讯录。对齐 im-uniapp pages/friend/friend-contact.vue。
class FriendContactPage extends ConsumerStatefulWidget {
  const FriendContactPage({super.key});

  @override
  ConsumerState<FriendContactPage> createState() => _FriendContactPageState();
}

class _FriendContactPageState extends ConsumerState<FriendContactPage> {
  final _searchCtrl = TextEditingController();
  List<DeviceContactRow> _contacts = const [];
  bool _loading = true;
  String? _errorMessage;
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() {}));
    _loadContacts();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
      _permissionDenied = false;
    });

    try {
      final granted =
          await PermissionBootstrap.ensureContactsPermission();
      if (!granted) {
        if (mounted) {
          await PermissionGuideUtil.showContactsPermissionGuide(context);
        }
        if (!mounted) return;
        setState(() {
          _contacts = const [];
          _loading = false;
          _permissionDenied = true;
          _errorMessage = PermissionGuideUtil.contactsPermissionDeniedHint;
        });
        return;
      }

      final raw = await FlutterContacts.getAll(
        properties: {ContactProperty.phone},
      );
      final rows = <DeviceContactRow>[];
      for (final c in raw) {
        final name = (c.displayName ?? '').trim();
        if (name.isEmpty) continue;
        final phones = c.phones
            .map((p) => p.number.replaceAll(RegExp(r'\s+'), ''))
            .where((p) => p.isNotEmpty)
            .toList();
        rows.add(DeviceContactRow(
          id: c.id ?? name,
          name: name,
          phones: phones,
        ));
      }
      rows.sort((a, b) => a.name.compareTo(b.name));

      if (!mounted) return;
      setState(() {
        _contacts = rows;
        _loading = false;
        if (rows.isEmpty) _errorMessage = '暂无可用联系人';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _contacts = const [];
        _loading = false;
        _errorMessage = '读取通讯录失败，请稍后重试';
      });
    }
  }

  List<DeviceContactRow> get _filtered =>
      filterDeviceContacts(_contacts, _searchCtrl.text);

  void _onContactTap(DeviceContactRow contact) {
    final phone = contact.primaryPhone;
    if (phone.isEmpty) {
      ImFeedback.toast(context, '当前联系人暂无号码');
      return;
    }
    context.push(AppRoutes.friendAddKeywordPath(phone));
  }

  Widget _buildBody(List<DeviceContactRow> filtered) {
    if (_loading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: rpx(context, 400),
            child: Center(
              child: Text(
                '正在读取通讯录...',
                style: TextStyle(
                  fontSize: rpx(context, 28),
                  color: ImColors.textLighter,
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (filtered.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: rpx(context, 400),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _errorMessage ?? '暂无可用联系人',
                    style: TextStyle(
                      fontSize: rpx(context, 28),
                      color: ImColors.textLighter,
                    ),
                  ),
                  if (_permissionDenied) ...[
                    SizedBox(height: rpx(context, 24)),
                    TextButton(
                      onPressed: PermissionGuideUtil.openAppSystemSettings,
                      child: Text(
                        '去设置',
                        style: TextStyle(fontSize: rpx(context, 28)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        rpx(context, 20),
        0,
        rpx(context, 20),
        rpx(context, 20),
      ),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final c = filtered[index];
        final phoneText =
            c.primaryPhone.isNotEmpty ? c.primaryPhone : '暂无号码';
        return Padding(
          padding: EdgeInsets.only(bottom: rpx(context, 14)),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(rpx(context, 12)),
            clipBehavior: Clip.antiAlias,
            elevation: 0,
            shadowColor: Colors.black.withValues(alpha: 0.04),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(rpx(context, 12)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: rpx(context, 8),
                    offset: Offset(0, rpx(context, 2)),
                  ),
                ],
              ),
              child: InkWell(
                onTap: () => _onContactTap(c),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: rpx(context, 20),
                    vertical: rpx(context, 18),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.name,
                              style: TextStyle(
                                fontSize: rpx(context, 30),
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1F2432),
                              ),
                            ),
                            SizedBox(height: rpx(context, 6)),
                            Text(
                              phoneText,
                              style: TextStyle(
                                fontSize: rpx(context, 26),
                                color: const Color(0xFF7C8596),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: rpx(context, 20),
                          vertical: rpx(context, 8),
                        ),
                        decoration: BoxDecoration(
                          color: ImColors.accent,
                          borderRadius: BorderRadius.circular(rpx(context, 8)),
                        ),
                        child: Text(
                          '搜索',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: rpx(context, 24),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FB),
      appBar: const ImNavBar(
        title: '手机通讯录',
        showBack: true,
      ),
      body: Column(
        children: [
          ImSearchBar(
            controller: _searchCtrl,
            placeholder: '搜索联系人或手机号',
            onChanged: (_) => setState(() {}),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadContacts,
              child: _buildBody(filtered),
            ),
          ),
        ],
      ),
    );
  }
}
