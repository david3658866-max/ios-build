import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/enums/message_type.dart';
import '../../core/storage/app_database.dart';
import '../../core/utils/group_sender_util.dart';
import '../../theme/im_colors.dart';
import '../../theme/rpx.dart';
import 'chat_sender_name_row.dart';
import 'head_image.dart';

enum FinancialCardVariant { contract, loan, product }

/// 金融类卡片气泡（合同/借款/产品）。对齐 chat-message-item.vue 大卡片样式。
class FinancialCardBubble extends StatelessWidget {
  const FinancialCardBubble({
    super.key,
    required this.message,
    required this.selfSend,
    required this.variant,
    this.senderName,
    this.senderRoles = const {},
    this.onTap,
    this.onLongPress,
  });

  final Message message;
  final bool selfSend;
  final FinancialCardVariant variant;
  final String? senderName;
  final Set<GroupSenderRole> senderRoles;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  static const Color _divider = Color(0xFFF0F0F0);
  static const Color _labelColor = Color(0xFF666666);
  static const Color _amountColor = Color(0xFFFF6B35);

  static FinancialCardVariant variantOf(int type) {
    if (type == MessageType.loanCard) return FinancialCardVariant.loan;
    if (type == MessageType.productCard) return FinancialCardVariant.product;
    return FinancialCardVariant.contract;
  }

  /// 对齐 uniapp `getLoanStatusClass`。
  static (Color bg, Color fg) loanStatusColors(int? status) {
    if (status == 0 || status == 36) {
      return (const Color(0xFFFFF3E0), const Color(0xFFFF9800));
    }
    if (status == 32) {
      return (const Color(0xFFFFEBEE), const Color(0xFFF44336));
    }
    if (status == 35) {
      return (const Color(0xFFE3F2FD), const Color(0xFF2196F3));
    }
    if (status == 42) {
      return (const Color(0xFFE8F5E9), const Color(0xFF4CAF50));
    }
    if (status == 43) {
      return (const Color(0xFFE1F5FE), const Color(0xFF00BCD4));
    }
    if (status == 53) {
      return (const Color(0xFFF3E5F5), const Color(0xFF9C27B0));
    }
    return (const Color(0xFFF5F5F5), const Color(0xFF666666));
  }

