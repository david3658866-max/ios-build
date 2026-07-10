import 'package:drift/drift.dart';

/// 好友申请表。对应后端 FriendRequestVO。applyTime 存毫秒时间戳。
class FriendRequests extends Table {
  IntColumn get id => integer()();
  IntColumn get sendId => integer().nullable()();
  TextColumn get sendNickName => text().nullable()();
  TextColumn get sendHeadImage => text().nullable()();
  IntColumn get recvId => integer().nullable()();
  TextColumn get recvNickName => text().nullable()();
  TextColumn get recvHeadImage => text().nullable()();
  TextColumn get remark => text().nullable()();

  /// 1待处理/2同意/3拒绝/4过期，见 RequestStatus。
  IntColumn get status => integer().withDefault(const Constant(1))();
  IntColumn get applyTime => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