  @override
  Widget build(BuildContext context) {
    final data = _parse(message.content);
    final headerTitle = _headerTitle(data);
    final iconUrl = data['icon']?.toString();
    final footer = switch (variant) {
      FinancialCardVariant.contract => '点击查看合同',
      FinancialCardVariant.loan => '点击查看借款',
      FinancialCardVariant.product => '点击查看产品',
    };

    return Column(
      crossAxisAlignment:
          selfSend ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        ?chatSenderNameLine(
          context,
          selfSend: selfSend,
          name: senderName,
          roles: senderRoles,
        ),
        GestureDetector(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Container(
            width: rpx(context, 400),
            padding: EdgeInsets.fromLTRB(
              rpx(context, 24),
              rpx(context, 20),
              rpx(context, 24),
              rpx(context, 16),
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(rpx(context, 12)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header(context, iconUrl: iconUrl, title: headerTitle),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: rpx(context, 8)),
                  child: Column(
                    children: _detailRows(context, data),
                  ),
                ),
                Container(height: rpx(context, 2), color: _divider),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: rpx(context, 10)),
                  child: Text(
                    footer,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: rpx(context, 26),
                      color: ImColors.textLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _header(
    BuildContext context, {
    required String? iconUrl,
    required String title,
  }) {
    return Container(
      padding: EdgeInsets.only(bottom: rpx(context, 12)),
      margin: EdgeInsets.only(bottom: rpx(context, 16)),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _divider, width: 2)),
      ),
      child: Row(
        children: [
          HeadImage(url: iconUrl, name: title, size: 80),
          SizedBox(width: rpx(context, 16)),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: rpx(context, 30),
                fontWeight: FontWeight.w600,
                color: ImColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _headerTitle(Map<String, dynamic> data) {
    return switch (variant) {
      FinancialCardVariant.contract =>
        data['title']?.toString() ??
            data['contractNumber']?.toString() ??
            '合同',
      FinancialCardVariant.loan =>
        data['product']?.toString() ?? data['title']?.toString() ?? '借款',
      FinancialCardVariant.product =>
        data['productName']?.toString() ??
            data['title']?.toString() ??
            '产品',
    };
  }

  List<Widget> _detailRows(BuildContext context, Map<String, dynamic> data) {
    final rows = <Widget>[];
    switch (variant) {
      case FinancialCardVariant.contract:
        _addInfo(rows, context, '合同编号', data['contractNumber']?.toString());
        _addAmount(rows, context, '合同金额', data['contractAmount']);
        _addInfo(rows, context, '借款编号', data['loanId']?.toString());
        _addInfo(rows, context, '借款时间', data['loanApplyTime']?.toString());
        _addStatus(
          rows,
          context,
          '借款状态',
          data['loanStatusText']?.toString(),
          _statusCode(data['loanStatus']),
        );
      case FinancialCardVariant.loan:
        _addAmount(rows, context, '借款金额', data['amount']);
        _addInfo(rows, context, '借款时间', data['loanTime']?.toString());
        _addInfo(
          rows,
          context,
          '期数',
          data['loanMonth'] != null ? '${data['loanMonth']}期' : null,
        );
        _addInfo(rows, context, '还款方式', data['repayMethod']?.toString());
        _addInfo(
          rows,
          context,
          '利率',
          data['interestRate'] != null ? '${data['interestRate']}%' : null,
        );
        _addStatus(
          rows,
          context,
          '状态',
          data['statusText']?.toString(),
          _statusCode(data['status']),
        );
      case FinancialCardVariant.product:
        _addAmount(rows, context, '最高可借', data['loanAmountMax'], format: true);
        _addInfo(
          rows,
          context,
          '最低利率',
          data['minimumYearRate']?.toString() ??
              (data['interestRate'] != null
                  ? '${data['interestRate']}%'
                  : null),
        );
        _addInfo(rows, context, '产品亮点', data['productHighlights']?.toString());
    }
    return rows;
  }

  int? _statusCode(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    return int.tryParse(raw.toString());
  }

  void _addInfo(
    List<Widget> rows,
    BuildContext context,
    String label,
    String? value,
  ) {
    if (value == null || value.isEmpty) return;
    rows.add(_infoRow(context, label, value));
  }

  void _addAmount(
    List<Widget> rows,
    BuildContext context,
    String label,
    dynamic value, {
    bool format = false,
  }) {
    final text = format ? _formatAmount(value) : _money(value);
    if (text == null || text.isEmpty) return;
    rows.add(_infoRow(context, label, text, isAmount: true));
  }

  void _addStatus(
    List<Widget> rows,
    BuildContext context,
    String label,
    String? text,
    int? status,
  ) {
    if (text == null || text.isEmpty) return;
    rows.add(_statusRow(context, label, text, status));
  }

  Widget _infoRow(
    BuildContext context,
    String label,
    String value, {
    bool isAmount = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: rpx(context, 10)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: rpx(context, 130),
            child: Text(
              '$label：',
              style: TextStyle(
                fontSize: rpx(context, 26),
                color: _labelColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: isAmount ? rpx(context, 32) : rpx(context, 26),
                fontWeight: isAmount ? FontWeight.w600 : FontWeight.w500,
                color: isAmount ? _amountColor : ImColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusRow(
    BuildContext context,
    String label,
    String text,
    int? status,
  ) {
    final (bg, fg) = loanStatusColors(status);
    return Padding(
      padding: EdgeInsets.only(bottom: rpx(context, 10)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: rpx(context, 130),
            child: Text(
              '$label：',
              style: TextStyle(
                fontSize: rpx(context, 26),
                color: _labelColor,
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: rpx(context, 10),
                vertical: rpx(context, 3),
              ),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(rpx(context, 6)),
              ),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: rpx(context, 22),
                  fontWeight: FontWeight.w500,
                  color: fg,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _money(dynamic v) {
    if (v == null) return null;
    final s = v.toString();
    if (s.isEmpty) return null;
    return s.startsWith('¥') ? s : '¥$s';
  }

  String? _formatAmount(dynamic v) {
    if (v == null) return null;
    final num? n = v is num ? v : num.tryParse(v.toString());
    if (n == null) return '¥0.00';
    return '¥${n.toStringAsFixed(2)}';
  }

  Map<String, dynamic> _parse(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return {};
  }
}
