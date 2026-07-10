// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ChatsTable extends Chats with TableInfo<$ChatsTable, Chat> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChatsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetIdMeta = const VerificationMeta(
    'targetId',
  );
  @override
  late final GeneratedColumn<int> targetId = GeneratedColumn<int>(
    'target_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _showNameMeta = const VerificationMeta(
    'showName',
  );
  @override
  late final GeneratedColumn<String> showName = GeneratedColumn<String>(
    'show_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _headImageMeta = const VerificationMeta(
    'headImage',
  );
  @override
  late final GeneratedColumn<String> headImage = GeneratedColumn<String>(
    'head_image',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _companyNameMeta = const VerificationMeta(
    'companyName',
  );
  @override
  late final GeneratedColumn<String> companyName = GeneratedColumn<String>(
    'company_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastContentMeta = const VerificationMeta(
    'lastContent',
  );
  @override
  late final GeneratedColumn<String> lastContent = GeneratedColumn<String>(
    'last_content',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSendTimeMeta = const VerificationMeta(
    'lastSendTime',
  );
  @override
  late final GeneratedColumn<int> lastSendTime = GeneratedColumn<int>(
    'last_send_time',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sendNickNameMeta = const VerificationMeta(
    'sendNickName',
  );
  @override
  late final GeneratedColumn<String> sendNickName = GeneratedColumn<String>(
    'send_nick_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastMsgTypeMeta = const VerificationMeta(
    'lastMsgType',
  );
  @override
  late final GeneratedColumn<int> lastMsgType = GeneratedColumn<int>(
    'last_msg_type',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unreadCountMeta = const VerificationMeta(
    'unreadCount',
  );
  @override
  late final GeneratedColumn<int> unreadCount = GeneratedColumn<int>(
    'unread_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _atMeMeta = const VerificationMeta('atMe');
  @override
  late final GeneratedColumn<bool> atMe = GeneratedColumn<bool>(
    'at_me',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("at_me" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _atAllMeta = const VerificationMeta('atAll');
  @override
  late final GeneratedColumn<bool> atAll = GeneratedColumn<bool>(
    'at_all',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("at_all" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastAtMessageIdMeta = const VerificationMeta(
    'lastAtMessageId',
  );
  @override
  late final GeneratedColumn<int> lastAtMessageId = GeneratedColumn<int>(
    'last_at_message_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(-1),
  );
  static const VerificationMeta _isDndMeta = const VerificationMeta('isDnd');
  @override
  late final GeneratedColumn<bool> isDnd = GeneratedColumn<bool>(
    'is_dnd',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_dnd" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isTopMeta = const VerificationMeta('isTop');
  @override
  late final GeneratedColumn<bool> isTop = GeneratedColumn<bool>(
    'is_top',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_top" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastMsgIdMeta = const VerificationMeta(
    'lastMsgId',
  );
  @override
  late final GeneratedColumn<int> lastMsgId = GeneratedColumn<int>(
    'last_msg_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _messagesLoadedMeta = const VerificationMeta(
    'messagesLoaded',
  );
  @override
  late final GeneratedColumn<bool> messagesLoaded = GeneratedColumn<bool>(
    'messages_loaded',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("messages_loaded" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    targetId,
    showName,
    headImage,
    companyName,
    lastContent,
    lastSendTime,
    sendNickName,
    lastMsgType,
    unreadCount,
    atMe,
    atAll,
    lastAtMessageId,
    isDnd,
    isTop,
    lastMsgId,
    messagesLoaded,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chats';
  @override
  VerificationContext validateIntegrity(
    Insertable<Chat> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('target_id')) {
      context.handle(
        _targetIdMeta,
        targetId.isAcceptableOrUnknown(data['target_id']!, _targetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_targetIdMeta);
    }
    if (data.containsKey('show_name')) {
      context.handle(
        _showNameMeta,
        showName.isAcceptableOrUnknown(data['show_name']!, _showNameMeta),
      );
    }
    if (data.containsKey('head_image')) {
      context.handle(
        _headImageMeta,
        headImage.isAcceptableOrUnknown(data['head_image']!, _headImageMeta),
      );
    }
    if (data.containsKey('company_name')) {
      context.handle(
        _companyNameMeta,
        companyName.isAcceptableOrUnknown(
          data['company_name']!,
          _companyNameMeta,
        ),
      );
    }
    if (data.containsKey('last_content')) {
      context.handle(
        _lastContentMeta,
        lastContent.isAcceptableOrUnknown(
          data['last_content']!,
          _lastContentMeta,
        ),
      );
    }
    if (data.containsKey('last_send_time')) {
      context.handle(
        _lastSendTimeMeta,
        lastSendTime.isAcceptableOrUnknown(
          data['last_send_time']!,
          _lastSendTimeMeta,
        ),
      );
    }
    if (data.containsKey('send_nick_name')) {
      context.handle(
        _sendNickNameMeta,
        sendNickName.isAcceptableOrUnknown(
          data['send_nick_name']!,
          _sendNickNameMeta,
        ),
      );
    }
    if (data.containsKey('last_msg_type')) {
      context.handle(
        _lastMsgTypeMeta,
        lastMsgType.isAcceptableOrUnknown(
          data['last_msg_type']!,
          _lastMsgTypeMeta,
        ),
      );
    }
    if (data.containsKey('unread_count')) {
      context.handle(
        _unreadCountMeta,
        unreadCount.isAcceptableOrUnknown(
          data['unread_count']!,
          _unreadCountMeta,
        ),
      );
    }
    if (data.containsKey('at_me')) {
      context.handle(
        _atMeMeta,
        atMe.isAcceptableOrUnknown(data['at_me']!, _atMeMeta),
      );
    }
    if (data.containsKey('at_all')) {
      context.handle(
        _atAllMeta,
        atAll.isAcceptableOrUnknown(data['at_all']!, _atAllMeta),
      );
    }
    if (data.containsKey('last_at_message_id')) {
      context.handle(
        _lastAtMessageIdMeta,
        lastAtMessageId.isAcceptableOrUnknown(
          data['last_at_message_id']!,
          _lastAtMessageIdMeta,
        ),
      );
    }
    if (data.containsKey('is_dnd')) {
      context.handle(
        _isDndMeta,
        isDnd.isAcceptableOrUnknown(data['is_dnd']!, _isDndMeta),
      );
    }
    if (data.containsKey('is_top')) {
      context.handle(
        _isTopMeta,
        isTop.isAcceptableOrUnknown(data['is_top']!, _isTopMeta),
      );
    }
    if (data.containsKey('last_msg_id')) {
      context.handle(
        _lastMsgIdMeta,
        lastMsgId.isAcceptableOrUnknown(data['last_msg_id']!, _lastMsgIdMeta),
      );
    }
    if (data.containsKey('messages_loaded')) {
      context.handle(
        _messagesLoadedMeta,
        messagesLoaded.isAcceptableOrUnknown(
          data['messages_loaded']!,
          _messagesLoadedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {type, targetId},
  ];
  @override
  Chat map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Chat(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      targetId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_id'],
      )!,
      showName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}show_name'],
      ),
      headImage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}head_image'],
      ),
      companyName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company_name'],
      ),
      lastContent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_content'],
      ),
      lastSendTime: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_send_time'],
      ),
      sendNickName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}send_nick_name'],
      ),
      lastMsgType: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_msg_type'],
      ),
      unreadCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unread_count'],
      )!,
      atMe: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}at_me'],
      )!,
      atAll: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}at_all'],
      )!,
      lastAtMessageId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_at_message_id'],
      )!,
      isDnd: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_dnd'],
      )!,
      isTop: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_top'],
      )!,
      lastMsgId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_msg_id'],
      )!,
      messagesLoaded: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}messages_loaded'],
      )!,
    );
  }

  @override
  $ChatsTable createAlias(String alias) {
    return $ChatsTable(attachedDatabase, alias);
  }
}

class Chat extends DataClass implements Insertable<Chat> {
  final int id;

  /// PRIVATE / GROUP / SYSTEM。
  final String type;

  /// 好友id / 群id / 0(系统)。
  final int targetId;
  final String? showName;
  final String? headImage;
  final String? companyName;
  final String? lastContent;
  final int? lastSendTime;
  final String? sendNickName;

  /// 末条消息类型（对齐 uniapp chat-item isShowSendName 用 messages[last].type）。
  final int? lastMsgType;
  final int unreadCount;
  final bool atMe;
  final bool atAll;
  final int lastAtMessageId;
  final bool isDnd;
  final bool isTop;

  /// 本地已拉取的最大消息 id。
  final int lastMsgId;

  /// 是否已加载过历史消息。
  final bool messagesLoaded;
  const Chat({
    required this.id,
    required this.type,
    required this.targetId,
    this.showName,
    this.headImage,
    this.companyName,
    this.lastContent,
    this.lastSendTime,
    this.sendNickName,
    this.lastMsgType,
    required this.unreadCount,
    required this.atMe,
    required this.atAll,
    required this.lastAtMessageId,
    required this.isDnd,
    required this.isTop,
    required this.lastMsgId,
    required this.messagesLoaded,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['type'] = Variable<String>(type);
    map['target_id'] = Variable<int>(targetId);
    if (!nullToAbsent || showName != null) {
      map['show_name'] = Variable<String>(showName);
    }
    if (!nullToAbsent || headImage != null) {
      map['head_image'] = Variable<String>(headImage);
    }
    if (!nullToAbsent || companyName != null) {
      map['company_name'] = Variable<String>(companyName);
    }
    if (!nullToAbsent || lastContent != null) {
      map['last_content'] = Variable<String>(lastContent);
    }
    if (!nullToAbsent || lastSendTime != null) {
      map['last_send_time'] = Variable<int>(lastSendTime);
    }
    if (!nullToAbsent || sendNickName != null) {
      map['send_nick_name'] = Variable<String>(sendNickName);
    }
    if (!nullToAbsent || lastMsgType != null) {
      map['last_msg_type'] = Variable<int>(lastMsgType);
    }
    map['unread_count'] = Variable<int>(unreadCount);
    map['at_me'] = Variable<bool>(atMe);
    map['at_all'] = Variable<bool>(atAll);
    map['last_at_message_id'] = Variable<int>(lastAtMessageId);
    map['is_dnd'] = Variable<bool>(isDnd);
    map['is_top'] = Variable<bool>(isTop);
    map['last_msg_id'] = Variable<int>(lastMsgId);
    map['messages_loaded'] = Variable<bool>(messagesLoaded);
    return map;
  }

  ChatsCompanion toCompanion(bool nullToAbsent) {
    return ChatsCompanion(
      id: Value(id),
      type: Value(type),
      targetId: Value(targetId),
      showName: showName == null && nullToAbsent
          ? const Value.absent()
          : Value(showName),
      headImage: headImage == null && nullToAbsent
          ? const Value.absent()
          : Value(headImage),
      companyName: companyName == null && nullToAbsent
          ? const Value.absent()
          : Value(companyName),
      lastContent: lastContent == null && nullToAbsent
          ? const Value.absent()
          : Value(lastContent),
      lastSendTime: lastSendTime == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSendTime),
      sendNickName: sendNickName == null && nullToAbsent
          ? const Value.absent()
          : Value(sendNickName),
      lastMsgType: lastMsgType == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMsgType),
      unreadCount: Value(unreadCount),
      atMe: Value(atMe),
      atAll: Value(atAll),
      lastAtMessageId: Value(lastAtMessageId),
      isDnd: Value(isDnd),
      isTop: Value(isTop),
      lastMsgId: Value(lastMsgId),
      messagesLoaded: Value(messagesLoaded),
    );
  }

  factory Chat.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Chat(
      id: serializer.fromJson<int>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      targetId: serializer.fromJson<int>(json['targetId']),
      showName: serializer.fromJson<String?>(json['showName']),
      headImage: serializer.fromJson<String?>(json['headImage']),
      companyName: serializer.fromJson<String?>(json['companyName']),
      lastContent: serializer.fromJson<String?>(json['lastContent']),
      lastSendTime: serializer.fromJson<int?>(json['lastSendTime']),
      sendNickName: serializer.fromJson<String?>(json['sendNickName']),
      lastMsgType: serializer.fromJson<int?>(json['lastMsgType']),
      unreadCount: serializer.fromJson<int>(json['unreadCount']),
      atMe: serializer.fromJson<bool>(json['atMe']),
      atAll: serializer.fromJson<bool>(json['atAll']),
      lastAtMessageId: serializer.fromJson<int>(json['lastAtMessageId']),
      isDnd: serializer.fromJson<bool>(json['isDnd']),
      isTop: serializer.fromJson<bool>(json['isTop']),
      lastMsgId: serializer.fromJson<int>(json['lastMsgId']),
      messagesLoaded: serializer.fromJson<bool>(json['messagesLoaded']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'type': serializer.toJson<String>(type),
      'targetId': serializer.toJson<int>(targetId),
      'showName': serializer.toJson<String?>(showName),
      'headImage': serializer.toJson<String?>(headImage),
      'companyName': serializer.toJson<String?>(companyName),
      'lastContent': serializer.toJson<String?>(lastContent),
      'lastSendTime': serializer.toJson<int?>(lastSendTime),
      'sendNickName': serializer.toJson<String?>(sendNickName),
      'lastMsgType': serializer.toJson<int?>(lastMsgType),
      'unreadCount': serializer.toJson<int>(unreadCount),
      'atMe': serializer.toJson<bool>(atMe),
      'atAll': serializer.toJson<bool>(atAll),
      'lastAtMessageId': serializer.toJson<int>(lastAtMessageId),
      'isDnd': serializer.toJson<bool>(isDnd),
      'isTop': serializer.toJson<bool>(isTop),
      'lastMsgId': serializer.toJson<int>(lastMsgId),
      'messagesLoaded': serializer.toJson<bool>(messagesLoaded),
    };
  }

  Chat copyWith({
    int? id,
    String? type,
    int? targetId,
    Value<String?> showName = const Value.absent(),
    Value<String?> headImage = const Value.absent(),
    Value<String?> companyName = const Value.absent(),
    Value<String?> lastContent = const Value.absent(),
    Value<int?> lastSendTime = const Value.absent(),
    Value<String?> sendNickName = const Value.absent(),
    Value<int?> lastMsgType = const Value.absent(),
    int? unreadCount,
    bool? atMe,
    bool? atAll,
    int? lastAtMessageId,
    bool? isDnd,
    bool? isTop,
    int? lastMsgId,
    bool? messagesLoaded,
  }) => Chat(
    id: id ?? this.id,
    type: type ?? this.type,
    targetId: targetId ?? this.targetId,
    showName: showName.present ? showName.value : this.showName,
    headImage: headImage.present ? headImage.value : this.headImage,
    companyName: companyName.present ? companyName.value : this.companyName,
    lastContent: lastContent.present ? lastContent.value : this.lastContent,
    lastSendTime: lastSendTime.present ? lastSendTime.value : this.lastSendTime,
    sendNickName: sendNickName.present ? sendNickName.value : this.sendNickName,
    lastMsgType: lastMsgType.present ? lastMsgType.value : this.lastMsgType,
    unreadCount: unreadCount ?? this.unreadCount,
    atMe: atMe ?? this.atMe,
    atAll: atAll ?? this.atAll,
    lastAtMessageId: lastAtMessageId ?? this.lastAtMessageId,
    isDnd: isDnd ?? this.isDnd,
    isTop: isTop ?? this.isTop,
    lastMsgId: lastMsgId ?? this.lastMsgId,
    messagesLoaded: messagesLoaded ?? this.messagesLoaded,
  );
  Chat copyWithCompanion(ChatsCompanion data) {
    return Chat(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      targetId: data.targetId.present ? data.targetId.value : this.targetId,
      showName: data.showName.present ? data.showName.value : this.showName,
      headImage: data.headImage.present ? data.headImage.value : this.headImage,
      companyName: data.companyName.present
          ? data.companyName.value
          : this.companyName,
      lastContent: data.lastContent.present
          ? data.lastContent.value
          : this.lastContent,
      lastSendTime: data.lastSendTime.present
          ? data.lastSendTime.value
          : this.lastSendTime,
      sendNickName: data.sendNickName.present
          ? data.sendNickName.value
          : this.sendNickName,
      lastMsgType: data.lastMsgType.present
          ? data.lastMsgType.value
          : this.lastMsgType,
      unreadCount: data.unreadCount.present
          ? data.unreadCount.value
          : this.unreadCount,
      atMe: data.atMe.present ? data.atMe.value : this.atMe,
      atAll: data.atAll.present ? data.atAll.value : this.atAll,
      lastAtMessageId: data.lastAtMessageId.present
          ? data.lastAtMessageId.value
          : this.lastAtMessageId,
      isDnd: data.isDnd.present ? data.isDnd.value : this.isDnd,
      isTop: data.isTop.present ? data.isTop.value : this.isTop,
      lastMsgId: data.lastMsgId.present ? data.lastMsgId.value : this.lastMsgId,
      messagesLoaded: data.messagesLoaded.present
          ? data.messagesLoaded.value
          : this.messagesLoaded,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Chat(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('targetId: $targetId, ')
          ..write('showName: $showName, ')
          ..write('headImage: $headImage, ')
          ..write('companyName: $companyName, ')
          ..write('lastContent: $lastContent, ')
          ..write('lastSendTime: $lastSendTime, ')
          ..write('sendNickName: $sendNickName, ')
          ..write('lastMsgType: $lastMsgType, ')
          ..write('unreadCount: $unreadCount, ')
          ..write('atMe: $atMe, ')
          ..write('atAll: $atAll, ')
          ..write('lastAtMessageId: $lastAtMessageId, ')
          ..write('isDnd: $isDnd, ')
          ..write('isTop: $isTop, ')
          ..write('lastMsgId: $lastMsgId, ')
          ..write('messagesLoaded: $messagesLoaded')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    type,
    targetId,
    showName,
    headImage,
    companyName,
    lastContent,
    lastSendTime,
    sendNickName,
    lastMsgType,
    unreadCount,
    atMe,
    atAll,
    lastAtMessageId,
    isDnd,
    isTop,
    lastMsgId,
    messagesLoaded,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Chat &&
          other.id == this.id &&
          other.type == this.type &&
          other.targetId == this.targetId &&
          other.showName == this.showName &&
          other.headImage == this.headImage &&
          other.companyName == this.companyName &&
          other.lastContent == this.lastContent &&
          other.lastSendTime == this.lastSendTime &&
          other.sendNickName == this.sendNickName &&
          other.lastMsgType == this.lastMsgType &&
          other.unreadCount == this.unreadCount &&
          other.atMe == this.atMe &&
          other.atAll == this.atAll &&
          other.lastAtMessageId == this.lastAtMessageId &&
          other.isDnd == this.isDnd &&
          other.isTop == this.isTop &&
          other.lastMsgId == this.lastMsgId &&
          other.messagesLoaded == this.messagesLoaded);
}

class ChatsCompanion extends UpdateCompanion<Chat> {
  final Value<int> id;
  final Value<String> type;
  final Value<int> targetId;
  final Value<String?> showName;
  final Value<String?> headImage;
  final Value<String?> companyName;
  final Value<String?> lastContent;
  final Value<int?> lastSendTime;
  final Value<String?> sendNickName;
  final Value<int?> lastMsgType;
  final Value<int> unreadCount;
  final Value<bool> atMe;
  final Value<bool> atAll;
  final Value<int> lastAtMessageId;
  final Value<bool> isDnd;
  final Value<bool> isTop;
  final Value<int> lastMsgId;
  final Value<bool> messagesLoaded;
  const ChatsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.targetId = const Value.absent(),
    this.showName = const Value.absent(),
    this.headImage = const Value.absent(),
    this.companyName = const Value.absent(),
    this.lastContent = const Value.absent(),
    this.lastSendTime = const Value.absent(),
    this.sendNickName = const Value.absent(),
    this.lastMsgType = const Value.absent(),
    this.unreadCount = const Value.absent(),
    this.atMe = const Value.absent(),
    this.atAll = const Value.absent(),
    this.lastAtMessageId = const Value.absent(),
    this.isDnd = const Value.absent(),
    this.isTop = const Value.absent(),
    this.lastMsgId = const Value.absent(),
    this.messagesLoaded = const Value.absent(),
  });
  ChatsCompanion.insert({
    this.id = const Value.absent(),
    required String type,
    required int targetId,
    this.showName = const Value.absent(),
    this.headImage = const Value.absent(),
    this.companyName = const Value.absent(),
    this.lastContent = const Value.absent(),
    this.lastSendTime = const Value.absent(),
    this.sendNickName = const Value.absent(),
    this.lastMsgType = const Value.absent(),
    this.unreadCount = const Value.absent(),
    this.atMe = const Value.absent(),
    this.atAll = const Value.absent(),
    this.lastAtMessageId = const Value.absent(),
    this.isDnd = const Value.absent(),
    this.isTop = const Value.absent(),
    this.lastMsgId = const Value.absent(),
    this.messagesLoaded = const Value.absent(),
  }) : type = Value(type),
       targetId = Value(targetId);
  static Insertable<Chat> custom({
    Expression<int>? id,
    Expression<String>? type,
    Expression<int>? targetId,
    Expression<String>? showName,
    Expression<String>? headImage,
    Expression<String>? companyName,
    Expression<String>? lastContent,
    Expression<int>? lastSendTime,
    Expression<String>? sendNickName,
    Expression<int>? lastMsgType,
    Expression<int>? unreadCount,
    Expression<bool>? atMe,
    Expression<bool>? atAll,
    Expression<int>? lastAtMessageId,
    Expression<bool>? isDnd,
    Expression<bool>? isTop,
    Expression<int>? lastMsgId,
    Expression<bool>? messagesLoaded,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (targetId != null) 'target_id': targetId,
      if (showName != null) 'show_name': showName,
      if (headImage != null) 'head_image': headImage,
      if (companyName != null) 'company_name': companyName,
      if (lastContent != null) 'last_content': lastContent,
      if (lastSendTime != null) 'last_send_time': lastSendTime,
      if (sendNickName != null) 'send_nick_name': sendNickName,
      if (lastMsgType != null) 'last_msg_type': lastMsgType,
      if (unreadCount != null) 'unread_count': unreadCount,
      if (atMe != null) 'at_me': atMe,
      if (atAll != null) 'at_all': atAll,
      if (lastAtMessageId != null) 'last_at_message_id': lastAtMessageId,
      if (isDnd != null) 'is_dnd': isDnd,
      if (isTop != null) 'is_top': isTop,
      if (lastMsgId != null) 'last_msg_id': lastMsgId,
      if (messagesLoaded != null) 'messages_loaded': messagesLoaded,
    });
  }

  ChatsCompanion copyWith({
    Value<int>? id,
    Value<String>? type,
    Value<int>? targetId,
    Value<String?>? showName,
    Value<String?>? headImage,
    Value<String?>? companyName,
    Value<String?>? lastContent,
    Value<int?>? lastSendTime,
    Value<String?>? sendNickName,
    Value<int?>? lastMsgType,
    Value<int>? unreadCount,
    Value<bool>? atMe,
    Value<bool>? atAll,
    Value<int>? lastAtMessageId,
    Value<bool>? isDnd,
    Value<bool>? isTop,
    Value<int>? lastMsgId,
    Value<bool>? messagesLoaded,
  }) {
    return ChatsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      targetId: targetId ?? this.targetId,
      showName: showName ?? this.showName,
      headImage: headImage ?? this.headImage,
      companyName: companyName ?? this.companyName,
      lastContent: lastContent ?? this.lastContent,
      lastSendTime: lastSendTime ?? this.lastSendTime,
      sendNickName: sendNickName ?? this.sendNickName,
      lastMsgType: lastMsgType ?? this.lastMsgType,
      unreadCount: unreadCount ?? this.unreadCount,
      atMe: atMe ?? this.atMe,
      atAll: atAll ?? this.atAll,
      lastAtMessageId: lastAtMessageId ?? this.lastAtMessageId,
      isDnd: isDnd ?? this.isDnd,
      isTop: isTop ?? this.isTop,
      lastMsgId: lastMsgId ?? this.lastMsgId,
      messagesLoaded: messagesLoaded ?? this.messagesLoaded,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (targetId.present) {
      map['target_id'] = Variable<int>(targetId.value);
    }
    if (showName.present) {
      map['show_name'] = Variable<String>(showName.value);
    }
    if (headImage.present) {
      map['head_image'] = Variable<String>(headImage.value);
    }
    if (companyName.present) {
      map['company_name'] = Variable<String>(companyName.value);
    }
    if (lastContent.present) {
      map['last_content'] = Variable<String>(lastContent.value);
    }
    if (lastSendTime.present) {
      map['last_send_time'] = Variable<int>(lastSendTime.value);
    }
    if (sendNickName.present) {
      map['send_nick_name'] = Variable<String>(sendNickName.value);
    }
    if (lastMsgType.present) {
      map['last_msg_type'] = Variable<int>(lastMsgType.value);
    }
    if (unreadCount.present) {
      map['unread_count'] = Variable<int>(unreadCount.value);
    }
    if (atMe.present) {
      map['at_me'] = Variable<bool>(atMe.value);
    }
    if (atAll.present) {
      map['at_all'] = Variable<bool>(atAll.value);
    }
    if (lastAtMessageId.present) {
      map['last_at_message_id'] = Variable<int>(lastAtMessageId.value);
    }
    if (isDnd.present) {
      map['is_dnd'] = Variable<bool>(isDnd.value);
    }
    if (isTop.present) {
      map['is_top'] = Variable<bool>(isTop.value);
    }
    if (lastMsgId.present) {
      map['last_msg_id'] = Variable<int>(lastMsgId.value);
    }
    if (messagesLoaded.present) {
      map['messages_loaded'] = Variable<bool>(messagesLoaded.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChatsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('targetId: $targetId, ')
          ..write('showName: $showName, ')
          ..write('headImage: $headImage, ')
          ..write('companyName: $companyName, ')
          ..write('lastContent: $lastContent, ')
          ..write('lastSendTime: $lastSendTime, ')
          ..write('sendNickName: $sendNickName, ')
          ..write('lastMsgType: $lastMsgType, ')
          ..write('unreadCount: $unreadCount, ')
          ..write('atMe: $atMe, ')
          ..write('atAll: $atAll, ')
          ..write('lastAtMessageId: $lastAtMessageId, ')
          ..write('isDnd: $isDnd, ')
          ..write('isTop: $isTop, ')
          ..write('lastMsgId: $lastMsgId, ')
          ..write('messagesLoaded: $messagesLoaded')
          ..write(')'))
        .toString();
  }
}

class $MessagesTable extends Messages with TableInfo<$MessagesTable, Message> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _rowIdMeta = const VerificationMeta('rowId');
  @override
  late final GeneratedColumn<int> rowId = GeneratedColumn<int>(
    'row_id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tmpIdMeta = const VerificationMeta('tmpId');
  @override
  late final GeneratedColumn<String> tmpId = GeneratedColumn<String>(
    'tmp_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _chatTypeMeta = const VerificationMeta(
    'chatType',
  );
  @override
  late final GeneratedColumn<String> chatType = GeneratedColumn<String>(
    'chat_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _chatTargetIdMeta = const VerificationMeta(
    'chatTargetId',
  );
  @override
  late final GeneratedColumn<int> chatTargetId = GeneratedColumn<int>(
    'chat_target_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sendIdMeta = const VerificationMeta('sendId');
  @override
  late final GeneratedColumn<int> sendId = GeneratedColumn<int>(
    'send_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recvIdMeta = const VerificationMeta('recvId');
  @override
  late final GeneratedColumn<int> recvId = GeneratedColumn<int>(
    'recv_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<int> groupId = GeneratedColumn<int>(
    'group_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<int> type = GeneratedColumn<int>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<int> status = GeneratedColumn<int>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sendTimeMeta = const VerificationMeta(
    'sendTime',
  );
  @override
  late final GeneratedColumn<int> sendTime = GeneratedColumn<int>(
    'send_time',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sendNickNameMeta = const VerificationMeta(
    'sendNickName',
  );
  @override
  late final GeneratedColumn<String> sendNickName = GeneratedColumn<String>(
    'send_nick_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _atUserIdsMeta = const VerificationMeta(
    'atUserIds',
  );
  @override
  late final GeneratedColumn<String> atUserIds = GeneratedColumn<String>(
    'at_user_ids',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _quoteMessageMeta = const VerificationMeta(
    'quoteMessage',
  );
  @override
  late final GeneratedColumn<String> quoteMessage = GeneratedColumn<String>(
    'quote_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _receiptMeta = const VerificationMeta(
    'receipt',
  );
  @override
  late final GeneratedColumn<bool> receipt = GeneratedColumn<bool>(
    'receipt',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("receipt" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _receiptOkMeta = const VerificationMeta(
    'receiptOk',
  );
  @override
  late final GeneratedColumn<bool> receiptOk = GeneratedColumn<bool>(
    'receipt_ok',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("receipt_ok" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _readedCountMeta = const VerificationMeta(
    'readedCount',
  );
  @override
  late final GeneratedColumn<int> readedCount = GeneratedColumn<int>(
    'readed_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _selfSendMeta = const VerificationMeta(
    'selfSend',
  );
  @override
  late final GeneratedColumn<bool> selfSend = GeneratedColumn<bool>(
    'self_send',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("self_send" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _seqNoMeta = const VerificationMeta('seqNo');
  @override
  late final GeneratedColumn<int> seqNo = GeneratedColumn<int>(
    'seq_no',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    rowId,
    id,
    tmpId,
    chatType,
    chatTargetId,
    sendId,
    recvId,
    groupId,
    type,
    content,
    status,
    sendTime,
    sendNickName,
    atUserIds,
    quoteMessage,
    receipt,
    receiptOk,
    readedCount,
    selfSend,
    seqNo,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<Message> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('row_id')) {
      context.handle(
        _rowIdMeta,
        rowId.isAcceptableOrUnknown(data['row_id']!, _rowIdMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('tmp_id')) {
      context.handle(
        _tmpIdMeta,
        tmpId.isAcceptableOrUnknown(data['tmp_id']!, _tmpIdMeta),
      );
    }
    if (data.containsKey('chat_type')) {
      context.handle(
        _chatTypeMeta,
        chatType.isAcceptableOrUnknown(data['chat_type']!, _chatTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_chatTypeMeta);
    }
    if (data.containsKey('chat_target_id')) {
      context.handle(
        _chatTargetIdMeta,
        chatTargetId.isAcceptableOrUnknown(
          data['chat_target_id']!,
          _chatTargetIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_chatTargetIdMeta);
    }
    if (data.containsKey('send_id')) {
      context.handle(
        _sendIdMeta,
        sendId.isAcceptableOrUnknown(data['send_id']!, _sendIdMeta),
      );
    }
    if (data.containsKey('recv_id')) {
      context.handle(
        _recvIdMeta,
        recvId.isAcceptableOrUnknown(data['recv_id']!, _recvIdMeta),
      );
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('send_time')) {
      context.handle(
        _sendTimeMeta,
        sendTime.isAcceptableOrUnknown(data['send_time']!, _sendTimeMeta),
      );
    }
    if (data.containsKey('send_nick_name')) {
      context.handle(
        _sendNickNameMeta,
        sendNickName.isAcceptableOrUnknown(
          data['send_nick_name']!,
          _sendNickNameMeta,
        ),
      );
    }
    if (data.containsKey('at_user_ids')) {
      context.handle(
        _atUserIdsMeta,
        atUserIds.isAcceptableOrUnknown(data['at_user_ids']!, _atUserIdsMeta),
      );
    }
    if (data.containsKey('quote_message')) {
      context.handle(
        _quoteMessageMeta,
        quoteMessage.isAcceptableOrUnknown(
          data['quote_message']!,
          _quoteMessageMeta,
        ),
      );
    }
    if (data.containsKey('receipt')) {
      context.handle(
        _receiptMeta,
        receipt.isAcceptableOrUnknown(data['receipt']!, _receiptMeta),
      );
    }
    if (data.containsKey('receipt_ok')) {
      context.handle(
        _receiptOkMeta,
        receiptOk.isAcceptableOrUnknown(data['receipt_ok']!, _receiptOkMeta),
      );
    }
    if (data.containsKey('readed_count')) {
      context.handle(
        _readedCountMeta,
        readedCount.isAcceptableOrUnknown(
          data['readed_count']!,
          _readedCountMeta,
        ),
      );
    }
    if (data.containsKey('self_send')) {
      context.handle(
        _selfSendMeta,
        selfSend.isAcceptableOrUnknown(data['self_send']!, _selfSendMeta),
      );
    }
    if (data.containsKey('seq_no')) {
      context.handle(
        _seqNoMeta,
        seqNo.isAcceptableOrUnknown(data['seq_no']!, _seqNoMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {rowId};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {chatType, chatTargetId, id},
  ];
  @override
  Message map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Message(
      rowId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}row_id'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      ),
      tmpId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tmp_id'],
      ),
      chatType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}chat_type'],
      )!,
      chatTargetId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chat_target_id'],
      )!,
      sendId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}send_id'],
      ),
      recvId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recv_id'],
      ),
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}group_id'],
      ),
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}type'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}status'],
      )!,
      sendTime: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}send_time'],
      ),
      sendNickName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}send_nick_name'],
      ),
      atUserIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}at_user_ids'],
      ),
      quoteMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quote_message'],
      ),
      receipt: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}receipt'],
      )!,
      receiptOk: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}receipt_ok'],
      )!,
      readedCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}readed_count'],
      )!,
      selfSend: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}self_send'],
      )!,
      seqNo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq_no'],
      ),
    );
  }

  @override
  $MessagesTable createAlias(String alias) {
    return $MessagesTable(attachedDatabase, alias);
  }
}

class Message extends DataClass implements Insertable<Message> {
  final int rowId;

  /// 服务端消息 id（发送中为空）。
  final int? id;

  /// 本地临时 id。
  final String? tmpId;

  /// PRIVATE / GROUP / SYSTEM。
  final String chatType;

  /// 会话目标 id（好友id/群id/0）。
  final int chatTargetId;
  final int? sendId;
  final int? recvId;
  final int? groupId;

  /// 消息类型 0-211，见 MessageType。
  final int type;
  final String? content;

  /// 消息状态 -2..3，见 MessageStatus。
  final int status;
  final int? sendTime;

  /// 群聊发送者昵称。
  final String? sendNickName;

  /// @ 的用户 id 列表（JSON: `List<int>`）。
  final String? atUserIds;

  /// 引用消息（JSON: QuoteMessage）。
  final String? quoteMessage;
  final bool receipt;
  final bool receiptOk;
  final int readedCount;
  final bool selfSend;

  /// 系统消息序号。
  final int? seqNo;
  const Message({
    required this.rowId,
    this.id,
    this.tmpId,
    required this.chatType,
    required this.chatTargetId,
    this.sendId,
    this.recvId,
    this.groupId,
    required this.type,
    this.content,
    required this.status,
    this.sendTime,
    this.sendNickName,
    this.atUserIds,
    this.quoteMessage,
    required this.receipt,
    required this.receiptOk,
    required this.readedCount,
    required this.selfSend,
    this.seqNo,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['row_id'] = Variable<int>(rowId);
    if (!nullToAbsent || id != null) {
      map['id'] = Variable<int>(id);
    }
    if (!nullToAbsent || tmpId != null) {
      map['tmp_id'] = Variable<String>(tmpId);
    }
    map['chat_type'] = Variable<String>(chatType);
    map['chat_target_id'] = Variable<int>(chatTargetId);
    if (!nullToAbsent || sendId != null) {
      map['send_id'] = Variable<int>(sendId);
    }
    if (!nullToAbsent || recvId != null) {
      map['recv_id'] = Variable<int>(recvId);
    }
    if (!nullToAbsent || groupId != null) {
      map['group_id'] = Variable<int>(groupId);
    }
    map['type'] = Variable<int>(type);
    if (!nullToAbsent || content != null) {
      map['content'] = Variable<String>(content);
    }
    map['status'] = Variable<int>(status);
    if (!nullToAbsent || sendTime != null) {
      map['send_time'] = Variable<int>(sendTime);
    }
    if (!nullToAbsent || sendNickName != null) {
      map['send_nick_name'] = Variable<String>(sendNickName);
    }
    if (!nullToAbsent || atUserIds != null) {
      map['at_user_ids'] = Variable<String>(atUserIds);
    }
    if (!nullToAbsent || quoteMessage != null) {
      map['quote_message'] = Variable<String>(quoteMessage);
    }
    map['receipt'] = Variable<bool>(receipt);
    map['receipt_ok'] = Variable<bool>(receiptOk);
    map['readed_count'] = Variable<int>(readedCount);
    map['self_send'] = Variable<bool>(selfSend);
    if (!nullToAbsent || seqNo != null) {
      map['seq_no'] = Variable<int>(seqNo);
    }
    return map;
  }

  MessagesCompanion toCompanion(bool nullToAbsent) {
    return MessagesCompanion(
      rowId: Value(rowId),
      id: id == null && nullToAbsent ? const Value.absent() : Value(id),
      tmpId: tmpId == null && nullToAbsent
          ? const Value.absent()
          : Value(tmpId),
      chatType: Value(chatType),
      chatTargetId: Value(chatTargetId),
      sendId: sendId == null && nullToAbsent
          ? const Value.absent()
          : Value(sendId),
      recvId: recvId == null && nullToAbsent
          ? const Value.absent()
          : Value(recvId),
      groupId: groupId == null && nullToAbsent
          ? const Value.absent()
          : Value(groupId),
      type: Value(type),
      content: content == null && nullToAbsent
          ? const Value.absent()
          : Value(content),
      status: Value(status),
      sendTime: sendTime == null && nullToAbsent
          ? const Value.absent()
          : Value(sendTime),
      sendNickName: sendNickName == null && nullToAbsent
          ? const Value.absent()
          : Value(sendNickName),
      atUserIds: atUserIds == null && nullToAbsent
          ? const Value.absent()
          : Value(atUserIds),
      quoteMessage: quoteMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(quoteMessage),
      receipt: Value(receipt),
      receiptOk: Value(receiptOk),
      readedCount: Value(readedCount),
      selfSend: Value(selfSend),
      seqNo: seqNo == null && nullToAbsent
          ? const Value.absent()
          : Value(seqNo),
    );
  }

  factory Message.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Message(
      rowId: serializer.fromJson<int>(json['rowId']),
      id: serializer.fromJson<int?>(json['id']),
      tmpId: serializer.fromJson<String?>(json['tmpId']),
      chatType: serializer.fromJson<String>(json['chatType']),
      chatTargetId: serializer.fromJson<int>(json['chatTargetId']),
      sendId: serializer.fromJson<int?>(json['sendId']),
      recvId: serializer.fromJson<int?>(json['recvId']),
      groupId: serializer.fromJson<int?>(json['groupId']),
      type: serializer.fromJson<int>(json['type']),
      content: serializer.fromJson<String?>(json['content']),
      status: serializer.fromJson<int>(json['status']),
      sendTime: serializer.fromJson<int?>(json['sendTime']),
      sendNickName: serializer.fromJson<String?>(json['sendNickName']),
      atUserIds: serializer.fromJson<String?>(json['atUserIds']),
      quoteMessage: serializer.fromJson<String?>(json['quoteMessage']),
      receipt: serializer.fromJson<bool>(json['receipt']),
      receiptOk: serializer.fromJson<bool>(json['receiptOk']),
      readedCount: serializer.fromJson<int>(json['readedCount']),
      selfSend: serializer.fromJson<bool>(json['selfSend']),
      seqNo: serializer.fromJson<int?>(json['seqNo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'rowId': serializer.toJson<int>(rowId),
      'id': serializer.toJson<int?>(id),
      'tmpId': serializer.toJson<String?>(tmpId),
      'chatType': serializer.toJson<String>(chatType),
      'chatTargetId': serializer.toJson<int>(chatTargetId),
      'sendId': serializer.toJson<int?>(sendId),
      'recvId': serializer.toJson<int?>(recvId),
      'groupId': serializer.toJson<int?>(groupId),
      'type': serializer.toJson<int>(type),
      'content': serializer.toJson<String?>(content),
      'status': serializer.toJson<int>(status),
      'sendTime': serializer.toJson<int?>(sendTime),
      'sendNickName': serializer.toJson<String?>(sendNickName),
      'atUserIds': serializer.toJson<String?>(atUserIds),
      'quoteMessage': serializer.toJson<String?>(quoteMessage),
      'receipt': serializer.toJson<bool>(receipt),
      'receiptOk': serializer.toJson<bool>(receiptOk),
      'readedCount': serializer.toJson<int>(readedCount),
      'selfSend': serializer.toJson<bool>(selfSend),
      'seqNo': serializer.toJson<int?>(seqNo),
    };
  }

  Message copyWith({
    int? rowId,
    Value<int?> id = const Value.absent(),
    Value<String?> tmpId = const Value.absent(),
    String? chatType,
    int? chatTargetId,
    Value<int?> sendId = const Value.absent(),
    Value<int?> recvId = const Value.absent(),
    Value<int?> groupId = const Value.absent(),
    int? type,
    Value<String?> content = const Value.absent(),
    int? status,
    Value<int?> sendTime = const Value.absent(),
    Value<String?> sendNickName = const Value.absent(),
    Value<String?> atUserIds = const Value.absent(),
    Value<String?> quoteMessage = const Value.absent(),
    bool? receipt,
    bool? receiptOk,
    int? readedCount,
    bool? selfSend,
    Value<int?> seqNo = const Value.absent(),
  }) => Message(
    rowId: rowId ?? this.rowId,
    id: id.present ? id.value : this.id,
    tmpId: tmpId.present ? tmpId.value : this.tmpId,
    chatType: chatType ?? this.chatType,
    chatTargetId: chatTargetId ?? this.chatTargetId,
    sendId: sendId.present ? sendId.value : this.sendId,
    recvId: recvId.present ? recvId.value : this.recvId,
    groupId: groupId.present ? groupId.value : this.groupId,
    type: type ?? this.type,
    content: content.present ? content.value : this.content,
    status: status ?? this.status,
    sendTime: sendTime.present ? sendTime.value : this.sendTime,
    sendNickName: sendNickName.present ? sendNickName.value : this.sendNickName,
    atUserIds: atUserIds.present ? atUserIds.value : this.atUserIds,
    quoteMessage: quoteMessage.present ? quoteMessage.value : this.quoteMessage,
    receipt: receipt ?? this.receipt,
    receiptOk: receiptOk ?? this.receiptOk,
    readedCount: readedCount ?? this.readedCount,
    selfSend: selfSend ?? this.selfSend,
    seqNo: seqNo.present ? seqNo.value : this.seqNo,
  );
  Message copyWithCompanion(MessagesCompanion data) {
    return Message(
      rowId: data.rowId.present ? data.rowId.value : this.rowId,
      id: data.id.present ? data.id.value : this.id,
      tmpId: data.tmpId.present ? data.tmpId.value : this.tmpId,
      chatType: data.chatType.present ? data.chatType.value : this.chatType,
      chatTargetId: data.chatTargetId.present
          ? data.chatTargetId.value
          : this.chatTargetId,
      sendId: data.sendId.present ? data.sendId.value : this.sendId,
      recvId: data.recvId.present ? data.recvId.value : this.recvId,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      type: data.type.present ? data.type.value : this.type,
      content: data.content.present ? data.content.value : this.content,
      status: data.status.present ? data.status.value : this.status,
      sendTime: data.sendTime.present ? data.sendTime.value : this.sendTime,
      sendNickName: data.sendNickName.present
          ? data.sendNickName.value
          : this.sendNickName,
      atUserIds: data.atUserIds.present ? data.atUserIds.value : this.atUserIds,
      quoteMessage: data.quoteMessage.present
          ? data.quoteMessage.value
          : this.quoteMessage,
      receipt: data.receipt.present ? data.receipt.value : this.receipt,
      receiptOk: data.receiptOk.present ? data.receiptOk.value : this.receiptOk,
      readedCount: data.readedCount.present
          ? data.readedCount.value
          : this.readedCount,
      selfSend: data.selfSend.present ? data.selfSend.value : this.selfSend,
      seqNo: data.seqNo.present ? data.seqNo.value : this.seqNo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Message(')
          ..write('rowId: $rowId, ')
          ..write('id: $id, ')
          ..write('tmpId: $tmpId, ')
          ..write('chatType: $chatType, ')
          ..write('chatTargetId: $chatTargetId, ')
          ..write('sendId: $sendId, ')
          ..write('recvId: $recvId, ')
          ..write('groupId: $groupId, ')
          ..write('type: $type, ')
          ..write('content: $content, ')
          ..write('status: $status, ')
          ..write('sendTime: $sendTime, ')
          ..write('sendNickName: $sendNickName, ')
          ..write('atUserIds: $atUserIds, ')
          ..write('quoteMessage: $quoteMessage, ')
          ..write('receipt: $receipt, ')
          ..write('receiptOk: $receiptOk, ')
          ..write('readedCount: $readedCount, ')
          ..write('selfSend: $selfSend, ')
          ..write('seqNo: $seqNo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    rowId,
    id,
    tmpId,
    chatType,
    chatTargetId,
    sendId,
    recvId,
    groupId,
    type,
    content,
    status,
    sendTime,
    sendNickName,
    atUserIds,
    quoteMessage,
    receipt,
    receiptOk,
    readedCount,
    selfSend,
    seqNo,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Message &&
          other.rowId == this.rowId &&
          other.id == this.id &&
          other.tmpId == this.tmpId &&
          other.chatType == this.chatType &&
          other.chatTargetId == this.chatTargetId &&
          other.sendId == this.sendId &&
          other.recvId == this.recvId &&
          other.groupId == this.groupId &&
          other.type == this.type &&
          other.content == this.content &&
          other.status == this.status &&
          other.sendTime == this.sendTime &&
          other.sendNickName == this.sendNickName &&
          other.atUserIds == this.atUserIds &&
          other.quoteMessage == this.quoteMessage &&
          other.receipt == this.receipt &&
          other.receiptOk == this.receiptOk &&
          other.readedCount == this.readedCount &&
          other.selfSend == this.selfSend &&
          other.seqNo == this.seqNo);
}

class MessagesCompanion extends UpdateCompanion<Message> {
  final Value<int> rowId;
  final Value<int?> id;
  final Value<String?> tmpId;
  final Value<String> chatType;
  final Value<int> chatTargetId;
  final Value<int?> sendId;
  final Value<int?> recvId;
  final Value<int?> groupId;
  final Value<int> type;
  final Value<String?> content;
  final Value<int> status;
  final Value<int?> sendTime;
  final Value<String?> sendNickName;
  final Value<String?> atUserIds;
  final Value<String?> quoteMessage;
  final Value<bool> receipt;
  final Value<bool> receiptOk;
  final Value<int> readedCount;
  final Value<bool> selfSend;
  final Value<int?> seqNo;
  const MessagesCompanion({
    this.rowId = const Value.absent(),
    this.id = const Value.absent(),
    this.tmpId = const Value.absent(),
    this.chatType = const Value.absent(),
    this.chatTargetId = const Value.absent(),
    this.sendId = const Value.absent(),
    this.recvId = const Value.absent(),
    this.groupId = const Value.absent(),
    this.type = const Value.absent(),
    this.content = const Value.absent(),
    this.status = const Value.absent(),
    this.sendTime = const Value.absent(),
    this.sendNickName = const Value.absent(),
    this.atUserIds = const Value.absent(),
    this.quoteMessage = const Value.absent(),
    this.receipt = const Value.absent(),
    this.receiptOk = const Value.absent(),
    this.readedCount = const Value.absent(),
    this.selfSend = const Value.absent(),
    this.seqNo = const Value.absent(),
  });
  MessagesCompanion.insert({
    this.rowId = const Value.absent(),
    this.id = const Value.absent(),
    this.tmpId = const Value.absent(),
    required String chatType,
    required int chatTargetId,
    this.sendId = const Value.absent(),
    this.recvId = const Value.absent(),
    this.groupId = const Value.absent(),
    required int type,
    this.content = const Value.absent(),
    required int status,
    this.sendTime = const Value.absent(),
    this.sendNickName = const Value.absent(),
    this.atUserIds = const Value.absent(),
    this.quoteMessage = const Value.absent(),
    this.receipt = const Value.absent(),
    this.receiptOk = const Value.absent(),
    this.readedCount = const Value.absent(),
    this.selfSend = const Value.absent(),
    this.seqNo = const Value.absent(),
  }) : chatType = Value(chatType),
       chatTargetId = Value(chatTargetId),
       type = Value(type),
       status = Value(status);
  static Insertable<Message> custom({
    Expression<int>? rowId,
    Expression<int>? id,
    Expression<String>? tmpId,
    Expression<String>? chatType,
    Expression<int>? chatTargetId,
    Expression<int>? sendId,
    Expression<int>? recvId,
    Expression<int>? groupId,
    Expression<int>? type,
    Expression<String>? content,
    Expression<int>? status,
    Expression<int>? sendTime,
    Expression<String>? sendNickName,
    Expression<String>? atUserIds,
    Expression<String>? quoteMessage,
    Expression<bool>? receipt,
    Expression<bool>? receiptOk,
    Expression<int>? readedCount,
    Expression<bool>? selfSend,
    Expression<int>? seqNo,
  }) {
    return RawValuesInsertable({
      if (rowId != null) 'row_id': rowId,
      if (id != null) 'id': id,
      if (tmpId != null) 'tmp_id': tmpId,
      if (chatType != null) 'chat_type': chatType,
      if (chatTargetId != null) 'chat_target_id': chatTargetId,
      if (sendId != null) 'send_id': sendId,
      if (recvId != null) 'recv_id': recvId,
      if (groupId != null) 'group_id': groupId,
      if (type != null) 'type': type,
      if (content != null) 'content': content,
      if (status != null) 'status': status,
      if (sendTime != null) 'send_time': sendTime,
      if (sendNickName != null) 'send_nick_name': sendNickName,
      if (atUserIds != null) 'at_user_ids': atUserIds,
      if (quoteMessage != null) 'quote_message': quoteMessage,
      if (receipt != null) 'receipt': receipt,
      if (receiptOk != null) 'receipt_ok': receiptOk,
      if (readedCount != null) 'readed_count': readedCount,
      if (selfSend != null) 'self_send': selfSend,
      if (seqNo != null) 'seq_no': seqNo,
    });
  }

  MessagesCompanion copyWith({
    Value<int>? rowId,
    Value<int?>? id,
    Value<String?>? tmpId,
    Value<String>? chatType,
    Value<int>? chatTargetId,
    Value<int?>? sendId,
    Value<int?>? recvId,
    Value<int?>? groupId,
    Value<int>? type,
    Value<String?>? content,
    Value<int>? status,
    Value<int?>? sendTime,
    Value<String?>? sendNickName,
    Value<String?>? atUserIds,
    Value<String?>? quoteMessage,
    Value<bool>? receipt,
    Value<bool>? receiptOk,
    Value<int>? readedCount,
    Value<bool>? selfSend,
    Value<int?>? seqNo,
  }) {
    return MessagesCompanion(
      rowId: rowId ?? this.rowId,
      id: id ?? this.id,
      tmpId: tmpId ?? this.tmpId,
      chatType: chatType ?? this.chatType,
      chatTargetId: chatTargetId ?? this.chatTargetId,
      sendId: sendId ?? this.sendId,
      recvId: recvId ?? this.recvId,
      groupId: groupId ?? this.groupId,
      type: type ?? this.type,
      content: content ?? this.content,
      status: status ?? this.status,
      sendTime: sendTime ?? this.sendTime,
      sendNickName: sendNickName ?? this.sendNickName,
      atUserIds: atUserIds ?? this.atUserIds,
      quoteMessage: quoteMessage ?? this.quoteMessage,
      receipt: receipt ?? this.receipt,
      receiptOk: receiptOk ?? this.receiptOk,
      readedCount: readedCount ?? this.readedCount,
      selfSend: selfSend ?? this.selfSend,
      seqNo: seqNo ?? this.seqNo,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (rowId.present) {
      map['row_id'] = Variable<int>(rowId.value);
    }
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (tmpId.present) {
      map['tmp_id'] = Variable<String>(tmpId.value);
    }
    if (chatType.present) {
      map['chat_type'] = Variable<String>(chatType.value);
    }
    if (chatTargetId.present) {
      map['chat_target_id'] = Variable<int>(chatTargetId.value);
    }
    if (sendId.present) {
      map['send_id'] = Variable<int>(sendId.value);
    }
    if (recvId.present) {
      map['recv_id'] = Variable<int>(recvId.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<int>(groupId.value);
    }
    if (type.present) {
      map['type'] = Variable<int>(type.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(status.value);
    }
    if (sendTime.present) {
      map['send_time'] = Variable<int>(sendTime.value);
    }
    if (sendNickName.present) {
      map['send_nick_name'] = Variable<String>(sendNickName.value);
    }
    if (atUserIds.present) {
      map['at_user_ids'] = Variable<String>(atUserIds.value);
    }
    if (quoteMessage.present) {
      map['quote_message'] = Variable<String>(quoteMessage.value);
    }
    if (receipt.present) {
      map['receipt'] = Variable<bool>(receipt.value);
    }
    if (receiptOk.present) {
      map['receipt_ok'] = Variable<bool>(receiptOk.value);
    }
    if (readedCount.present) {
      map['readed_count'] = Variable<int>(readedCount.value);
    }
    if (selfSend.present) {
      map['self_send'] = Variable<bool>(selfSend.value);
    }
    if (seqNo.present) {
      map['seq_no'] = Variable<int>(seqNo.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessagesCompanion(')
          ..write('rowId: $rowId, ')
          ..write('id: $id, ')
          ..write('tmpId: $tmpId, ')
          ..write('chatType: $chatType, ')
          ..write('chatTargetId: $chatTargetId, ')
          ..write('sendId: $sendId, ')
          ..write('recvId: $recvId, ')
          ..write('groupId: $groupId, ')
          ..write('type: $type, ')
          ..write('content: $content, ')
          ..write('status: $status, ')
          ..write('sendTime: $sendTime, ')
          ..write('sendNickName: $sendNickName, ')
          ..write('atUserIds: $atUserIds, ')
          ..write('quoteMessage: $quoteMessage, ')
          ..write('receipt: $receipt, ')
          ..write('receiptOk: $receiptOk, ')
          ..write('readedCount: $readedCount, ')
          ..write('selfSend: $selfSend, ')
          ..write('seqNo: $seqNo')
          ..write(')'))
        .toString();
  }
}

class $FriendsTable extends Friends with TableInfo<$FriendsTable, Friend> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FriendsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nickNameMeta = const VerificationMeta(
    'nickName',
  );
  @override
  late final GeneratedColumn<String> nickName = GeneratedColumn<String>(
    'nick_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _showNickNameMeta = const VerificationMeta(
    'showNickName',
  );
  @override
  late final GeneratedColumn<String> showNickName = GeneratedColumn<String>(
    'show_nick_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remarkNickNameMeta = const VerificationMeta(
    'remarkNickName',
  );
  @override
  late final GeneratedColumn<String> remarkNickName = GeneratedColumn<String>(
    'remark_nick_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _headImageMeta = const VerificationMeta(
    'headImage',
  );
  @override
  late final GeneratedColumn<String> headImage = GeneratedColumn<String>(
    'head_image',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _companyNameMeta = const VerificationMeta(
    'companyName',
  );
  @override
  late final GeneratedColumn<String> companyName = GeneratedColumn<String>(
    'company_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDndMeta = const VerificationMeta('isDnd');
  @override
  late final GeneratedColumn<bool> isDnd = GeneratedColumn<bool>(
    'is_dnd',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_dnd" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isTopMeta = const VerificationMeta('isTop');
  @override
  late final GeneratedColumn<bool> isTop = GeneratedColumn<bool>(
    'is_top',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_top" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _onlineMeta = const VerificationMeta('online');
  @override
  late final GeneratedColumn<bool> online = GeneratedColumn<bool>(
    'online',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("online" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _onlineWebMeta = const VerificationMeta(
    'onlineWeb',
  );
  @override
  late final GeneratedColumn<bool> onlineWeb = GeneratedColumn<bool>(
    'online_web',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("online_web" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _onlineAppMeta = const VerificationMeta(
    'onlineApp',
  );
  @override
  late final GeneratedColumn<bool> onlineApp = GeneratedColumn<bool>(
    'online_app',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("online_app" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    nickName,
    showNickName,
    remarkNickName,
    headImage,
    companyName,
    isDnd,
    isTop,
    deleted,
    online,
    onlineWeb,
    onlineApp,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'friends';
  @override
  VerificationContext validateIntegrity(
    Insertable<Friend> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('nick_name')) {
      context.handle(
        _nickNameMeta,
        nickName.isAcceptableOrUnknown(data['nick_name']!, _nickNameMeta),
      );
    }
    if (data.containsKey('show_nick_name')) {
      context.handle(
        _showNickNameMeta,
        showNickName.isAcceptableOrUnknown(
          data['show_nick_name']!,
          _showNickNameMeta,
        ),
      );
    }
    if (data.containsKey('remark_nick_name')) {
      context.handle(
        _remarkNickNameMeta,
        remarkNickName.isAcceptableOrUnknown(
          data['remark_nick_name']!,
          _remarkNickNameMeta,
        ),
      );
    }
    if (data.containsKey('head_image')) {
      context.handle(
        _headImageMeta,
        headImage.isAcceptableOrUnknown(data['head_image']!, _headImageMeta),
      );
    }
    if (data.containsKey('company_name')) {
      context.handle(
        _companyNameMeta,
        companyName.isAcceptableOrUnknown(
          data['company_name']!,
          _companyNameMeta,
        ),
      );
    }
    if (data.containsKey('is_dnd')) {
      context.handle(
        _isDndMeta,
        isDnd.isAcceptableOrUnknown(data['is_dnd']!, _isDndMeta),
      );
    }
    if (data.containsKey('is_top')) {
      context.handle(
        _isTopMeta,
        isTop.isAcceptableOrUnknown(data['is_top']!, _isTopMeta),
      );
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('online')) {
      context.handle(
        _onlineMeta,
        online.isAcceptableOrUnknown(data['online']!, _onlineMeta),
      );
    }
    if (data.containsKey('online_web')) {
      context.handle(
        _onlineWebMeta,
        onlineWeb.isAcceptableOrUnknown(data['online_web']!, _onlineWebMeta),
      );
    }
    if (data.containsKey('online_app')) {
      context.handle(
        _onlineAppMeta,
        onlineApp.isAcceptableOrUnknown(data['online_app']!, _onlineAppMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Friend map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Friend(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      nickName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nick_name'],
      ),
      showNickName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}show_nick_name'],
      ),
      remarkNickName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remark_nick_name'],
      ),
      headImage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}head_image'],
      ),
      companyName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company_name'],
      ),
      isDnd: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_dnd'],
      )!,
      isTop: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_top'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      online: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}online'],
      )!,
      onlineWeb: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}online_web'],
      )!,
      onlineApp: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}online_app'],
      )!,
    );
  }

  @override
  $FriendsTable createAlias(String alias) {
    return $FriendsTable(attachedDatabase, alias);
  }
}

class Friend extends DataClass implements Insertable<Friend> {
  final int id;
  final String? nickName;
  final String? showNickName;
  final String? remarkNickName;
  final String? headImage;
  final String? companyName;
  final bool isDnd;
  final bool isTop;
  final bool deleted;
  final bool online;
  final bool onlineWeb;
  final bool onlineApp;
  const Friend({
    required this.id,
    this.nickName,
    this.showNickName,
    this.remarkNickName,
    this.headImage,
    this.companyName,
    required this.isDnd,
    required this.isTop,
    required this.deleted,
    required this.online,
    required this.onlineWeb,
    required this.onlineApp,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || nickName != null) {
      map['nick_name'] = Variable<String>(nickName);
    }
    if (!nullToAbsent || showNickName != null) {
      map['show_nick_name'] = Variable<String>(showNickName);
    }
    if (!nullToAbsent || remarkNickName != null) {
      map['remark_nick_name'] = Variable<String>(remarkNickName);
    }
    if (!nullToAbsent || headImage != null) {
      map['head_image'] = Variable<String>(headImage);
    }
    if (!nullToAbsent || companyName != null) {
      map['company_name'] = Variable<String>(companyName);
    }
    map['is_dnd'] = Variable<bool>(isDnd);
    map['is_top'] = Variable<bool>(isTop);
    map['deleted'] = Variable<bool>(deleted);
    map['online'] = Variable<bool>(online);
    map['online_web'] = Variable<bool>(onlineWeb);
    map['online_app'] = Variable<bool>(onlineApp);
    return map;
  }

  FriendsCompanion toCompanion(bool nullToAbsent) {
    return FriendsCompanion(
      id: Value(id),
      nickName: nickName == null && nullToAbsent
          ? const Value.absent()
          : Value(nickName),
      showNickName: showNickName == null && nullToAbsent
          ? const Value.absent()
          : Value(showNickName),
      remarkNickName: remarkNickName == null && nullToAbsent
          ? const Value.absent()
          : Value(remarkNickName),
      headImage: headImage == null && nullToAbsent
          ? const Value.absent()
          : Value(headImage),
      companyName: companyName == null && nullToAbsent
          ? const Value.absent()
          : Value(companyName),
      isDnd: Value(isDnd),
      isTop: Value(isTop),
      deleted: Value(deleted),
      online: Value(online),
      onlineWeb: Value(onlineWeb),
      onlineApp: Value(onlineApp),
    );
  }

  factory Friend.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Friend(
      id: serializer.fromJson<int>(json['id']),
      nickName: serializer.fromJson<String?>(json['nickName']),
      showNickName: serializer.fromJson<String?>(json['showNickName']),
      remarkNickName: serializer.fromJson<String?>(json['remarkNickName']),
      headImage: serializer.fromJson<String?>(json['headImage']),
      companyName: serializer.fromJson<String?>(json['companyName']),
      isDnd: serializer.fromJson<bool>(json['isDnd']),
      isTop: serializer.fromJson<bool>(json['isTop']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      online: serializer.fromJson<bool>(json['online']),
      onlineWeb: serializer.fromJson<bool>(json['onlineWeb']),
      onlineApp: serializer.fromJson<bool>(json['onlineApp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'nickName': serializer.toJson<String?>(nickName),
      'showNickName': serializer.toJson<String?>(showNickName),
      'remarkNickName': serializer.toJson<String?>(remarkNickName),
      'headImage': serializer.toJson<String?>(headImage),
      'companyName': serializer.toJson<String?>(companyName),
      'isDnd': serializer.toJson<bool>(isDnd),
      'isTop': serializer.toJson<bool>(isTop),
      'deleted': serializer.toJson<bool>(deleted),
      'online': serializer.toJson<bool>(online),
      'onlineWeb': serializer.toJson<bool>(onlineWeb),
      'onlineApp': serializer.toJson<bool>(onlineApp),
    };
  }

  Friend copyWith({
    int? id,
    Value<String?> nickName = const Value.absent(),
    Value<String?> showNickName = const Value.absent(),
    Value<String?> remarkNickName = const Value.absent(),
    Value<String?> headImage = const Value.absent(),
    Value<String?> companyName = const Value.absent(),
    bool? isDnd,
    bool? isTop,
    bool? deleted,
    bool? online,
    bool? onlineWeb,
    bool? onlineApp,
  }) => Friend(
    id: id ?? this.id,
    nickName: nickName.present ? nickName.value : this.nickName,
    showNickName: showNickName.present ? showNickName.value : this.showNickName,
    remarkNickName: remarkNickName.present
        ? remarkNickName.value
        : this.remarkNickName,
    headImage: headImage.present ? headImage.value : this.headImage,
    companyName: companyName.present ? companyName.value : this.companyName,
    isDnd: isDnd ?? this.isDnd,
    isTop: isTop ?? this.isTop,
    deleted: deleted ?? this.deleted,
    online: online ?? this.online,
    onlineWeb: onlineWeb ?? this.onlineWeb,
    onlineApp: onlineApp ?? this.onlineApp,
  );
  Friend copyWithCompanion(FriendsCompanion data) {
    return Friend(
      id: data.id.present ? data.id.value : this.id,
      nickName: data.nickName.present ? data.nickName.value : this.nickName,
      showNickName: data.showNickName.present
          ? data.showNickName.value
          : this.showNickName,
      remarkNickName: data.remarkNickName.present
          ? data.remarkNickName.value
          : this.remarkNickName,
      headImage: data.headImage.present ? data.headImage.value : this.headImage,
      companyName: data.companyName.present
          ? data.companyName.value
          : this.companyName,
      isDnd: data.isDnd.present ? data.isDnd.value : this.isDnd,
      isTop: data.isTop.present ? data.isTop.value : this.isTop,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      online: data.online.present ? data.online.value : this.online,
      onlineWeb: data.onlineWeb.present ? data.onlineWeb.value : this.onlineWeb,
      onlineApp: data.onlineApp.present ? data.onlineApp.value : this.onlineApp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Friend(')
          ..write('id: $id, ')
          ..write('nickName: $nickName, ')
          ..write('showNickName: $showNickName, ')
          ..write('remarkNickName: $remarkNickName, ')
          ..write('headImage: $headImage, ')
          ..write('companyName: $companyName, ')
          ..write('isDnd: $isDnd, ')
          ..write('isTop: $isTop, ')
          ..write('deleted: $deleted, ')
          ..write('online: $online, ')
          ..write('onlineWeb: $onlineWeb, ')
          ..write('onlineApp: $onlineApp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    nickName,
    showNickName,
    remarkNickName,
    headImage,
    companyName,
    isDnd,
    isTop,
    deleted,
    online,
    onlineWeb,
    onlineApp,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Friend &&
          other.id == this.id &&
          other.nickName == this.nickName &&
          other.showNickName == this.showNickName &&
          other.remarkNickName == this.remarkNickName &&
          other.headImage == this.headImage &&
          other.companyName == this.companyName &&
          other.isDnd == this.isDnd &&
          other.isTop == this.isTop &&
          other.deleted == this.deleted &&
          other.online == this.online &&
          other.onlineWeb == this.onlineWeb &&
          other.onlineApp == this.onlineApp);
}

class FriendsCompanion extends UpdateCompanion<Friend> {
  final Value<int> id;
  final Value<String?> nickName;
  final Value<String?> showNickName;
  final Value<String?> remarkNickName;
  final Value<String?> headImage;
  final Value<String?> companyName;
  final Value<bool> isDnd;
  final Value<bool> isTop;
  final Value<bool> deleted;
  final Value<bool> online;
  final Value<bool> onlineWeb;
  final Value<bool> onlineApp;
  const FriendsCompanion({
    this.id = const Value.absent(),
    this.nickName = const Value.absent(),
    this.showNickName = const Value.absent(),
    this.remarkNickName = const Value.absent(),
    this.headImage = const Value.absent(),
    this.companyName = const Value.absent(),
    this.isDnd = const Value.absent(),
    this.isTop = const Value.absent(),
    this.deleted = const Value.absent(),
    this.online = const Value.absent(),
    this.onlineWeb = const Value.absent(),
    this.onlineApp = const Value.absent(),
  });
  FriendsCompanion.insert({
    this.id = const Value.absent(),
    this.nickName = const Value.absent(),
    this.showNickName = const Value.absent(),
    this.remarkNickName = const Value.absent(),
    this.headImage = const Value.absent(),
    this.companyName = const Value.absent(),
    this.isDnd = const Value.absent(),
    this.isTop = const Value.absent(),
    this.deleted = const Value.absent(),
    this.online = const Value.absent(),
    this.onlineWeb = const Value.absent(),
    this.onlineApp = const Value.absent(),
  });
  static Insertable<Friend> custom({
    Expression<int>? id,
    Expression<String>? nickName,
    Expression<String>? showNickName,
    Expression<String>? remarkNickName,
    Expression<String>? headImage,
    Expression<String>? companyName,
    Expression<bool>? isDnd,
    Expression<bool>? isTop,
    Expression<bool>? deleted,
    Expression<bool>? online,
    Expression<bool>? onlineWeb,
    Expression<bool>? onlineApp,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nickName != null) 'nick_name': nickName,
      if (showNickName != null) 'show_nick_name': showNickName,
      if (remarkNickName != null) 'remark_nick_name': remarkNickName,
      if (headImage != null) 'head_image': headImage,
      if (companyName != null) 'company_name': companyName,
      if (isDnd != null) 'is_dnd': isDnd,
      if (isTop != null) 'is_top': isTop,
      if (deleted != null) 'deleted': deleted,
      if (online != null) 'online': online,
      if (onlineWeb != null) 'online_web': onlineWeb,
      if (onlineApp != null) 'online_app': onlineApp,
    });
  }

  FriendsCompanion copyWith({
    Value<int>? id,
    Value<String?>? nickName,
    Value<String?>? showNickName,
    Value<String?>? remarkNickName,
    Value<String?>? headImage,
    Value<String?>? companyName,
    Value<bool>? isDnd,
    Value<bool>? isTop,
    Value<bool>? deleted,
    Value<bool>? online,
    Value<bool>? onlineWeb,
    Value<bool>? onlineApp,
  }) {
    return FriendsCompanion(
      id: id ?? this.id,
      nickName: nickName ?? this.nickName,
      showNickName: showNickName ?? this.showNickName,
      remarkNickName: remarkNickName ?? this.remarkNickName,
      headImage: headImage ?? this.headImage,
      companyName: companyName ?? this.companyName,
      isDnd: isDnd ?? this.isDnd,
      isTop: isTop ?? this.isTop,
      deleted: deleted ?? this.deleted,
      online: online ?? this.online,
      onlineWeb: onlineWeb ?? this.onlineWeb,
      onlineApp: onlineApp ?? this.onlineApp,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (nickName.present) {
      map['nick_name'] = Variable<String>(nickName.value);
    }
    if (showNickName.present) {
      map['show_nick_name'] = Variable<String>(showNickName.value);
    }
    if (remarkNickName.present) {
      map['remark_nick_name'] = Variable<String>(remarkNickName.value);
    }
    if (headImage.present) {
      map['head_image'] = Variable<String>(headImage.value);
    }
    if (companyName.present) {
      map['company_name'] = Variable<String>(companyName.value);
    }
    if (isDnd.present) {
      map['is_dnd'] = Variable<bool>(isDnd.value);
    }
    if (isTop.present) {
      map['is_top'] = Variable<bool>(isTop.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (online.present) {
      map['online'] = Variable<bool>(online.value);
    }
    if (onlineWeb.present) {
      map['online_web'] = Variable<bool>(onlineWeb.value);
    }
    if (onlineApp.present) {
      map['online_app'] = Variable<bool>(onlineApp.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FriendsCompanion(')
          ..write('id: $id, ')
          ..write('nickName: $nickName, ')
          ..write('showNickName: $showNickName, ')
          ..write('remarkNickName: $remarkNickName, ')
          ..write('headImage: $headImage, ')
          ..write('companyName: $companyName, ')
          ..write('isDnd: $isDnd, ')
          ..write('isTop: $isTop, ')
          ..write('deleted: $deleted, ')
          ..write('online: $online, ')
          ..write('onlineWeb: $onlineWeb, ')
          ..write('onlineApp: $onlineApp')
          ..write(')'))
        .toString();
  }
}

class $GroupsTable extends Groups with TableInfo<$GroupsTable, Group> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GroupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<int> ownerId = GeneratedColumn<int>(
    'owner_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _headImageMeta = const VerificationMeta(
    'headImage',
  );
  @override
  late final GeneratedColumn<String> headImage = GeneratedColumn<String>(
    'head_image',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _headImageThumbMeta = const VerificationMeta(
    'headImageThumb',
  );
  @override
  late final GeneratedColumn<String> headImageThumb = GeneratedColumn<String>(
    'head_image_thumb',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noticeMeta = const VerificationMeta('notice');
  @override
  late final GeneratedColumn<String> notice = GeneratedColumn<String>(
    'notice',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remarkNickNameMeta = const VerificationMeta(
    'remarkNickName',
  );
  @override
  late final GeneratedColumn<String> remarkNickName = GeneratedColumn<String>(
    'remark_nick_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _showNickNameMeta = const VerificationMeta(
    'showNickName',
  );
  @override
  late final GeneratedColumn<String> showNickName = GeneratedColumn<String>(
    'show_nick_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _showGroupNameMeta = const VerificationMeta(
    'showGroupName',
  );
  @override
  late final GeneratedColumn<String> showGroupName = GeneratedColumn<String>(
    'show_group_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remarkGroupNameMeta = const VerificationMeta(
    'remarkGroupName',
  );
  @override
  late final GeneratedColumn<String> remarkGroupName = GeneratedColumn<String>(
    'remark_group_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isAllMutedMeta = const VerificationMeta(
    'isAllMuted',
  );
  @override
  late final GeneratedColumn<bool> isAllMuted = GeneratedColumn<bool>(
    'is_all_muted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_all_muted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isAllowInviteMeta = const VerificationMeta(
    'isAllowInvite',
  );
  @override
  late final GeneratedColumn<bool> isAllowInvite = GeneratedColumn<bool>(
    'is_allow_invite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_allow_invite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isAllowShareCardMeta = const VerificationMeta(
    'isAllowShareCard',
  );
  @override
  late final GeneratedColumn<bool> isAllowShareCard = GeneratedColumn<bool>(
    'is_allow_share_card',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_allow_share_card" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _dissolveMeta = const VerificationMeta(
    'dissolve',
  );
  @override
  late final GeneratedColumn<bool> dissolve = GeneratedColumn<bool>(
    'dissolve',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("dissolve" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _quitMeta = const VerificationMeta('quit');
  @override
  late final GeneratedColumn<bool> quit = GeneratedColumn<bool>(
    'quit',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("quit" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isMutedMeta = const VerificationMeta(
    'isMuted',
  );
  @override
  late final GeneratedColumn<bool> isMuted = GeneratedColumn<bool>(
    'is_muted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_muted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isBannedMeta = const VerificationMeta(
    'isBanned',
  );
  @override
  late final GeneratedColumn<bool> isBanned = GeneratedColumn<bool>(
    'is_banned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_banned" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDndMeta = const VerificationMeta('isDnd');
  @override
  late final GeneratedColumn<bool> isDnd = GeneratedColumn<bool>(
    'is_dnd',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_dnd" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isTopMeta = const VerificationMeta('isTop');
  @override
  late final GeneratedColumn<bool> isTop = GeneratedColumn<bool>(
    'is_top',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_top" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _topMessageMeta = const VerificationMeta(
    'topMessage',
  );
  @override
  late final GeneratedColumn<String> topMessage = GeneratedColumn<String>(
    'top_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    ownerId,
    headImage,
    headImageThumb,
    notice,
    remarkNickName,
    showNickName,
    showGroupName,
    remarkGroupName,
    isAllMuted,
    isAllowInvite,
    isAllowShareCard,
    dissolve,
    quit,
    isMuted,
    isBanned,
    reason,
    isDnd,
    isTop,
    topMessage,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'groups';
  @override
  VerificationContext validateIntegrity(
    Insertable<Group> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    }
    if (data.containsKey('head_image')) {
      context.handle(
        _headImageMeta,
        headImage.isAcceptableOrUnknown(data['head_image']!, _headImageMeta),
      );
    }
    if (data.containsKey('head_image_thumb')) {
      context.handle(
        _headImageThumbMeta,
        headImageThumb.isAcceptableOrUnknown(
          data['head_image_thumb']!,
          _headImageThumbMeta,
        ),
      );
    }
    if (data.containsKey('notice')) {
      context.handle(
        _noticeMeta,
        notice.isAcceptableOrUnknown(data['notice']!, _noticeMeta),
      );
    }
    if (data.containsKey('remark_nick_name')) {
      context.handle(
        _remarkNickNameMeta,
        remarkNickName.isAcceptableOrUnknown(
          data['remark_nick_name']!,
          _remarkNickNameMeta,
        ),
      );
    }
    if (data.containsKey('show_nick_name')) {
      context.handle(
        _showNickNameMeta,
        showNickName.isAcceptableOrUnknown(
          data['show_nick_name']!,
          _showNickNameMeta,
        ),
      );
    }
    if (data.containsKey('show_group_name')) {
      context.handle(
        _showGroupNameMeta,
        showGroupName.isAcceptableOrUnknown(
          data['show_group_name']!,
          _showGroupNameMeta,
        ),
      );
    }
    if (data.containsKey('remark_group_name')) {
      context.handle(
        _remarkGroupNameMeta,
        remarkGroupName.isAcceptableOrUnknown(
          data['remark_group_name']!,
          _remarkGroupNameMeta,
        ),
      );
    }
    if (data.containsKey('is_all_muted')) {
      context.handle(
        _isAllMutedMeta,
        isAllMuted.isAcceptableOrUnknown(
          data['is_all_muted']!,
          _isAllMutedMeta,
        ),
      );
    }
    if (data.containsKey('is_allow_invite')) {
      context.handle(
        _isAllowInviteMeta,
        isAllowInvite.isAcceptableOrUnknown(
          data['is_allow_invite']!,
          _isAllowInviteMeta,
        ),
      );
    }
    if (data.containsKey('is_allow_share_card')) {
      context.handle(
        _isAllowShareCardMeta,
        isAllowShareCard.isAcceptableOrUnknown(
          data['is_allow_share_card']!,
          _isAllowShareCardMeta,
        ),
      );
    }
    if (data.containsKey('dissolve')) {
      context.handle(
        _dissolveMeta,
        dissolve.isAcceptableOrUnknown(data['dissolve']!, _dissolveMeta),
      );
    }
    if (data.containsKey('quit')) {
      context.handle(
        _quitMeta,
        quit.isAcceptableOrUnknown(data['quit']!, _quitMeta),
      );
    }
    if (data.containsKey('is_muted')) {
      context.handle(
        _isMutedMeta,
        isMuted.isAcceptableOrUnknown(data['is_muted']!, _isMutedMeta),
      );
    }
    if (data.containsKey('is_banned')) {
      context.handle(
        _isBannedMeta,
        isBanned.isAcceptableOrUnknown(data['is_banned']!, _isBannedMeta),
      );
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    }
    if (data.containsKey('is_dnd')) {
      context.handle(
        _isDndMeta,
        isDnd.isAcceptableOrUnknown(data['is_dnd']!, _isDndMeta),
      );
    }
    if (data.containsKey('is_top')) {
      context.handle(
        _isTopMeta,
        isTop.isAcceptableOrUnknown(data['is_top']!, _isTopMeta),
      );
    }
    if (data.containsKey('top_message')) {
      context.handle(
        _topMessageMeta,
        topMessage.isAcceptableOrUnknown(data['top_message']!, _topMessageMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Group map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Group(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}owner_id'],
      ),
      headImage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}head_image'],
      ),
      headImageThumb: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}head_image_thumb'],
      ),
      notice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notice'],
      ),
      remarkNickName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remark_nick_name'],
      ),
      showNickName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}show_nick_name'],
      ),
      showGroupName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}show_group_name'],
      ),
      remarkGroupName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remark_group_name'],
      ),
      isAllMuted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_all_muted'],
      )!,
      isAllowInvite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_allow_invite'],
      )!,
      isAllowShareCard: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_allow_share_card'],
      )!,
      dissolve: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}dissolve'],
      )!,
      quit: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}quit'],
      )!,
      isMuted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_muted'],
      )!,
      isBanned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_banned'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      ),
      isDnd: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_dnd'],
      )!,
      isTop: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_top'],
      )!,
      topMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}top_message'],
      ),
    );
  }

  @override
  $GroupsTable createAlias(String alias) {
    return $GroupsTable(attachedDatabase, alias);
  }
}

class Group extends DataClass implements Insertable<Group> {
  final int id;
  final String? name;
  final int? ownerId;
  final String? headImage;
  final String? headImageThumb;
  final String? notice;
  final String? remarkNickName;
  final String? showNickName;
  final String? showGroupName;
  final String? remarkGroupName;
  final bool isAllMuted;
  final bool isAllowInvite;
  final bool isAllowShareCard;
  final bool dissolve;
  final bool quit;
  final bool isMuted;
  final bool isBanned;
  final String? reason;
  final bool isDnd;
  final bool isTop;

  /// 群置顶消息（JSON: GroupMessageVO）。
  final String? topMessage;
  const Group({
    required this.id,
    this.name,
    this.ownerId,
    this.headImage,
    this.headImageThumb,
    this.notice,
    this.remarkNickName,
    this.showNickName,
    this.showGroupName,
    this.remarkGroupName,
    required this.isAllMuted,
    required this.isAllowInvite,
    required this.isAllowShareCard,
    required this.dissolve,
    required this.quit,
    required this.isMuted,
    required this.isBanned,
    this.reason,
    required this.isDnd,
    required this.isTop,
    this.topMessage,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || ownerId != null) {
      map['owner_id'] = Variable<int>(ownerId);
    }
    if (!nullToAbsent || headImage != null) {
      map['head_image'] = Variable<String>(headImage);
    }
    if (!nullToAbsent || headImageThumb != null) {
      map['head_image_thumb'] = Variable<String>(headImageThumb);
    }
    if (!nullToAbsent || notice != null) {
      map['notice'] = Variable<String>(notice);
    }
    if (!nullToAbsent || remarkNickName != null) {
      map['remark_nick_name'] = Variable<String>(remarkNickName);
    }
    if (!nullToAbsent || showNickName != null) {
      map['show_nick_name'] = Variable<String>(showNickName);
    }
    if (!nullToAbsent || showGroupName != null) {
      map['show_group_name'] = Variable<String>(showGroupName);
    }
    if (!nullToAbsent || remarkGroupName != null) {
      map['remark_group_name'] = Variable<String>(remarkGroupName);
    }
    map['is_all_muted'] = Variable<bool>(isAllMuted);
    map['is_allow_invite'] = Variable<bool>(isAllowInvite);
    map['is_allow_share_card'] = Variable<bool>(isAllowShareCard);
    map['dissolve'] = Variable<bool>(dissolve);
    map['quit'] = Variable<bool>(quit);
    map['is_muted'] = Variable<bool>(isMuted);
    map['is_banned'] = Variable<bool>(isBanned);
    if (!nullToAbsent || reason != null) {
      map['reason'] = Variable<String>(reason);
    }
    map['is_dnd'] = Variable<bool>(isDnd);
    map['is_top'] = Variable<bool>(isTop);
    if (!nullToAbsent || topMessage != null) {
      map['top_message'] = Variable<String>(topMessage);
    }
    return map;
  }

  GroupsCompanion toCompanion(bool nullToAbsent) {
    return GroupsCompanion(
      id: Value(id),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      ownerId: ownerId == null && nullToAbsent
          ? const Value.absent()
          : Value(ownerId),
      headImage: headImage == null && nullToAbsent
          ? const Value.absent()
          : Value(headImage),
      headImageThumb: headImageThumb == null && nullToAbsent
          ? const Value.absent()
          : Value(headImageThumb),
      notice: notice == null && nullToAbsent
          ? const Value.absent()
          : Value(notice),
      remarkNickName: remarkNickName == null && nullToAbsent
          ? const Value.absent()
          : Value(remarkNickName),
      showNickName: showNickName == null && nullToAbsent
          ? const Value.absent()
          : Value(showNickName),
      showGroupName: showGroupName == null && nullToAbsent
          ? const Value.absent()
          : Value(showGroupName),
      remarkGroupName: remarkGroupName == null && nullToAbsent
          ? const Value.absent()
          : Value(remarkGroupName),
      isAllMuted: Value(isAllMuted),
      isAllowInvite: Value(isAllowInvite),
      isAllowShareCard: Value(isAllowShareCard),
      dissolve: Value(dissolve),
      quit: Value(quit),
      isMuted: Value(isMuted),
      isBanned: Value(isBanned),
      reason: reason == null && nullToAbsent
          ? const Value.absent()
          : Value(reason),
      isDnd: Value(isDnd),
      isTop: Value(isTop),
      topMessage: topMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(topMessage),
    );
  }

  factory Group.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Group(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String?>(json['name']),
      ownerId: serializer.fromJson<int?>(json['ownerId']),
      headImage: serializer.fromJson<String?>(json['headImage']),
      headImageThumb: serializer.fromJson<String?>(json['headImageThumb']),
      notice: serializer.fromJson<String?>(json['notice']),
      remarkNickName: serializer.fromJson<String?>(json['remarkNickName']),
      showNickName: serializer.fromJson<String?>(json['showNickName']),
      showGroupName: serializer.fromJson<String?>(json['showGroupName']),
      remarkGroupName: serializer.fromJson<String?>(json['remarkGroupName']),
      isAllMuted: serializer.fromJson<bool>(json['isAllMuted']),
      isAllowInvite: serializer.fromJson<bool>(json['isAllowInvite']),
      isAllowShareCard: serializer.fromJson<bool>(json['isAllowShareCard']),
      dissolve: serializer.fromJson<bool>(json['dissolve']),
      quit: serializer.fromJson<bool>(json['quit']),
      isMuted: serializer.fromJson<bool>(json['isMuted']),
      isBanned: serializer.fromJson<bool>(json['isBanned']),
      reason: serializer.fromJson<String?>(json['reason']),
      isDnd: serializer.fromJson<bool>(json['isDnd']),
      isTop: serializer.fromJson<bool>(json['isTop']),
      topMessage: serializer.fromJson<String?>(json['topMessage']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String?>(name),
      'ownerId': serializer.toJson<int?>(ownerId),
      'headImage': serializer.toJson<String?>(headImage),
      'headImageThumb': serializer.toJson<String?>(headImageThumb),
      'notice': serializer.toJson<String?>(notice),
      'remarkNickName': serializer.toJson<String?>(remarkNickName),
      'showNickName': serializer.toJson<String?>(showNickName),
      'showGroupName': serializer.toJson<String?>(showGroupName),
      'remarkGroupName': serializer.toJson<String?>(remarkGroupName),
      'isAllMuted': serializer.toJson<bool>(isAllMuted),
      'isAllowInvite': serializer.toJson<bool>(isAllowInvite),
      'isAllowShareCard': serializer.toJson<bool>(isAllowShareCard),
      'dissolve': serializer.toJson<bool>(dissolve),
      'quit': serializer.toJson<bool>(quit),
      'isMuted': serializer.toJson<bool>(isMuted),
      'isBanned': serializer.toJson<bool>(isBanned),
      'reason': serializer.toJson<String?>(reason),
      'isDnd': serializer.toJson<bool>(isDnd),
      'isTop': serializer.toJson<bool>(isTop),
      'topMessage': serializer.toJson<String?>(topMessage),
    };
  }

  Group copyWith({
    int? id,
    Value<String?> name = const Value.absent(),
    Value<int?> ownerId = const Value.absent(),
    Value<String?> headImage = const Value.absent(),
    Value<String?> headImageThumb = const Value.absent(),
    Value<String?> notice = const Value.absent(),
    Value<String?> remarkNickName = const Value.absent(),
    Value<String?> showNickName = const Value.absent(),
    Value<String?> showGroupName = const Value.absent(),
    Value<String?> remarkGroupName = const Value.absent(),
    bool? isAllMuted,
    bool? isAllowInvite,
    bool? isAllowShareCard,
    bool? dissolve,
    bool? quit,
    bool? isMuted,
    bool? isBanned,
    Value<String?> reason = const Value.absent(),
    bool? isDnd,
    bool? isTop,
    Value<String?> topMessage = const Value.absent(),
  }) => Group(
    id: id ?? this.id,
    name: name.present ? name.value : this.name,
    ownerId: ownerId.present ? ownerId.value : this.ownerId,
    headImage: headImage.present ? headImage.value : this.headImage,
    headImageThumb: headImageThumb.present
        ? headImageThumb.value
        : this.headImageThumb,
    notice: notice.present ? notice.value : this.notice,
    remarkNickName: remarkNickName.present
        ? remarkNickName.value
        : this.remarkNickName,
    showNickName: showNickName.present ? showNickName.value : this.showNickName,
    showGroupName: showGroupName.present
        ? showGroupName.value
        : this.showGroupName,
    remarkGroupName: remarkGroupName.present
        ? remarkGroupName.value
        : this.remarkGroupName,
    isAllMuted: isAllMuted ?? this.isAllMuted,
    isAllowInvite: isAllowInvite ?? this.isAllowInvite,
    isAllowShareCard: isAllowShareCard ?? this.isAllowShareCard,
    dissolve: dissolve ?? this.dissolve,
    quit: quit ?? this.quit,
    isMuted: isMuted ?? this.isMuted,
    isBanned: isBanned ?? this.isBanned,
    reason: reason.present ? reason.value : this.reason,
    isDnd: isDnd ?? this.isDnd,
    isTop: isTop ?? this.isTop,
    topMessage: topMessage.present ? topMessage.value : this.topMessage,
  );
  Group copyWithCompanion(GroupsCompanion data) {
    return Group(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      headImage: data.headImage.present ? data.headImage.value : this.headImage,
      headImageThumb: data.headImageThumb.present
          ? data.headImageThumb.value
          : this.headImageThumb,
      notice: data.notice.present ? data.notice.value : this.notice,
      remarkNickName: data.remarkNickName.present
          ? data.remarkNickName.value
          : this.remarkNickName,
      showNickName: data.showNickName.present
          ? data.showNickName.value
          : this.showNickName,
      showGroupName: data.showGroupName.present
          ? data.showGroupName.value
          : this.showGroupName,
      remarkGroupName: data.remarkGroupName.present
          ? data.remarkGroupName.value
          : this.remarkGroupName,
      isAllMuted: data.isAllMuted.present
          ? data.isAllMuted.value
          : this.isAllMuted,
      isAllowInvite: data.isAllowInvite.present
          ? data.isAllowInvite.value
          : this.isAllowInvite,
      isAllowShareCard: data.isAllowShareCard.present
          ? data.isAllowShareCard.value
          : this.isAllowShareCard,
      dissolve: data.dissolve.present ? data.dissolve.value : this.dissolve,
      quit: data.quit.present ? data.quit.value : this.quit,
      isMuted: data.isMuted.present ? data.isMuted.value : this.isMuted,
      isBanned: data.isBanned.present ? data.isBanned.value : this.isBanned,
      reason: data.reason.present ? data.reason.value : this.reason,
      isDnd: data.isDnd.present ? data.isDnd.value : this.isDnd,
      isTop: data.isTop.present ? data.isTop.value : this.isTop,
      topMessage: data.topMessage.present
          ? data.topMessage.value
          : this.topMessage,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Group(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('ownerId: $ownerId, ')
          ..write('headImage: $headImage, ')
          ..write('headImageThumb: $headImageThumb, ')
          ..write('notice: $notice, ')
          ..write('remarkNickName: $remarkNickName, ')
          ..write('showNickName: $showNickName, ')
          ..write('showGroupName: $showGroupName, ')
          ..write('remarkGroupName: $remarkGroupName, ')
          ..write('isAllMuted: $isAllMuted, ')
          ..write('isAllowInvite: $isAllowInvite, ')
          ..write('isAllowShareCard: $isAllowShareCard, ')
          ..write('dissolve: $dissolve, ')
          ..write('quit: $quit, ')
          ..write('isMuted: $isMuted, ')
          ..write('isBanned: $isBanned, ')
          ..write('reason: $reason, ')
          ..write('isDnd: $isDnd, ')
          ..write('isTop: $isTop, ')
          ..write('topMessage: $topMessage')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    name,
    ownerId,
    headImage,
    headImageThumb,
    notice,
    remarkNickName,
    showNickName,
    showGroupName,
    remarkGroupName,
    isAllMuted,
    isAllowInvite,
    isAllowShareCard,
    dissolve,
    quit,
    isMuted,
    isBanned,
    reason,
    isDnd,
    isTop,
    topMessage,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Group &&
          other.id == this.id &&
          other.name == this.name &&
          other.ownerId == this.ownerId &&
          other.headImage == this.headImage &&
          other.headImageThumb == this.headImageThumb &&
          other.notice == this.notice &&
          other.remarkNickName == this.remarkNickName &&
          other.showNickName == this.showNickName &&
          other.showGroupName == this.showGroupName &&
          other.remarkGroupName == this.remarkGroupName &&
          other.isAllMuted == this.isAllMuted &&
          other.isAllowInvite == this.isAllowInvite &&
          other.isAllowShareCard == this.isAllowShareCard &&
          other.dissolve == this.dissolve &&
          other.quit == this.quit &&
          other.isMuted == this.isMuted &&
          other.isBanned == this.isBanned &&
          other.reason == this.reason &&
          other.isDnd == this.isDnd &&
          other.isTop == this.isTop &&
          other.topMessage == this.topMessage);
}

class GroupsCompanion extends UpdateCompanion<Group> {
  final Value<int> id;
  final Value<String?> name;
  final Value<int?> ownerId;
  final Value<String?> headImage;
  final Value<String?> headImageThumb;
  final Value<String?> notice;
  final Value<String?> remarkNickName;
  final Value<String?> showNickName;
  final Value<String?> showGroupName;
  final Value<String?> remarkGroupName;
  final Value<bool> isAllMuted;
  final Value<bool> isAllowInvite;
  final Value<bool> isAllowShareCard;
  final Value<bool> dissolve;
  final Value<bool> quit;
  final Value<bool> isMuted;
  final Value<bool> isBanned;
  final Value<String?> reason;
  final Value<bool> isDnd;
  final Value<bool> isTop;
  final Value<String?> topMessage;
  const GroupsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.headImage = const Value.absent(),
    this.headImageThumb = const Value.absent(),
    this.notice = const Value.absent(),
    this.remarkNickName = const Value.absent(),
    this.showNickName = const Value.absent(),
    this.showGroupName = const Value.absent(),
    this.remarkGroupName = const Value.absent(),
    this.isAllMuted = const Value.absent(),
    this.isAllowInvite = const Value.absent(),
    this.isAllowShareCard = const Value.absent(),
    this.dissolve = const Value.absent(),
    this.quit = const Value.absent(),
    this.isMuted = const Value.absent(),
    this.isBanned = const Value.absent(),
    this.reason = const Value.absent(),
    this.isDnd = const Value.absent(),
    this.isTop = const Value.absent(),
    this.topMessage = const Value.absent(),
  });
  GroupsCompanion.insert({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.headImage = const Value.absent(),
    this.headImageThumb = const Value.absent(),
    this.notice = const Value.absent(),
    this.remarkNickName = const Value.absent(),
    this.showNickName = const Value.absent(),
    this.showGroupName = const Value.absent(),
    this.remarkGroupName = const Value.absent(),
    this.isAllMuted = const Value.absent(),
    this.isAllowInvite = const Value.absent(),
    this.isAllowShareCard = const Value.absent(),
    this.dissolve = const Value.absent(),
    this.quit = const Value.absent(),
    this.isMuted = const Value.absent(),
    this.isBanned = const Value.absent(),
    this.reason = const Value.absent(),
    this.isDnd = const Value.absent(),
    this.isTop = const Value.absent(),
    this.topMessage = const Value.absent(),
  });
  static Insertable<Group> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? ownerId,
    Expression<String>? headImage,
    Expression<String>? headImageThumb,
    Expression<String>? notice,
    Expression<String>? remarkNickName,
    Expression<String>? showNickName,
    Expression<String>? showGroupName,
    Expression<String>? remarkGroupName,
    Expression<bool>? isAllMuted,
    Expression<bool>? isAllowInvite,
    Expression<bool>? isAllowShareCard,
    Expression<bool>? dissolve,
    Expression<bool>? quit,
    Expression<bool>? isMuted,
    Expression<bool>? isBanned,
    Expression<String>? reason,
    Expression<bool>? isDnd,
    Expression<bool>? isTop,
    Expression<String>? topMessage,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (ownerId != null) 'owner_id': ownerId,
      if (headImage != null) 'head_image': headImage,
      if (headImageThumb != null) 'head_image_thumb': headImageThumb,
      if (notice != null) 'notice': notice,
      if (remarkNickName != null) 'remark_nick_name': remarkNickName,
      if (showNickName != null) 'show_nick_name': showNickName,
      if (showGroupName != null) 'show_group_name': showGroupName,
      if (remarkGroupName != null) 'remark_group_name': remarkGroupName,
      if (isAllMuted != null) 'is_all_muted': isAllMuted,
      if (isAllowInvite != null) 'is_allow_invite': isAllowInvite,
      if (isAllowShareCard != null) 'is_allow_share_card': isAllowShareCard,
      if (dissolve != null) 'dissolve': dissolve,
      if (quit != null) 'quit': quit,
      if (isMuted != null) 'is_muted': isMuted,
      if (isBanned != null) 'is_banned': isBanned,
      if (reason != null) 'reason': reason,
      if (isDnd != null) 'is_dnd': isDnd,
      if (isTop != null) 'is_top': isTop,
      if (topMessage != null) 'top_message': topMessage,
    });
  }

  GroupsCompanion copyWith({
    Value<int>? id,
    Value<String?>? name,
    Value<int?>? ownerId,
    Value<String?>? headImage,
    Value<String?>? headImageThumb,
    Value<String?>? notice,
    Value<String?>? remarkNickName,
    Value<String?>? showNickName,
    Value<String?>? showGroupName,
    Value<String?>? remarkGroupName,
    Value<bool>? isAllMuted,
    Value<bool>? isAllowInvite,
    Value<bool>? isAllowShareCard,
    Value<bool>? dissolve,
    Value<bool>? quit,
    Value<bool>? isMuted,
    Value<bool>? isBanned,
    Value<String?>? reason,
    Value<bool>? isDnd,
    Value<bool>? isTop,
    Value<String?>? topMessage,
  }) {
    return GroupsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerId: ownerId ?? this.ownerId,
      headImage: headImage ?? this.headImage,
      headImageThumb: headImageThumb ?? this.headImageThumb,
      notice: notice ?? this.notice,
      remarkNickName: remarkNickName ?? this.remarkNickName,
      showNickName: showNickName ?? this.showNickName,
      showGroupName: showGroupName ?? this.showGroupName,
      remarkGroupName: remarkGroupName ?? this.remarkGroupName,
      isAllMuted: isAllMuted ?? this.isAllMuted,
      isAllowInvite: isAllowInvite ?? this.isAllowInvite,
      isAllowShareCard: isAllowShareCard ?? this.isAllowShareCard,
      dissolve: dissolve ?? this.dissolve,
      quit: quit ?? this.quit,
      isMuted: isMuted ?? this.isMuted,
      isBanned: isBanned ?? this.isBanned,
      reason: reason ?? this.reason,
      isDnd: isDnd ?? this.isDnd,
      isTop: isTop ?? this.isTop,
      topMessage: topMessage ?? this.topMessage,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<int>(ownerId.value);
    }
    if (headImage.present) {
      map['head_image'] = Variable<String>(headImage.value);
    }
    if (headImageThumb.present) {
      map['head_image_thumb'] = Variable<String>(headImageThumb.value);
    }
    if (notice.present) {
      map['notice'] = Variable<String>(notice.value);
    }
    if (remarkNickName.present) {
      map['remark_nick_name'] = Variable<String>(remarkNickName.value);
    }
    if (showNickName.present) {
      map['show_nick_name'] = Variable<String>(showNickName.value);
    }
    if (showGroupName.present) {
      map['show_group_name'] = Variable<String>(showGroupName.value);
    }
    if (remarkGroupName.present) {
      map['remark_group_name'] = Variable<String>(remarkGroupName.value);
    }
    if (isAllMuted.present) {
      map['is_all_muted'] = Variable<bool>(isAllMuted.value);
    }
    if (isAllowInvite.present) {
      map['is_allow_invite'] = Variable<bool>(isAllowInvite.value);
    }
    if (isAllowShareCard.present) {
      map['is_allow_share_card'] = Variable<bool>(isAllowShareCard.value);
    }
    if (dissolve.present) {
      map['dissolve'] = Variable<bool>(dissolve.value);
    }
    if (quit.present) {
      map['quit'] = Variable<bool>(quit.value);
    }
    if (isMuted.present) {
      map['is_muted'] = Variable<bool>(isMuted.value);
    }
    if (isBanned.present) {
      map['is_banned'] = Variable<bool>(isBanned.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (isDnd.present) {
      map['is_dnd'] = Variable<bool>(isDnd.value);
    }
    if (isTop.present) {
      map['is_top'] = Variable<bool>(isTop.value);
    }
    if (topMessage.present) {
      map['top_message'] = Variable<String>(topMessage.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GroupsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('ownerId: $ownerId, ')
          ..write('headImage: $headImage, ')
          ..write('headImageThumb: $headImageThumb, ')
          ..write('notice: $notice, ')
          ..write('remarkNickName: $remarkNickName, ')
          ..write('showNickName: $showNickName, ')
          ..write('showGroupName: $showGroupName, ')
          ..write('remarkGroupName: $remarkGroupName, ')
          ..write('isAllMuted: $isAllMuted, ')
          ..write('isAllowInvite: $isAllowInvite, ')
          ..write('isAllowShareCard: $isAllowShareCard, ')
          ..write('dissolve: $dissolve, ')
          ..write('quit: $quit, ')
          ..write('isMuted: $isMuted, ')
          ..write('isBanned: $isBanned, ')
          ..write('reason: $reason, ')
          ..write('isDnd: $isDnd, ')
          ..write('isTop: $isTop, ')
          ..write('topMessage: $topMessage')
          ..write(')'))
        .toString();
  }
}

class $GroupMembersTable extends GroupMembers
    with TableInfo<$GroupMembersTable, GroupMember> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GroupMembersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<int> groupId = GeneratedColumn<int>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _showNickNameMeta = const VerificationMeta(
    'showNickName',
  );
  @override
  late final GeneratedColumn<String> showNickName = GeneratedColumn<String>(
    'show_nick_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remarkNickNameMeta = const VerificationMeta(
    'remarkNickName',
  );
  @override
  late final GeneratedColumn<String> remarkNickName = GeneratedColumn<String>(
    'remark_nick_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _headImageMeta = const VerificationMeta(
    'headImage',
  );
  @override
  late final GeneratedColumn<String> headImage = GeneratedColumn<String>(
    'head_image',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _companyNameMeta = const VerificationMeta(
    'companyName',
  );
  @override
  late final GeneratedColumn<String> companyName = GeneratedColumn<String>(
    'company_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isManagerMeta = const VerificationMeta(
    'isManager',
  );
  @override
  late final GeneratedColumn<bool> isManager = GeneratedColumn<bool>(
    'is_manager',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_manager" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isMutedMeta = const VerificationMeta(
    'isMuted',
  );
  @override
  late final GeneratedColumn<bool> isMuted = GeneratedColumn<bool>(
    'is_muted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_muted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _quitMeta = const VerificationMeta('quit');
  @override
  late final GeneratedColumn<bool> quit = GeneratedColumn<bool>(
    'quit',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("quit" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _onlineMeta = const VerificationMeta('online');
  @override
  late final GeneratedColumn<bool> online = GeneratedColumn<bool>(
    'online',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("online" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _showGroupNameMeta = const VerificationMeta(
    'showGroupName',
  );
  @override
  late final GeneratedColumn<String> showGroupName = GeneratedColumn<String>(
    'show_group_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remarkGroupNameMeta = const VerificationMeta(
    'remarkGroupName',
  );
  @override
  late final GeneratedColumn<String> remarkGroupName = GeneratedColumn<String>(
    'remark_group_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    groupId,
    userId,
    showNickName,
    remarkNickName,
    headImage,
    companyName,
    isManager,
    isMuted,
    quit,
    online,
    showGroupName,
    remarkGroupName,
    version,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'group_members';
  @override
  VerificationContext validateIntegrity(
    Insertable<GroupMember> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('show_nick_name')) {
      context.handle(
        _showNickNameMeta,
        showNickName.isAcceptableOrUnknown(
          data['show_nick_name']!,
          _showNickNameMeta,
        ),
      );
    }
    if (data.containsKey('remark_nick_name')) {
      context.handle(
        _remarkNickNameMeta,
        remarkNickName.isAcceptableOrUnknown(
          data['remark_nick_name']!,
          _remarkNickNameMeta,
        ),
      );
    }
    if (data.containsKey('head_image')) {
      context.handle(
        _headImageMeta,
        headImage.isAcceptableOrUnknown(data['head_image']!, _headImageMeta),
      );
    }
    if (data.containsKey('company_name')) {
      context.handle(
        _companyNameMeta,
        companyName.isAcceptableOrUnknown(
          data['company_name']!,
          _companyNameMeta,
        ),
      );
    }
    if (data.containsKey('is_manager')) {
      context.handle(
        _isManagerMeta,
        isManager.isAcceptableOrUnknown(data['is_manager']!, _isManagerMeta),
      );
    }
    if (data.containsKey('is_muted')) {
      context.handle(
        _isMutedMeta,
        isMuted.isAcceptableOrUnknown(data['is_muted']!, _isMutedMeta),
      );
    }
    if (data.containsKey('quit')) {
      context.handle(
        _quitMeta,
        quit.isAcceptableOrUnknown(data['quit']!, _quitMeta),
      );
    }
    if (data.containsKey('online')) {
      context.handle(
        _onlineMeta,
        online.isAcceptableOrUnknown(data['online']!, _onlineMeta),
      );
    }
    if (data.containsKey('show_group_name')) {
      context.handle(
        _showGroupNameMeta,
        showGroupName.isAcceptableOrUnknown(
          data['show_group_name']!,
          _showGroupNameMeta,
        ),
      );
    }
    if (data.containsKey('remark_group_name')) {
      context.handle(
        _remarkGroupNameMeta,
        remarkGroupName.isAcceptableOrUnknown(
          data['remark_group_name']!,
          _remarkGroupNameMeta,
        ),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {groupId, userId};
  @override
  GroupMember map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GroupMember(
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}group_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_id'],
      )!,
      showNickName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}show_nick_name'],
      ),
      remarkNickName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remark_nick_name'],
      ),
      headImage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}head_image'],
      ),
      companyName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company_name'],
      ),
      isManager: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_manager'],
      )!,
      isMuted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_muted'],
      )!,
      quit: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}quit'],
      )!,
      online: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}online'],
      )!,
      showGroupName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}show_group_name'],
      ),
      remarkGroupName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remark_group_name'],
      ),
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
    );
  }

  @override
  $GroupMembersTable createAlias(String alias) {
    return $GroupMembersTable(attachedDatabase, alias);
  }
}

class GroupMember extends DataClass implements Insertable<GroupMember> {
  final int groupId;
  final int userId;
  final String? showNickName;
  final String? remarkNickName;
  final String? headImage;
  final String? companyName;
  final bool isManager;
  final bool isMuted;
  final bool quit;
  final bool online;
  final String? showGroupName;
  final String? remarkGroupName;
  final int version;
  const GroupMember({
    required this.groupId,
    required this.userId,
    this.showNickName,
    this.remarkNickName,
    this.headImage,
    this.companyName,
    required this.isManager,
    required this.isMuted,
    required this.quit,
    required this.online,
    this.showGroupName,
    this.remarkGroupName,
    required this.version,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['group_id'] = Variable<int>(groupId);
    map['user_id'] = Variable<int>(userId);
    if (!nullToAbsent || showNickName != null) {
      map['show_nick_name'] = Variable<String>(showNickName);
    }
    if (!nullToAbsent || remarkNickName != null) {
      map['remark_nick_name'] = Variable<String>(remarkNickName);
    }
    if (!nullToAbsent || headImage != null) {
      map['head_image'] = Variable<String>(headImage);
    }
    if (!nullToAbsent || companyName != null) {
      map['company_name'] = Variable<String>(companyName);
    }
    map['is_manager'] = Variable<bool>(isManager);
    map['is_muted'] = Variable<bool>(isMuted);
    map['quit'] = Variable<bool>(quit);
    map['online'] = Variable<bool>(online);
    if (!nullToAbsent || showGroupName != null) {
      map['show_group_name'] = Variable<String>(showGroupName);
    }
    if (!nullToAbsent || remarkGroupName != null) {
      map['remark_group_name'] = Variable<String>(remarkGroupName);
    }
    map['version'] = Variable<int>(version);
    return map;
  }

  GroupMembersCompanion toCompanion(bool nullToAbsent) {
    return GroupMembersCompanion(
      groupId: Value(groupId),
      userId: Value(userId),
      showNickName: showNickName == null && nullToAbsent
          ? const Value.absent()
          : Value(showNickName),
      remarkNickName: remarkNickName == null && nullToAbsent
          ? const Value.absent()
          : Value(remarkNickName),
      headImage: headImage == null && nullToAbsent
          ? const Value.absent()
          : Value(headImage),
      companyName: companyName == null && nullToAbsent
          ? const Value.absent()
          : Value(companyName),
      isManager: Value(isManager),
      isMuted: Value(isMuted),
      quit: Value(quit),
      online: Value(online),
      showGroupName: showGroupName == null && nullToAbsent
          ? const Value.absent()
          : Value(showGroupName),
      remarkGroupName: remarkGroupName == null && nullToAbsent
          ? const Value.absent()
          : Value(remarkGroupName),
      version: Value(version),
    );
  }

  factory GroupMember.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GroupMember(
      groupId: serializer.fromJson<int>(json['groupId']),
      userId: serializer.fromJson<int>(json['userId']),
      showNickName: serializer.fromJson<String?>(json['showNickName']),
      remarkNickName: serializer.fromJson<String?>(json['remarkNickName']),
      headImage: serializer.fromJson<String?>(json['headImage']),
      companyName: serializer.fromJson<String?>(json['companyName']),
      isManager: serializer.fromJson<bool>(json['isManager']),
      isMuted: serializer.fromJson<bool>(json['isMuted']),
      quit: serializer.fromJson<bool>(json['quit']),
      online: serializer.fromJson<bool>(json['online']),
      showGroupName: serializer.fromJson<String?>(json['showGroupName']),
      remarkGroupName: serializer.fromJson<String?>(json['remarkGroupName']),
      version: serializer.fromJson<int>(json['version']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'groupId': serializer.toJson<int>(groupId),
      'userId': serializer.toJson<int>(userId),
      'showNickName': serializer.toJson<String?>(showNickName),
      'remarkNickName': serializer.toJson<String?>(remarkNickName),
      'headImage': serializer.toJson<String?>(headImage),
      'companyName': serializer.toJson<String?>(companyName),
      'isManager': serializer.toJson<bool>(isManager),
      'isMuted': serializer.toJson<bool>(isMuted),
      'quit': serializer.toJson<bool>(quit),
      'online': serializer.toJson<bool>(online),
      'showGroupName': serializer.toJson<String?>(showGroupName),
      'remarkGroupName': serializer.toJson<String?>(remarkGroupName),
      'version': serializer.toJson<int>(version),
    };
  }

  GroupMember copyWith({
    int? groupId,
    int? userId,
    Value<String?> showNickName = const Value.absent(),
    Value<String?> remarkNickName = const Value.absent(),
    Value<String?> headImage = const Value.absent(),
    Value<String?> companyName = const Value.absent(),
    bool? isManager,
    bool? isMuted,
    bool? quit,
    bool? online,
    Value<String?> showGroupName = const Value.absent(),
    Value<String?> remarkGroupName = const Value.absent(),
    int? version,
  }) => GroupMember(
    groupId: groupId ?? this.groupId,
    userId: userId ?? this.userId,
    showNickName: showNickName.present ? showNickName.value : this.showNickName,
    remarkNickName: remarkNickName.present
        ? remarkNickName.value
        : this.remarkNickName,
    headImage: headImage.present ? headImage.value : this.headImage,
    companyName: companyName.present ? companyName.value : this.companyName,
    isManager: isManager ?? this.isManager,
    isMuted: isMuted ?? this.isMuted,
    quit: quit ?? this.quit,
    online: online ?? this.online,
    showGroupName: showGroupName.present
        ? showGroupName.value
        : this.showGroupName,
    remarkGroupName: remarkGroupName.present
        ? remarkGroupName.value
        : this.remarkGroupName,
    version: version ?? this.version,
  );
  GroupMember copyWithCompanion(GroupMembersCompanion data) {
    return GroupMember(
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      userId: data.userId.present ? data.userId.value : this.userId,
      showNickName: data.showNickName.present
          ? data.showNickName.value
          : this.showNickName,
      remarkNickName: data.remarkNickName.present
          ? data.remarkNickName.value
          : this.remarkNickName,
      headImage: data.headImage.present ? data.headImage.value : this.headImage,
      companyName: data.companyName.present
          ? data.companyName.value
          : this.companyName,
      isManager: data.isManager.present ? data.isManager.value : this.isManager,
      isMuted: data.isMuted.present ? data.isMuted.value : this.isMuted,
      quit: data.quit.present ? data.quit.value : this.quit,
      online: data.online.present ? data.online.value : this.online,
      showGroupName: data.showGroupName.present
          ? data.showGroupName.value
          : this.showGroupName,
      remarkGroupName: data.remarkGroupName.present
          ? data.remarkGroupName.value
          : this.remarkGroupName,
      version: data.version.present ? data.version.value : this.version,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GroupMember(')
          ..write('groupId: $groupId, ')
          ..write('userId: $userId, ')
          ..write('showNickName: $showNickName, ')
          ..write('remarkNickName: $remarkNickName, ')
          ..write('headImage: $headImage, ')
          ..write('companyName: $companyName, ')
          ..write('isManager: $isManager, ')
          ..write('isMuted: $isMuted, ')
          ..write('quit: $quit, ')
          ..write('online: $online, ')
          ..write('showGroupName: $showGroupName, ')
          ..write('remarkGroupName: $remarkGroupName, ')
          ..write('version: $version')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    groupId,
    userId,
    showNickName,
    remarkNickName,
    headImage,
    companyName,
    isManager,
    isMuted,
    quit,
    online,
    showGroupName,
    remarkGroupName,
    version,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GroupMember &&
          other.groupId == this.groupId &&
          other.userId == this.userId &&
          other.showNickName == this.showNickName &&
          other.remarkNickName == this.remarkNickName &&
          other.headImage == this.headImage &&
          other.companyName == this.companyName &&
          other.isManager == this.isManager &&
          other.isMuted == this.isMuted &&
          other.quit == this.quit &&
          other.online == this.online &&
          other.showGroupName == this.showGroupName &&
          other.remarkGroupName == this.remarkGroupName &&
          other.version == this.version);
}

class GroupMembersCompanion extends UpdateCompanion<GroupMember> {
  final Value<int> groupId;
  final Value<int> userId;
  final Value<String?> showNickName;
  final Value<String?> remarkNickName;
  final Value<String?> headImage;
  final Value<String?> companyName;
  final Value<bool> isManager;
  final Value<bool> isMuted;
  final Value<bool> quit;
  final Value<bool> online;
  final Value<String?> showGroupName;
  final Value<String?> remarkGroupName;
  final Value<int> version;
  final Value<int> rowid;
  const GroupMembersCompanion({
    this.groupId = const Value.absent(),
    this.userId = const Value.absent(),
    this.showNickName = const Value.absent(),
    this.remarkNickName = const Value.absent(),
    this.headImage = const Value.absent(),
    this.companyName = const Value.absent(),
    this.isManager = const Value.absent(),
    this.isMuted = const Value.absent(),
    this.quit = const Value.absent(),
    this.online = const Value.absent(),
    this.showGroupName = const Value.absent(),
    this.remarkGroupName = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GroupMembersCompanion.insert({
    required int groupId,
    required int userId,
    this.showNickName = const Value.absent(),
    this.remarkNickName = const Value.absent(),
    this.headImage = const Value.absent(),
    this.companyName = const Value.absent(),
    this.isManager = const Value.absent(),
    this.isMuted = const Value.absent(),
    this.quit = const Value.absent(),
    this.online = const Value.absent(),
    this.showGroupName = const Value.absent(),
    this.remarkGroupName = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : groupId = Value(groupId),
       userId = Value(userId);
  static Insertable<GroupMember> custom({
    Expression<int>? groupId,
    Expression<int>? userId,
    Expression<String>? showNickName,
    Expression<String>? remarkNickName,
    Expression<String>? headImage,
    Expression<String>? companyName,
    Expression<bool>? isManager,
    Expression<bool>? isMuted,
    Expression<bool>? quit,
    Expression<bool>? online,
    Expression<String>? showGroupName,
    Expression<String>? remarkGroupName,
    Expression<int>? version,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (groupId != null) 'group_id': groupId,
      if (userId != null) 'user_id': userId,
      if (showNickName != null) 'show_nick_name': showNickName,
      if (remarkNickName != null) 'remark_nick_name': remarkNickName,
      if (headImage != null) 'head_image': headImage,
      if (companyName != null) 'company_name': companyName,
      if (isManager != null) 'is_manager': isManager,
      if (isMuted != null) 'is_muted': isMuted,
      if (quit != null) 'quit': quit,
      if (online != null) 'online': online,
      if (showGroupName != null) 'show_group_name': showGroupName,
      if (remarkGroupName != null) 'remark_group_name': remarkGroupName,
      if (version != null) 'version': version,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GroupMembersCompanion copyWith({
    Value<int>? groupId,
    Value<int>? userId,
    Value<String?>? showNickName,
    Value<String?>? remarkNickName,
    Value<String?>? headImage,
    Value<String?>? companyName,
    Value<bool>? isManager,
    Value<bool>? isMuted,
    Value<bool>? quit,
    Value<bool>? online,
    Value<String?>? showGroupName,
    Value<String?>? remarkGroupName,
    Value<int>? version,
    Value<int>? rowid,
  }) {
    return GroupMembersCompanion(
      groupId: groupId ?? this.groupId,
      userId: userId ?? this.userId,
      showNickName: showNickName ?? this.showNickName,
      remarkNickName: remarkNickName ?? this.remarkNickName,
      headImage: headImage ?? this.headImage,
      companyName: companyName ?? this.companyName,
      isManager: isManager ?? this.isManager,
      isMuted: isMuted ?? this.isMuted,
      quit: quit ?? this.quit,
      online: online ?? this.online,
      showGroupName: showGroupName ?? this.showGroupName,
      remarkGroupName: remarkGroupName ?? this.remarkGroupName,
      version: version ?? this.version,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (groupId.present) {
      map['group_id'] = Variable<int>(groupId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (showNickName.present) {
      map['show_nick_name'] = Variable<String>(showNickName.value);
    }
    if (remarkNickName.present) {
      map['remark_nick_name'] = Variable<String>(remarkNickName.value);
    }
    if (headImage.present) {
      map['head_image'] = Variable<String>(headImage.value);
    }
    if (companyName.present) {
      map['company_name'] = Variable<String>(companyName.value);
    }
    if (isManager.present) {
      map['is_manager'] = Variable<bool>(isManager.value);
    }
    if (isMuted.present) {
      map['is_muted'] = Variable<bool>(isMuted.value);
    }
    if (quit.present) {
      map['quit'] = Variable<bool>(quit.value);
    }
    if (online.present) {
      map['online'] = Variable<bool>(online.value);
    }
    if (showGroupName.present) {
      map['show_group_name'] = Variable<String>(showGroupName.value);
    }
    if (remarkGroupName.present) {
      map['remark_group_name'] = Variable<String>(remarkGroupName.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GroupMembersCompanion(')
          ..write('groupId: $groupId, ')
          ..write('userId: $userId, ')
          ..write('showNickName: $showNickName, ')
          ..write('remarkNickName: $remarkNickName, ')
          ..write('headImage: $headImage, ')
          ..write('companyName: $companyName, ')
          ..write('isManager: $isManager, ')
          ..write('isMuted: $isMuted, ')
          ..write('quit: $quit, ')
          ..write('online: $online, ')
          ..write('showGroupName: $showGroupName, ')
          ..write('remarkGroupName: $remarkGroupName, ')
          ..write('version: $version, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FriendRequestsTable extends FriendRequests
    with TableInfo<$FriendRequestsTable, FriendRequest> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FriendRequestsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sendIdMeta = const VerificationMeta('sendId');
  @override
  late final GeneratedColumn<int> sendId = GeneratedColumn<int>(
    'send_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sendNickNameMeta = const VerificationMeta(
    'sendNickName',
  );
  @override
  late final GeneratedColumn<String> sendNickName = GeneratedColumn<String>(
    'send_nick_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sendHeadImageMeta = const VerificationMeta(
    'sendHeadImage',
  );
  @override
  late final GeneratedColumn<String> sendHeadImage = GeneratedColumn<String>(
    'send_head_image',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recvIdMeta = const VerificationMeta('recvId');
  @override
  late final GeneratedColumn<int> recvId = GeneratedColumn<int>(
    'recv_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recvNickNameMeta = const VerificationMeta(
    'recvNickName',
  );
  @override
  late final GeneratedColumn<String> recvNickName = GeneratedColumn<String>(
    'recv_nick_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recvHeadImageMeta = const VerificationMeta(
    'recvHeadImage',
  );
  @override
  late final GeneratedColumn<String> recvHeadImage = GeneratedColumn<String>(
    'recv_head_image',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remarkMeta = const VerificationMeta('remark');
  @override
  late final GeneratedColumn<String> remark = GeneratedColumn<String>(
    'remark',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<int> status = GeneratedColumn<int>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _applyTimeMeta = const VerificationMeta(
    'applyTime',
  );
  @override
  late final GeneratedColumn<int> applyTime = GeneratedColumn<int>(
    'apply_time',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sendId,
    sendNickName,
    sendHeadImage,
    recvId,
    recvNickName,
    recvHeadImage,
    remark,
    status,
    applyTime,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'friend_requests';
  @override
  VerificationContext validateIntegrity(
    Insertable<FriendRequest> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('send_id')) {
      context.handle(
        _sendIdMeta,
        sendId.isAcceptableOrUnknown(data['send_id']!, _sendIdMeta),
      );
    }
    if (data.containsKey('send_nick_name')) {
      context.handle(
        _sendNickNameMeta,
        sendNickName.isAcceptableOrUnknown(
          data['send_nick_name']!,
          _sendNickNameMeta,
        ),
      );
    }
    if (data.containsKey('send_head_image')) {
      context.handle(
        _sendHeadImageMeta,
        sendHeadImage.isAcceptableOrUnknown(
          data['send_head_image']!,
          _sendHeadImageMeta,
        ),
      );
    }
    if (data.containsKey('recv_id')) {
      context.handle(
        _recvIdMeta,
        recvId.isAcceptableOrUnknown(data['recv_id']!, _recvIdMeta),
      );
    }
    if (data.containsKey('recv_nick_name')) {
      context.handle(
        _recvNickNameMeta,
        recvNickName.isAcceptableOrUnknown(
          data['recv_nick_name']!,
          _recvNickNameMeta,
        ),
      );
    }
    if (data.containsKey('recv_head_image')) {
      context.handle(
        _recvHeadImageMeta,
        recvHeadImage.isAcceptableOrUnknown(
          data['recv_head_image']!,
          _recvHeadImageMeta,
        ),
      );
    }
    if (data.containsKey('remark')) {
      context.handle(
        _remarkMeta,
        remark.isAcceptableOrUnknown(data['remark']!, _remarkMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('apply_time')) {
      context.handle(
        _applyTimeMeta,
        applyTime.isAcceptableOrUnknown(data['apply_time']!, _applyTimeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FriendRequest map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FriendRequest(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sendId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}send_id'],
      ),
      sendNickName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}send_nick_name'],
      ),
      sendHeadImage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}send_head_image'],
      ),
      recvId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recv_id'],
      ),
      recvNickName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recv_nick_name'],
      ),
      recvHeadImage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recv_head_image'],
      ),
      remark: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remark'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}status'],
      )!,
      applyTime: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}apply_time'],
      ),
    );
  }

  @override
  $FriendRequestsTable createAlias(String alias) {
    return $FriendRequestsTable(attachedDatabase, alias);
  }
}

class FriendRequest extends DataClass implements Insertable<FriendRequest> {
  final int id;
  final int? sendId;
  final String? sendNickName;
  final String? sendHeadImage;
  final int? recvId;
  final String? recvNickName;
  final String? recvHeadImage;
  final String? remark;

  /// 1待处理/2同意/3拒绝/4过期，见 RequestStatus。
  final int status;
  final int? applyTime;
  const FriendRequest({
    required this.id,
    this.sendId,
    this.sendNickName,
    this.sendHeadImage,
    this.recvId,
    this.recvNickName,
    this.recvHeadImage,
    this.remark,
    required this.status,
    this.applyTime,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || sendId != null) {
      map['send_id'] = Variable<int>(sendId);
    }
    if (!nullToAbsent || sendNickName != null) {
      map['send_nick_name'] = Variable<String>(sendNickName);
    }
    if (!nullToAbsent || sendHeadImage != null) {
      map['send_head_image'] = Variable<String>(sendHeadImage);
    }
    if (!nullToAbsent || recvId != null) {
      map['recv_id'] = Variable<int>(recvId);
    }
    if (!nullToAbsent || recvNickName != null) {
      map['recv_nick_name'] = Variable<String>(recvNickName);
    }
    if (!nullToAbsent || recvHeadImage != null) {
      map['recv_head_image'] = Variable<String>(recvHeadImage);
    }
    if (!nullToAbsent || remark != null) {
      map['remark'] = Variable<String>(remark);
    }
    map['status'] = Variable<int>(status);
    if (!nullToAbsent || applyTime != null) {
      map['apply_time'] = Variable<int>(applyTime);
    }
    return map;
  }

  FriendRequestsCompanion toCompanion(bool nullToAbsent) {
    return FriendRequestsCompanion(
      id: Value(id),
      sendId: sendId == null && nullToAbsent
          ? const Value.absent()
          : Value(sendId),
      sendNickName: sendNickName == null && nullToAbsent
          ? const Value.absent()
          : Value(sendNickName),
      sendHeadImage: sendHeadImage == null && nullToAbsent
          ? const Value.absent()
          : Value(sendHeadImage),
      recvId: recvId == null && nullToAbsent
          ? const Value.absent()
          : Value(recvId),
      recvNickName: recvNickName == null && nullToAbsent
          ? const Value.absent()
          : Value(recvNickName),
      recvHeadImage: recvHeadImage == null && nullToAbsent
          ? const Value.absent()
          : Value(recvHeadImage),
      remark: remark == null && nullToAbsent
          ? const Value.absent()
          : Value(remark),
      status: Value(status),
      applyTime: applyTime == null && nullToAbsent
          ? const Value.absent()
          : Value(applyTime),
    );
  }

  factory FriendRequest.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FriendRequest(
      id: serializer.fromJson<int>(json['id']),
      sendId: serializer.fromJson<int?>(json['sendId']),
      sendNickName: serializer.fromJson<String?>(json['sendNickName']),
      sendHeadImage: serializer.fromJson<String?>(json['sendHeadImage']),
      recvId: serializer.fromJson<int?>(json['recvId']),
      recvNickName: serializer.fromJson<String?>(json['recvNickName']),
      recvHeadImage: serializer.fromJson<String?>(json['recvHeadImage']),
      remark: serializer.fromJson<String?>(json['remark']),
      status: serializer.fromJson<int>(json['status']),
      applyTime: serializer.fromJson<int?>(json['applyTime']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sendId': serializer.toJson<int?>(sendId),
      'sendNickName': serializer.toJson<String?>(sendNickName),
      'sendHeadImage': serializer.toJson<String?>(sendHeadImage),
      'recvId': serializer.toJson<int?>(recvId),
      'recvNickName': serializer.toJson<String?>(recvNickName),
      'recvHeadImage': serializer.toJson<String?>(recvHeadImage),
      'remark': serializer.toJson<String?>(remark),
      'status': serializer.toJson<int>(status),
      'applyTime': serializer.toJson<int?>(applyTime),
    };
  }

  FriendRequest copyWith({
    int? id,
    Value<int?> sendId = const Value.absent(),
    Value<String?> sendNickName = const Value.absent(),
    Value<String?> sendHeadImage = const Value.absent(),
    Value<int?> recvId = const Value.absent(),
    Value<String?> recvNickName = const Value.absent(),
    Value<String?> recvHeadImage = const Value.absent(),
    Value<String?> remark = const Value.absent(),
    int? status,
    Value<int?> applyTime = const Value.absent(),
  }) => FriendRequest(
    id: id ?? this.id,
    sendId: sendId.present ? sendId.value : this.sendId,
    sendNickName: sendNickName.present ? sendNickName.value : this.sendNickName,
    sendHeadImage: sendHeadImage.present
        ? sendHeadImage.value
        : this.sendHeadImage,
    recvId: recvId.present ? recvId.value : this.recvId,
    recvNickName: recvNickName.present ? recvNickName.value : this.recvNickName,
    recvHeadImage: recvHeadImage.present
        ? recvHeadImage.value
        : this.recvHeadImage,
    remark: remark.present ? remark.value : this.remark,
    status: status ?? this.status,
    applyTime: applyTime.present ? applyTime.value : this.applyTime,
  );
  FriendRequest copyWithCompanion(FriendRequestsCompanion data) {
    return FriendRequest(
      id: data.id.present ? data.id.value : this.id,
      sendId: data.sendId.present ? data.sendId.value : this.sendId,
      sendNickName: data.sendNickName.present
          ? data.sendNickName.value
          : this.sendNickName,
      sendHeadImage: data.sendHeadImage.present
          ? data.sendHeadImage.value
          : this.sendHeadImage,
      recvId: data.recvId.present ? data.recvId.value : this.recvId,
      recvNickName: data.recvNickName.present
          ? data.recvNickName.value
          : this.recvNickName,
      recvHeadImage: data.recvHeadImage.present
          ? data.recvHeadImage.value
          : this.recvHeadImage,
      remark: data.remark.present ? data.remark.value : this.remark,
      status: data.status.present ? data.status.value : this.status,
      applyTime: data.applyTime.present ? data.applyTime.value : this.applyTime,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FriendRequest(')
          ..write('id: $id, ')
          ..write('sendId: $sendId, ')
          ..write('sendNickName: $sendNickName, ')
          ..write('sendHeadImage: $sendHeadImage, ')
          ..write('recvId: $recvId, ')
          ..write('recvNickName: $recvNickName, ')
          ..write('recvHeadImage: $recvHeadImage, ')
          ..write('remark: $remark, ')
          ..write('status: $status, ')
          ..write('applyTime: $applyTime')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sendId,
    sendNickName,
    sendHeadImage,
    recvId,
    recvNickName,
    recvHeadImage,
    remark,
    status,
    applyTime,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FriendRequest &&
          other.id == this.id &&
          other.sendId == this.sendId &&
          other.sendNickName == this.sendNickName &&
          other.sendHeadImage == this.sendHeadImage &&
          other.recvId == this.recvId &&
          other.recvNickName == this.recvNickName &&
          other.recvHeadImage == this.recvHeadImage &&
          other.remark == this.remark &&
          other.status == this.status &&
          other.applyTime == this.applyTime);
}

class FriendRequestsCompanion extends UpdateCompanion<FriendRequest> {
  final Value<int> id;
  final Value<int?> sendId;
  final Value<String?> sendNickName;
  final Value<String?> sendHeadImage;
  final Value<int?> recvId;
  final Value<String?> recvNickName;
  final Value<String?> recvHeadImage;
  final Value<String?> remark;
  final Value<int> status;
  final Value<int?> applyTime;
  const FriendRequestsCompanion({
    this.id = const Value.absent(),
    this.sendId = const Value.absent(),
    this.sendNickName = const Value.absent(),
    this.sendHeadImage = const Value.absent(),
    this.recvId = const Value.absent(),
    this.recvNickName = const Value.absent(),
    this.recvHeadImage = const Value.absent(),
    this.remark = const Value.absent(),
    this.status = const Value.absent(),
    this.applyTime = const Value.absent(),
  });
  FriendRequestsCompanion.insert({
    this.id = const Value.absent(),
    this.sendId = const Value.absent(),
    this.sendNickName = const Value.absent(),
    this.sendHeadImage = const Value.absent(),
    this.recvId = const Value.absent(),
    this.recvNickName = const Value.absent(),
    this.recvHeadImage = const Value.absent(),
    this.remark = const Value.absent(),
    this.status = const Value.absent(),
    this.applyTime = const Value.absent(),
  });
  static Insertable<FriendRequest> custom({
    Expression<int>? id,
    Expression<int>? sendId,
    Expression<String>? sendNickName,
    Expression<String>? sendHeadImage,
    Expression<int>? recvId,
    Expression<String>? recvNickName,
    Expression<String>? recvHeadImage,
    Expression<String>? remark,
    Expression<int>? status,
    Expression<int>? applyTime,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sendId != null) 'send_id': sendId,
      if (sendNickName != null) 'send_nick_name': sendNickName,
      if (sendHeadImage != null) 'send_head_image': sendHeadImage,
      if (recvId != null) 'recv_id': recvId,
      if (recvNickName != null) 'recv_nick_name': recvNickName,
      if (recvHeadImage != null) 'recv_head_image': recvHeadImage,
      if (remark != null) 'remark': remark,
      if (status != null) 'status': status,
      if (applyTime != null) 'apply_time': applyTime,
    });
  }

  FriendRequestsCompanion copyWith({
    Value<int>? id,
    Value<int?>? sendId,
    Value<String?>? sendNickName,
    Value<String?>? sendHeadImage,
    Value<int?>? recvId,
    Value<String?>? recvNickName,
    Value<String?>? recvHeadImage,
    Value<String?>? remark,
    Value<int>? status,
    Value<int?>? applyTime,
  }) {
    return FriendRequestsCompanion(
      id: id ?? this.id,
      sendId: sendId ?? this.sendId,
      sendNickName: sendNickName ?? this.sendNickName,
      sendHeadImage: sendHeadImage ?? this.sendHeadImage,
      recvId: recvId ?? this.recvId,
      recvNickName: recvNickName ?? this.recvNickName,
      recvHeadImage: recvHeadImage ?? this.recvHeadImage,
      remark: remark ?? this.remark,
      status: status ?? this.status,
      applyTime: applyTime ?? this.applyTime,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sendId.present) {
      map['send_id'] = Variable<int>(sendId.value);
    }
    if (sendNickName.present) {
      map['send_nick_name'] = Variable<String>(sendNickName.value);
    }
    if (sendHeadImage.present) {
      map['send_head_image'] = Variable<String>(sendHeadImage.value);
    }
    if (recvId.present) {
      map['recv_id'] = Variable<int>(recvId.value);
    }
    if (recvNickName.present) {
      map['recv_nick_name'] = Variable<String>(recvNickName.value);
    }
    if (recvHeadImage.present) {
      map['recv_head_image'] = Variable<String>(recvHeadImage.value);
    }
    if (remark.present) {
      map['remark'] = Variable<String>(remark.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(status.value);
    }
    if (applyTime.present) {
      map['apply_time'] = Variable<int>(applyTime.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FriendRequestsCompanion(')
          ..write('id: $id, ')
          ..write('sendId: $sendId, ')
          ..write('sendNickName: $sendNickName, ')
          ..write('sendHeadImage: $sendHeadImage, ')
          ..write('recvId: $recvId, ')
          ..write('recvNickName: $recvNickName, ')
          ..write('recvHeadImage: $recvHeadImage, ')
          ..write('remark: $remark, ')
          ..write('status: $status, ')
          ..write('applyTime: $applyTime')
          ..write(')'))
        .toString();
  }
}

class $SyncCursorsTable extends SyncCursors
    with TableInfo<$SyncCursorsTable, SyncCursor> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncCursorsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<int> value = GeneratedColumn<int>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_cursors';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncCursor> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SyncCursor map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncCursor(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SyncCursorsTable createAlias(String alias) {
    return $SyncCursorsTable(attachedDatabase, alias);
  }
}

class SyncCursor extends DataClass implements Insertable<SyncCursor> {
  final String key;
  final int value;
  const SyncCursor({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<int>(value);
    return map;
  }

  SyncCursorsCompanion toCompanion(bool nullToAbsent) {
    return SyncCursorsCompanion(key: Value(key), value: Value(value));
  }

  factory SyncCursor.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncCursor(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<int>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<int>(value),
    };
  }

  SyncCursor copyWith({String? key, int? value}) =>
      SyncCursor(key: key ?? this.key, value: value ?? this.value);
  SyncCursor copyWithCompanion(SyncCursorsCompanion data) {
    return SyncCursor(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncCursor(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncCursor &&
          other.key == this.key &&
          other.value == this.value);
}

class SyncCursorsCompanion extends UpdateCompanion<SyncCursor> {
  final Value<String> key;
  final Value<int> value;
  final Value<int> rowid;
  const SyncCursorsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncCursorsCompanion.insert({
    required String key,
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key);
  static Insertable<SyncCursor> custom({
    Expression<String>? key,
    Expression<int>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncCursorsCompanion copyWith({
    Value<String>? key,
    Value<int>? value,
    Value<int>? rowid,
  }) {
    return SyncCursorsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<int>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncCursorsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ChatsTable chats = $ChatsTable(this);
  late final $MessagesTable messages = $MessagesTable(this);
  late final $FriendsTable friends = $FriendsTable(this);
  late final $GroupsTable groups = $GroupsTable(this);
  late final $GroupMembersTable groupMembers = $GroupMembersTable(this);
  late final $FriendRequestsTable friendRequests = $FriendRequestsTable(this);
  late final $SyncCursorsTable syncCursors = $SyncCursorsTable(this);
  late final SyncCursorDao syncCursorDao = SyncCursorDao(this as AppDatabase);
  late final ChatDao chatDao = ChatDao(this as AppDatabase);
  late final MessageDao messageDao = MessageDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    chats,
    messages,
    friends,
    groups,
    groupMembers,
    friendRequests,
    syncCursors,
  ];
}

typedef $$ChatsTableCreateCompanionBuilder =
    ChatsCompanion Function({
      Value<int> id,
      required String type,
      required int targetId,
      Value<String?> showName,
      Value<String?> headImage,
      Value<String?> companyName,
      Value<String?> lastContent,
      Value<int?> lastSendTime,
      Value<String?> sendNickName,
      Value<int?> lastMsgType,
      Value<int> unreadCount,
      Value<bool> atMe,
      Value<bool> atAll,
      Value<int> lastAtMessageId,
      Value<bool> isDnd,
      Value<bool> isTop,
      Value<int> lastMsgId,
      Value<bool> messagesLoaded,
    });
typedef $$ChatsTableUpdateCompanionBuilder =
    ChatsCompanion Function({
      Value<int> id,
      Value<String> type,
      Value<int> targetId,
      Value<String?> showName,
      Value<String?> headImage,
      Value<String?> companyName,
      Value<String?> lastContent,
      Value<int?> lastSendTime,
      Value<String?> sendNickName,
      Value<int?> lastMsgType,
      Value<int> unreadCount,
      Value<bool> atMe,
      Value<bool> atAll,
      Value<int> lastAtMessageId,
      Value<bool> isDnd,
      Value<bool> isTop,
      Value<int> lastMsgId,
      Value<bool> messagesLoaded,
    });

class $$ChatsTableFilterComposer extends Composer<_$AppDatabase, $ChatsTable> {
  $$ChatsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetId => $composableBuilder(
    column: $table.targetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get showName => $composableBuilder(
    column: $table.showName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get headImage => $composableBuilder(
    column: $table.headImage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get companyName => $composableBuilder(
    column: $table.companyName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastContent => $composableBuilder(
    column: $table.lastContent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastSendTime => $composableBuilder(
    column: $table.lastSendTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sendNickName => $composableBuilder(
    column: $table.sendNickName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastMsgType => $composableBuilder(
    column: $table.lastMsgType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get atMe => $composableBuilder(
    column: $table.atMe,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get atAll => $composableBuilder(
    column: $table.atAll,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastAtMessageId => $composableBuilder(
    column: $table.lastAtMessageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDnd => $composableBuilder(
    column: $table.isDnd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isTop => $composableBuilder(
    column: $table.isTop,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastMsgId => $composableBuilder(
    column: $table.lastMsgId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get messagesLoaded => $composableBuilder(
    column: $table.messagesLoaded,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ChatsTableOrderingComposer
    extends Composer<_$AppDatabase, $ChatsTable> {
  $$ChatsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetId => $composableBuilder(
    column: $table.targetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get showName => $composableBuilder(
    column: $table.showName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get headImage => $composableBuilder(
    column: $table.headImage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get companyName => $composableBuilder(
    column: $table.companyName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastContent => $composableBuilder(
    column: $table.lastContent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSendTime => $composableBuilder(
    column: $table.lastSendTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sendNickName => $composableBuilder(
    column: $table.sendNickName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastMsgType => $composableBuilder(
    column: $table.lastMsgType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get atMe => $composableBuilder(
    column: $table.atMe,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get atAll => $composableBuilder(
    column: $table.atAll,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastAtMessageId => $composableBuilder(
    column: $table.lastAtMessageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDnd => $composableBuilder(
    column: $table.isDnd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isTop => $composableBuilder(
    column: $table.isTop,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastMsgId => $composableBuilder(
    column: $table.lastMsgId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get messagesLoaded => $composableBuilder(
    column: $table.messagesLoaded,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ChatsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChatsTable> {
  $$ChatsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get targetId =>
      $composableBuilder(column: $table.targetId, builder: (column) => column);

  GeneratedColumn<String> get showName =>
      $composableBuilder(column: $table.showName, builder: (column) => column);

  GeneratedColumn<String> get headImage =>
      $composableBuilder(column: $table.headImage, builder: (column) => column);

  GeneratedColumn<String> get companyName => $composableBuilder(
    column: $table.companyName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastContent => $composableBuilder(
    column: $table.lastContent,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastSendTime => $composableBuilder(
    column: $table.lastSendTime,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sendNickName => $composableBuilder(
    column: $table.sendNickName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastMsgType => $composableBuilder(
    column: $table.lastMsgType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get atMe =>
      $composableBuilder(column: $table.atMe, builder: (column) => column);

  GeneratedColumn<bool> get atAll =>
      $composableBuilder(column: $table.atAll, builder: (column) => column);

  GeneratedColumn<int> get lastAtMessageId => $composableBuilder(
    column: $table.lastAtMessageId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDnd =>
      $composableBuilder(column: $table.isDnd, builder: (column) => column);

  GeneratedColumn<bool> get isTop =>
      $composableBuilder(column: $table.isTop, builder: (column) => column);

  GeneratedColumn<int> get lastMsgId =>
      $composableBuilder(column: $table.lastMsgId, builder: (column) => column);

  GeneratedColumn<bool> get messagesLoaded => $composableBuilder(
    column: $table.messagesLoaded,
    builder: (column) => column,
  );
}

class $$ChatsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChatsTable,
          Chat,
          $$ChatsTableFilterComposer,
          $$ChatsTableOrderingComposer,
          $$ChatsTableAnnotationComposer,
          $$ChatsTableCreateCompanionBuilder,
          $$ChatsTableUpdateCompanionBuilder,
          (Chat, BaseReferences<_$AppDatabase, $ChatsTable, Chat>),
          Chat,
          PrefetchHooks Function()
        > {
  $$ChatsTableTableManager(_$AppDatabase db, $ChatsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChatsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChatsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChatsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int> targetId = const Value.absent(),
                Value<String?> showName = const Value.absent(),
                Value<String?> headImage = const Value.absent(),
                Value<String?> companyName = const Value.absent(),
                Value<String?> lastContent = const Value.absent(),
                Value<int?> lastSendTime = const Value.absent(),
                Value<String?> sendNickName = const Value.absent(),
                Value<int?> lastMsgType = const Value.absent(),
                Value<int> unreadCount = const Value.absent(),
                Value<bool> atMe = const Value.absent(),
                Value<bool> atAll = const Value.absent(),
                Value<int> lastAtMessageId = const Value.absent(),
                Value<bool> isDnd = const Value.absent(),
                Value<bool> isTop = const Value.absent(),
                Value<int> lastMsgId = const Value.absent(),
                Value<bool> messagesLoaded = const Value.absent(),
              }) => ChatsCompanion(
                id: id,
                type: type,
                targetId: targetId,
                showName: showName,
                headImage: headImage,
                companyName: companyName,
                lastContent: lastContent,
                lastSendTime: lastSendTime,
                sendNickName: sendNickName,
                lastMsgType: lastMsgType,
                unreadCount: unreadCount,
                atMe: atMe,
                atAll: atAll,
                lastAtMessageId: lastAtMessageId,
                isDnd: isDnd,
                isTop: isTop,
                lastMsgId: lastMsgId,
                messagesLoaded: messagesLoaded,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String type,
                required int targetId,
                Value<String?> showName = const Value.absent(),
                Value<String?> headImage = const Value.absent(),
                Value<String?> companyName = const Value.absent(),
                Value<String?> lastContent = const Value.absent(),
                Value<int?> lastSendTime = const Value.absent(),
                Value<String?> sendNickName = const Value.absent(),
                Value<int?> lastMsgType = const Value.absent(),
                Value<int> unreadCount = const Value.absent(),
                Value<bool> atMe = const Value.absent(),
                Value<bool> atAll = const Value.absent(),
                Value<int> lastAtMessageId = const Value.absent(),
                Value<bool> isDnd = const Value.absent(),
                Value<bool> isTop = const Value.absent(),
                Value<int> lastMsgId = const Value.absent(),
                Value<bool> messagesLoaded = const Value.absent(),
              }) => ChatsCompanion.insert(
                id: id,
                type: type,
                targetId: targetId,
                showName: showName,
                headImage: headImage,
                companyName: companyName,
                lastContent: lastContent,
                lastSendTime: lastSendTime,
                sendNickName: sendNickName,
                lastMsgType: lastMsgType,
                unreadCount: unreadCount,
                atMe: atMe,
                atAll: atAll,
                lastAtMessageId: lastAtMessageId,
                isDnd: isDnd,
                isTop: isTop,
                lastMsgId: lastMsgId,
                messagesLoaded: messagesLoaded,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ChatsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChatsTable,
      Chat,
      $$ChatsTableFilterComposer,
      $$ChatsTableOrderingComposer,
      $$ChatsTableAnnotationComposer,
      $$ChatsTableCreateCompanionBuilder,
      $$ChatsTableUpdateCompanionBuilder,
      (Chat, BaseReferences<_$AppDatabase, $ChatsTable, Chat>),
      Chat,
      PrefetchHooks Function()
    >;
typedef $$MessagesTableCreateCompanionBuilder =
    MessagesCompanion Function({
      Value<int> rowId,
      Value<int?> id,
      Value<String?> tmpId,
      required String chatType,
      required int chatTargetId,
      Value<int?> sendId,
      Value<int?> recvId,
      Value<int?> groupId,
      required int type,
      Value<String?> content,
      required int status,
      Value<int?> sendTime,
      Value<String?> sendNickName,
      Value<String?> atUserIds,
      Value<String?> quoteMessage,
      Value<bool> receipt,
      Value<bool> receiptOk,
      Value<int> readedCount,
      Value<bool> selfSend,
      Value<int?> seqNo,
    });
typedef $$MessagesTableUpdateCompanionBuilder =
    MessagesCompanion Function({
      Value<int> rowId,
      Value<int?> id,
      Value<String?> tmpId,
      Value<String> chatType,
      Value<int> chatTargetId,
      Value<int?> sendId,
      Value<int?> recvId,
      Value<int?> groupId,
      Value<int> type,
      Value<String?> content,
      Value<int> status,
      Value<int?> sendTime,
      Value<String?> sendNickName,
      Value<String?> atUserIds,
      Value<String?> quoteMessage,
      Value<bool> receipt,
      Value<bool> receiptOk,
      Value<int> readedCount,
      Value<bool> selfSend,
      Value<int?> seqNo,
    });

class $$MessagesTableFilterComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tmpId => $composableBuilder(
    column: $table.tmpId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get chatType => $composableBuilder(
    column: $table.chatType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get chatTargetId => $composableBuilder(
    column: $table.chatTargetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sendId => $composableBuilder(
    column: $table.sendId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recvId => $composableBuilder(
    column: $table.recvId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sendTime => $composableBuilder(
    column: $table.sendTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sendNickName => $composableBuilder(
    column: $table.sendNickName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get atUserIds => $composableBuilder(
    column: $table.atUserIds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get quoteMessage => $composableBuilder(
    column: $table.quoteMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get receipt => $composableBuilder(
    column: $table.receipt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get receiptOk => $composableBuilder(
    column: $table.receiptOk,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get readedCount => $composableBuilder(
    column: $table.readedCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get selfSend => $composableBuilder(
    column: $table.selfSend,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seqNo => $composableBuilder(
    column: $table.seqNo,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tmpId => $composableBuilder(
    column: $table.tmpId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get chatType => $composableBuilder(
    column: $table.chatType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get chatTargetId => $composableBuilder(
    column: $table.chatTargetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sendId => $composableBuilder(
    column: $table.sendId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recvId => $composableBuilder(
    column: $table.recvId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sendTime => $composableBuilder(
    column: $table.sendTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sendNickName => $composableBuilder(
    column: $table.sendNickName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get atUserIds => $composableBuilder(
    column: $table.atUserIds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quoteMessage => $composableBuilder(
    column: $table.quoteMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get receipt => $composableBuilder(
    column: $table.receipt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get receiptOk => $composableBuilder(
    column: $table.receiptOk,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get readedCount => $composableBuilder(
    column: $table.readedCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get selfSend => $composableBuilder(
    column: $table.selfSend,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seqNo => $composableBuilder(
    column: $table.seqNo,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get rowId =>
      $composableBuilder(column: $table.rowId, builder: (column) => column);

  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tmpId =>
      $composableBuilder(column: $table.tmpId, builder: (column) => column);

  GeneratedColumn<String> get chatType =>
      $composableBuilder(column: $table.chatType, builder: (column) => column);

  GeneratedColumn<int> get chatTargetId => $composableBuilder(
    column: $table.chatTargetId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sendId =>
      $composableBuilder(column: $table.sendId, builder: (column) => column);

  GeneratedColumn<int> get recvId =>
      $composableBuilder(column: $table.recvId, builder: (column) => column);

  GeneratedColumn<int> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get sendTime =>
      $composableBuilder(column: $table.sendTime, builder: (column) => column);

  GeneratedColumn<String> get sendNickName => $composableBuilder(
    column: $table.sendNickName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get atUserIds =>
      $composableBuilder(column: $table.atUserIds, builder: (column) => column);

  GeneratedColumn<String> get quoteMessage => $composableBuilder(
    column: $table.quoteMessage,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get receipt =>
      $composableBuilder(column: $table.receipt, builder: (column) => column);

  GeneratedColumn<bool> get receiptOk =>
      $composableBuilder(column: $table.receiptOk, builder: (column) => column);

  GeneratedColumn<int> get readedCount => $composableBuilder(
    column: $table.readedCount,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get selfSend =>
      $composableBuilder(column: $table.selfSend, builder: (column) => column);

  GeneratedColumn<int> get seqNo =>
      $composableBuilder(column: $table.seqNo, builder: (column) => column);
}

class $$MessagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MessagesTable,
          Message,
          $$MessagesTableFilterComposer,
          $$MessagesTableOrderingComposer,
          $$MessagesTableAnnotationComposer,
          $$MessagesTableCreateCompanionBuilder,
          $$MessagesTableUpdateCompanionBuilder,
          (Message, BaseReferences<_$AppDatabase, $MessagesTable, Message>),
          Message,
          PrefetchHooks Function()
        > {
  $$MessagesTableTableManager(_$AppDatabase db, $MessagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> rowId = const Value.absent(),
                Value<int?> id = const Value.absent(),
                Value<String?> tmpId = const Value.absent(),
                Value<String> chatType = const Value.absent(),
                Value<int> chatTargetId = const Value.absent(),
                Value<int?> sendId = const Value.absent(),
                Value<int?> recvId = const Value.absent(),
                Value<int?> groupId = const Value.absent(),
                Value<int> type = const Value.absent(),
                Value<String?> content = const Value.absent(),
                Value<int> status = const Value.absent(),
                Value<int?> sendTime = const Value.absent(),
                Value<String?> sendNickName = const Value.absent(),
                Value<String?> atUserIds = const Value.absent(),
                Value<String?> quoteMessage = const Value.absent(),
                Value<bool> receipt = const Value.absent(),
                Value<bool> receiptOk = const Value.absent(),
                Value<int> readedCount = const Value.absent(),
                Value<bool> selfSend = const Value.absent(),
                Value<int?> seqNo = const Value.absent(),
              }) => MessagesCompanion(
                rowId: rowId,
                id: id,
                tmpId: tmpId,
                chatType: chatType,
                chatTargetId: chatTargetId,
                sendId: sendId,
                recvId: recvId,
                groupId: groupId,
                type: type,
                content: content,
                status: status,
                sendTime: sendTime,
                sendNickName: sendNickName,
                atUserIds: atUserIds,
                quoteMessage: quoteMessage,
                receipt: receipt,
                receiptOk: receiptOk,
                readedCount: readedCount,
                selfSend: selfSend,
                seqNo: seqNo,
              ),
          createCompanionCallback:
              ({
                Value<int> rowId = const Value.absent(),
                Value<int?> id = const Value.absent(),
                Value<String?> tmpId = const Value.absent(),
                required String chatType,
                required int chatTargetId,
                Value<int?> sendId = const Value.absent(),
                Value<int?> recvId = const Value.absent(),
                Value<int?> groupId = const Value.absent(),
                required int type,
                Value<String?> content = const Value.absent(),
                required int status,
                Value<int?> sendTime = const Value.absent(),
                Value<String?> sendNickName = const Value.absent(),
                Value<String?> atUserIds = const Value.absent(),
                Value<String?> quoteMessage = const Value.absent(),
                Value<bool> receipt = const Value.absent(),
                Value<bool> receiptOk = const Value.absent(),
                Value<int> readedCount = const Value.absent(),
                Value<bool> selfSend = const Value.absent(),
                Value<int?> seqNo = const Value.absent(),
              }) => MessagesCompanion.insert(
                rowId: rowId,
                id: id,
                tmpId: tmpId,
                chatType: chatType,
                chatTargetId: chatTargetId,
                sendId: sendId,
                recvId: recvId,
                groupId: groupId,
                type: type,
                content: content,
                status: status,
                sendTime: sendTime,
                sendNickName: sendNickName,
                atUserIds: atUserIds,
                quoteMessage: quoteMessage,
                receipt: receipt,
                receiptOk: receiptOk,
                readedCount: readedCount,
                selfSend: selfSend,
                seqNo: seqNo,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MessagesTable,
      Message,
      $$MessagesTableFilterComposer,
      $$MessagesTableOrderingComposer,
      $$MessagesTableAnnotationComposer,
      $$MessagesTableCreateCompanionBuilder,
      $$MessagesTableUpdateCompanionBuilder,
      (Message, BaseReferences<_$AppDatabase, $MessagesTable, Message>),
      Message,
      PrefetchHooks Function()
    >;
typedef $$FriendsTableCreateCompanionBuilder =
    FriendsCompanion Function({
      Value<int> id,
      Value<String?> nickName,
      Value<String?> showNickName,
      Value<String?> remarkNickName,
      Value<String?> headImage,
      Value<String?> companyName,
      Value<bool> isDnd,
      Value<bool> isTop,
      Value<bool> deleted,
      Value<bool> online,
      Value<bool> onlineWeb,
      Value<bool> onlineApp,
    });
typedef $$FriendsTableUpdateCompanionBuilder =
    FriendsCompanion Function({
      Value<int> id,
      Value<String?> nickName,
      Value<String?> showNickName,
      Value<String?> remarkNickName,
      Value<String?> headImage,
      Value<String?> companyName,
      Value<bool> isDnd,
      Value<bool> isTop,
      Value<bool> deleted,
      Value<bool> online,
      Value<bool> onlineWeb,
      Value<bool> onlineApp,
    });

class $$FriendsTableFilterComposer
    extends Composer<_$AppDatabase, $FriendsTable> {
  $$FriendsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nickName => $composableBuilder(
    column: $table.nickName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get showNickName => $composableBuilder(
    column: $table.showNickName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remarkNickName => $composableBuilder(
    column: $table.remarkNickName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get headImage => $composableBuilder(
    column: $table.headImage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get companyName => $composableBuilder(
    column: $table.companyName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDnd => $composableBuilder(
    column: $table.isDnd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isTop => $composableBuilder(
    column: $table.isTop,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get online => $composableBuilder(
    column: $table.online,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get onlineWeb => $composableBuilder(
    column: $table.onlineWeb,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get onlineApp => $composableBuilder(
    column: $table.onlineApp,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FriendsTableOrderingComposer
    extends Composer<_$AppDatabase, $FriendsTable> {
  $$FriendsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nickName => $composableBuilder(
    column: $table.nickName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get showNickName => $composableBuilder(
    column: $table.showNickName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remarkNickName => $composableBuilder(
    column: $table.remarkNickName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get headImage => $composableBuilder(
    column: $table.headImage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get companyName => $composableBuilder(
    column: $table.companyName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDnd => $composableBuilder(
    column: $table.isDnd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isTop => $composableBuilder(
    column: $table.isTop,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get online => $composableBuilder(
    column: $table.online,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get onlineWeb => $composableBuilder(
    column: $table.onlineWeb,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get onlineApp => $composableBuilder(
    column: $table.onlineApp,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FriendsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FriendsTable> {
  $$FriendsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nickName =>
      $composableBuilder(column: $table.nickName, builder: (column) => column);

  GeneratedColumn<String> get showNickName => $composableBuilder(
    column: $table.showNickName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remarkNickName => $composableBuilder(
    column: $table.remarkNickName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get headImage =>
      $composableBuilder(column: $table.headImage, builder: (column) => column);

  GeneratedColumn<String> get companyName => $composableBuilder(
    column: $table.companyName,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDnd =>
      $composableBuilder(column: $table.isDnd, builder: (column) => column);

  GeneratedColumn<bool> get isTop =>
      $composableBuilder(column: $table.isTop, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<bool> get online =>
      $composableBuilder(column: $table.online, builder: (column) => column);

  GeneratedColumn<bool> get onlineWeb =>
      $composableBuilder(column: $table.onlineWeb, builder: (column) => column);

  GeneratedColumn<bool> get onlineApp =>
      $composableBuilder(column: $table.onlineApp, builder: (column) => column);
}

class $$FriendsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FriendsTable,
          Friend,
          $$FriendsTableFilterComposer,
          $$FriendsTableOrderingComposer,
          $$FriendsTableAnnotationComposer,
          $$FriendsTableCreateCompanionBuilder,
          $$FriendsTableUpdateCompanionBuilder,
          (Friend, BaseReferences<_$AppDatabase, $FriendsTable, Friend>),
          Friend,
          PrefetchHooks Function()
        > {
  $$FriendsTableTableManager(_$AppDatabase db, $FriendsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FriendsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FriendsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FriendsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> nickName = const Value.absent(),
                Value<String?> showNickName = const Value.absent(),
                Value<String?> remarkNickName = const Value.absent(),
                Value<String?> headImage = const Value.absent(),
                Value<String?> companyName = const Value.absent(),
                Value<bool> isDnd = const Value.absent(),
                Value<bool> isTop = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<bool> online = const Value.absent(),
                Value<bool> onlineWeb = const Value.absent(),
                Value<bool> onlineApp = const Value.absent(),
              }) => FriendsCompanion(
                id: id,
                nickName: nickName,
                showNickName: showNickName,
                remarkNickName: remarkNickName,
                headImage: headImage,
                companyName: companyName,
                isDnd: isDnd,
                isTop: isTop,
                deleted: deleted,
                online: online,
                onlineWeb: onlineWeb,
                onlineApp: onlineApp,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> nickName = const Value.absent(),
                Value<String?> showNickName = const Value.absent(),
                Value<String?> remarkNickName = const Value.absent(),
                Value<String?> headImage = const Value.absent(),
                Value<String?> companyName = const Value.absent(),
                Value<bool> isDnd = const Value.absent(),
                Value<bool> isTop = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<bool> online = const Value.absent(),
                Value<bool> onlineWeb = const Value.absent(),
                Value<bool> onlineApp = const Value.absent(),
              }) => FriendsCompanion.insert(
                id: id,
                nickName: nickName,
                showNickName: showNickName,
                remarkNickName: remarkNickName,
                headImage: headImage,
                companyName: companyName,
                isDnd: isDnd,
                isTop: isTop,
                deleted: deleted,
                online: online,
                onlineWeb: onlineWeb,
                onlineApp: onlineApp,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FriendsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FriendsTable,
      Friend,
      $$FriendsTableFilterComposer,
      $$FriendsTableOrderingComposer,
      $$FriendsTableAnnotationComposer,
      $$FriendsTableCreateCompanionBuilder,
      $$FriendsTableUpdateCompanionBuilder,
      (Friend, BaseReferences<_$AppDatabase, $FriendsTable, Friend>),
      Friend,
      PrefetchHooks Function()
    >;
typedef $$GroupsTableCreateCompanionBuilder =
    GroupsCompanion Function({
      Value<int> id,
      Value<String?> name,
      Value<int?> ownerId,
      Value<String?> headImage,
      Value<String?> headImageThumb,
      Value<String?> notice,
      Value<String?> remarkNickName,
      Value<String?> showNickName,
      Value<String?> showGroupName,
      Value<String?> remarkGroupName,
      Value<bool> isAllMuted,
      Value<bool> isAllowInvite,
      Value<bool> isAllowShareCard,
      Value<bool> dissolve,
      Value<bool> quit,
      Value<bool> isMuted,
      Value<bool> isBanned,
      Value<String?> reason,
      Value<bool> isDnd,
      Value<bool> isTop,
      Value<String?> topMessage,
    });
typedef $$GroupsTableUpdateCompanionBuilder =
    GroupsCompanion Function({
      Value<int> id,
      Value<String?> name,
      Value<int?> ownerId,
      Value<String?> headImage,
      Value<String?> headImageThumb,
      Value<String?> notice,
      Value<String?> remarkNickName,
      Value<String?> showNickName,
      Value<String?> showGroupName,
      Value<String?> remarkGroupName,
      Value<bool> isAllMuted,
      Value<bool> isAllowInvite,
      Value<bool> isAllowShareCard,
      Value<bool> dissolve,
      Value<bool> quit,
      Value<bool> isMuted,
      Value<bool> isBanned,
      Value<String?> reason,
      Value<bool> isDnd,
      Value<bool> isTop,
      Value<String?> topMessage,
    });

class $$GroupsTableFilterComposer
    extends Composer<_$AppDatabase, $GroupsTable> {
  $$GroupsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get headImage => $composableBuilder(
    column: $table.headImage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get headImageThumb => $composableBuilder(
    column: $table.headImageThumb,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notice => $composableBuilder(
    column: $table.notice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remarkNickName => $composableBuilder(
    column: $table.remarkNickName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get showNickName => $composableBuilder(
    column: $table.showNickName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get showGroupName => $composableBuilder(
    column: $table.showGroupName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remarkGroupName => $composableBuilder(
    column: $table.remarkGroupName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isAllMuted => $composableBuilder(
    column: $table.isAllMuted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isAllowInvite => $composableBuilder(
    column: $table.isAllowInvite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isAllowShareCard => $composableBuilder(
    column: $table.isAllowShareCard,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get dissolve => $composableBuilder(
    column: $table.dissolve,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get quit => $composableBuilder(
    column: $table.quit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isMuted => $composableBuilder(
    column: $table.isMuted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isBanned => $composableBuilder(
    column: $table.isBanned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDnd => $composableBuilder(
    column: $table.isDnd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isTop => $composableBuilder(
    column: $table.isTop,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get topMessage => $composableBuilder(
    column: $table.topMessage,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GroupsTableOrderingComposer
    extends Composer<_$AppDatabase, $GroupsTable> {
  $$GroupsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get headImage => $composableBuilder(
    column: $table.headImage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get headImageThumb => $composableBuilder(
    column: $table.headImageThumb,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notice => $composableBuilder(
    column: $table.notice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remarkNickName => $composableBuilder(
    column: $table.remarkNickName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get showNickName => $composableBuilder(
    column: $table.showNickName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get showGroupName => $composableBuilder(
    column: $table.showGroupName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remarkGroupName => $composableBuilder(
    column: $table.remarkGroupName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isAllMuted => $composableBuilder(
    column: $table.isAllMuted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isAllowInvite => $composableBuilder(
    column: $table.isAllowInvite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isAllowShareCard => $composableBuilder(
    column: $table.isAllowShareCard,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get dissolve => $composableBuilder(
    column: $table.dissolve,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get quit => $composableBuilder(
    column: $table.quit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isMuted => $composableBuilder(
    column: $table.isMuted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isBanned => $composableBuilder(
    column: $table.isBanned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDnd => $composableBuilder(
    column: $table.isDnd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isTop => $composableBuilder(
    column: $table.isTop,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get topMessage => $composableBuilder(
    column: $table.topMessage,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GroupsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GroupsTable> {
  $$GroupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get headImage =>
      $composableBuilder(column: $table.headImage, builder: (column) => column);

  GeneratedColumn<String> get headImageThumb => $composableBuilder(
    column: $table.headImageThumb,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notice =>
      $composableBuilder(column: $table.notice, builder: (column) => column);

  GeneratedColumn<String> get remarkNickName => $composableBuilder(
    column: $table.remarkNickName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get showNickName => $composableBuilder(
    column: $table.showNickName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get showGroupName => $composableBuilder(
    column: $table.showGroupName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remarkGroupName => $composableBuilder(
    column: $table.remarkGroupName,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isAllMuted => $composableBuilder(
    column: $table.isAllMuted,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isAllowInvite => $composableBuilder(
    column: $table.isAllowInvite,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isAllowShareCard => $composableBuilder(
    column: $table.isAllowShareCard,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get dissolve =>
      $composableBuilder(column: $table.dissolve, builder: (column) => column);

  GeneratedColumn<bool> get quit =>
      $composableBuilder(column: $table.quit, builder: (column) => column);

  GeneratedColumn<bool> get isMuted =>
      $composableBuilder(column: $table.isMuted, builder: (column) => column);

  GeneratedColumn<bool> get isBanned =>
      $composableBuilder(column: $table.isBanned, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<bool> get isDnd =>
      $composableBuilder(column: $table.isDnd, builder: (column) => column);

  GeneratedColumn<bool> get isTop =>
      $composableBuilder(column: $table.isTop, builder: (column) => column);

  GeneratedColumn<String> get topMessage => $composableBuilder(
    column: $table.topMessage,
    builder: (column) => column,
  );
}

class $$GroupsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GroupsTable,
          Group,
          $$GroupsTableFilterComposer,
          $$GroupsTableOrderingComposer,
          $$GroupsTableAnnotationComposer,
          $$GroupsTableCreateCompanionBuilder,
          $$GroupsTableUpdateCompanionBuilder,
          (Group, BaseReferences<_$AppDatabase, $GroupsTable, Group>),
          Group,
          PrefetchHooks Function()
        > {
  $$GroupsTableTableManager(_$AppDatabase db, $GroupsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GroupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GroupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GroupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<int?> ownerId = const Value.absent(),
                Value<String?> headImage = const Value.absent(),
                Value<String?> headImageThumb = const Value.absent(),
                Value<String?> notice = const Value.absent(),
                Value<String?> remarkNickName = const Value.absent(),
                Value<String?> showNickName = const Value.absent(),
                Value<String?> showGroupName = const Value.absent(),
                Value<String?> remarkGroupName = const Value.absent(),
                Value<bool> isAllMuted = const Value.absent(),
                Value<bool> isAllowInvite = const Value.absent(),
                Value<bool> isAllowShareCard = const Value.absent(),
                Value<bool> dissolve = const Value.absent(),
                Value<bool> quit = const Value.absent(),
                Value<bool> isMuted = const Value.absent(),
                Value<bool> isBanned = const Value.absent(),
                Value<String?> reason = const Value.absent(),
                Value<bool> isDnd = const Value.absent(),
                Value<bool> isTop = const Value.absent(),
                Value<String?> topMessage = const Value.absent(),
              }) => GroupsCompanion(
                id: id,
                name: name,
                ownerId: ownerId,
                headImage: headImage,
                headImageThumb: headImageThumb,
                notice: notice,
                remarkNickName: remarkNickName,
                showNickName: showNickName,
                showGroupName: showGroupName,
                remarkGroupName: remarkGroupName,
                isAllMuted: isAllMuted,
                isAllowInvite: isAllowInvite,
                isAllowShareCard: isAllowShareCard,
                dissolve: dissolve,
                quit: quit,
                isMuted: isMuted,
                isBanned: isBanned,
                reason: reason,
                isDnd: isDnd,
                isTop: isTop,
                topMessage: topMessage,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<int?> ownerId = const Value.absent(),
                Value<String?> headImage = const Value.absent(),
                Value<String?> headImageThumb = const Value.absent(),
                Value<String?> notice = const Value.absent(),
                Value<String?> remarkNickName = const Value.absent(),
                Value<String?> showNickName = const Value.absent(),
                Value<String?> showGroupName = const Value.absent(),
                Value<String?> remarkGroupName = const Value.absent(),
                Value<bool> isAllMuted = const Value.absent(),
                Value<bool> isAllowInvite = const Value.absent(),
                Value<bool> isAllowShareCard = const Value.absent(),
                Value<bool> dissolve = const Value.absent(),
                Value<bool> quit = const Value.absent(),
                Value<bool> isMuted = const Value.absent(),
                Value<bool> isBanned = const Value.absent(),
                Value<String?> reason = const Value.absent(),
                Value<bool> isDnd = const Value.absent(),
                Value<bool> isTop = const Value.absent(),
                Value<String?> topMessage = const Value.absent(),
              }) => GroupsCompanion.insert(
                id: id,
                name: name,
                ownerId: ownerId,
                headImage: headImage,
                headImageThumb: headImageThumb,
                notice: notice,
                remarkNickName: remarkNickName,
                showNickName: showNickName,
                showGroupName: showGroupName,
                remarkGroupName: remarkGroupName,
                isAllMuted: isAllMuted,
                isAllowInvite: isAllowInvite,
                isAllowShareCard: isAllowShareCard,
                dissolve: dissolve,
                quit: quit,
                isMuted: isMuted,
                isBanned: isBanned,
                reason: reason,
                isDnd: isDnd,
                isTop: isTop,
                topMessage: topMessage,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GroupsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GroupsTable,
      Group,
      $$GroupsTableFilterComposer,
      $$GroupsTableOrderingComposer,
      $$GroupsTableAnnotationComposer,
      $$GroupsTableCreateCompanionBuilder,
      $$GroupsTableUpdateCompanionBuilder,
      (Group, BaseReferences<_$AppDatabase, $GroupsTable, Group>),
      Group,
      PrefetchHooks Function()
    >;
typedef $$GroupMembersTableCreateCompanionBuilder =
    GroupMembersCompanion Function({
      required int groupId,
      required int userId,
      Value<String?> showNickName,
      Value<String?> remarkNickName,
      Value<String?> headImage,
      Value<String?> companyName,
      Value<bool> isManager,
      Value<bool> isMuted,
      Value<bool> quit,
      Value<bool> online,
      Value<String?> showGroupName,
      Value<String?> remarkGroupName,
      Value<int> version,
      Value<int> rowid,
    });
typedef $$GroupMembersTableUpdateCompanionBuilder =
    GroupMembersCompanion Function({
      Value<int> groupId,
      Value<int> userId,
      Value<String?> showNickName,
      Value<String?> remarkNickName,
      Value<String?> headImage,
      Value<String?> companyName,
      Value<bool> isManager,
      Value<bool> isMuted,
      Value<bool> quit,
      Value<bool> online,
      Value<String?> showGroupName,
      Value<String?> remarkGroupName,
      Value<int> version,
      Value<int> rowid,
    });

class $$GroupMembersTableFilterComposer
    extends Composer<_$AppDatabase, $GroupMembersTable> {
  $$GroupMembersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get showNickName => $composableBuilder(
    column: $table.showNickName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remarkNickName => $composableBuilder(
    column: $table.remarkNickName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get headImage => $composableBuilder(
    column: $table.headImage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get companyName => $composableBuilder(
    column: $table.companyName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isManager => $composableBuilder(
    column: $table.isManager,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isMuted => $composableBuilder(
    column: $table.isMuted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get quit => $composableBuilder(
    column: $table.quit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get online => $composableBuilder(
    column: $table.online,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get showGroupName => $composableBuilder(
    column: $table.showGroupName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remarkGroupName => $composableBuilder(
    column: $table.remarkGroupName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GroupMembersTableOrderingComposer
    extends Composer<_$AppDatabase, $GroupMembersTable> {
  $$GroupMembersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get showNickName => $composableBuilder(
    column: $table.showNickName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remarkNickName => $composableBuilder(
    column: $table.remarkNickName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get headImage => $composableBuilder(
    column: $table.headImage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get companyName => $composableBuilder(
    column: $table.companyName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isManager => $composableBuilder(
    column: $table.isManager,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isMuted => $composableBuilder(
    column: $table.isMuted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get quit => $composableBuilder(
    column: $table.quit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get online => $composableBuilder(
    column: $table.online,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get showGroupName => $composableBuilder(
    column: $table.showGroupName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remarkGroupName => $composableBuilder(
    column: $table.remarkGroupName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GroupMembersTableAnnotationComposer
    extends Composer<_$AppDatabase, $GroupMembersTable> {
  $$GroupMembersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<int> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get showNickName => $composableBuilder(
    column: $table.showNickName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remarkNickName => $composableBuilder(
    column: $table.remarkNickName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get headImage =>
      $composableBuilder(column: $table.headImage, builder: (column) => column);

  GeneratedColumn<String> get companyName => $composableBuilder(
    column: $table.companyName,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isManager =>
      $composableBuilder(column: $table.isManager, builder: (column) => column);

  GeneratedColumn<bool> get isMuted =>
      $composableBuilder(column: $table.isMuted, builder: (column) => column);

  GeneratedColumn<bool> get quit =>
      $composableBuilder(column: $table.quit, builder: (column) => column);

  GeneratedColumn<bool> get online =>
      $composableBuilder(column: $table.online, builder: (column) => column);

  GeneratedColumn<String> get showGroupName => $composableBuilder(
    column: $table.showGroupName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remarkGroupName => $composableBuilder(
    column: $table.remarkGroupName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);
}

class $$GroupMembersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GroupMembersTable,
          GroupMember,
          $$GroupMembersTableFilterComposer,
          $$GroupMembersTableOrderingComposer,
          $$GroupMembersTableAnnotationComposer,
          $$GroupMembersTableCreateCompanionBuilder,
          $$GroupMembersTableUpdateCompanionBuilder,
          (
            GroupMember,
            BaseReferences<_$AppDatabase, $GroupMembersTable, GroupMember>,
          ),
          GroupMember,
          PrefetchHooks Function()
        > {
  $$GroupMembersTableTableManager(_$AppDatabase db, $GroupMembersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GroupMembersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GroupMembersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GroupMembersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> groupId = const Value.absent(),
                Value<int> userId = const Value.absent(),
                Value<String?> showNickName = const Value.absent(),
                Value<String?> remarkNickName = const Value.absent(),
                Value<String?> headImage = const Value.absent(),
                Value<String?> companyName = const Value.absent(),
                Value<bool> isManager = const Value.absent(),
                Value<bool> isMuted = const Value.absent(),
                Value<bool> quit = const Value.absent(),
                Value<bool> online = const Value.absent(),
                Value<String?> showGroupName = const Value.absent(),
                Value<String?> remarkGroupName = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GroupMembersCompanion(
                groupId: groupId,
                userId: userId,
                showNickName: showNickName,
                remarkNickName: remarkNickName,
                headImage: headImage,
                companyName: companyName,
                isManager: isManager,
                isMuted: isMuted,
                quit: quit,
                online: online,
                showGroupName: showGroupName,
                remarkGroupName: remarkGroupName,
                version: version,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int groupId,
                required int userId,
                Value<String?> showNickName = const Value.absent(),
                Value<String?> remarkNickName = const Value.absent(),
                Value<String?> headImage = const Value.absent(),
                Value<String?> companyName = const Value.absent(),
                Value<bool> isManager = const Value.absent(),
                Value<bool> isMuted = const Value.absent(),
                Value<bool> quit = const Value.absent(),
                Value<bool> online = const Value.absent(),
                Value<String?> showGroupName = const Value.absent(),
                Value<String?> remarkGroupName = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GroupMembersCompanion.insert(
                groupId: groupId,
                userId: userId,
                showNickName: showNickName,
                remarkNickName: remarkNickName,
                headImage: headImage,
                companyName: companyName,
                isManager: isManager,
                isMuted: isMuted,
                quit: quit,
                online: online,
                showGroupName: showGroupName,
                remarkGroupName: remarkGroupName,
                version: version,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GroupMembersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GroupMembersTable,
      GroupMember,
      $$GroupMembersTableFilterComposer,
      $$GroupMembersTableOrderingComposer,
      $$GroupMembersTableAnnotationComposer,
      $$GroupMembersTableCreateCompanionBuilder,
      $$GroupMembersTableUpdateCompanionBuilder,
      (
        GroupMember,
        BaseReferences<_$AppDatabase, $GroupMembersTable, GroupMember>,
      ),
      GroupMember,
      PrefetchHooks Function()
    >;
typedef $$FriendRequestsTableCreateCompanionBuilder =
    FriendRequestsCompanion Function({
      Value<int> id,
      Value<int?> sendId,
      Value<String?> sendNickName,
      Value<String?> sendHeadImage,
      Value<int?> recvId,
      Value<String?> recvNickName,
      Value<String?> recvHeadImage,
      Value<String?> remark,
      Value<int> status,
      Value<int?> applyTime,
    });
typedef $$FriendRequestsTableUpdateCompanionBuilder =
    FriendRequestsCompanion Function({
      Value<int> id,
      Value<int?> sendId,
      Value<String?> sendNickName,
      Value<String?> sendHeadImage,
      Value<int?> recvId,
      Value<String?> recvNickName,
      Value<String?> recvHeadImage,
      Value<String?> remark,
      Value<int> status,
      Value<int?> applyTime,
    });

class $$FriendRequestsTableFilterComposer
    extends Composer<_$AppDatabase, $FriendRequestsTable> {
  $$FriendRequestsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sendId => $composableBuilder(
    column: $table.sendId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sendNickName => $composableBuilder(
    column: $table.sendNickName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sendHeadImage => $composableBuilder(
    column: $table.sendHeadImage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recvId => $composableBuilder(
    column: $table.recvId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recvNickName => $composableBuilder(
    column: $table.recvNickName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recvHeadImage => $composableBuilder(
    column: $table.recvHeadImage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remark => $composableBuilder(
    column: $table.remark,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get applyTime => $composableBuilder(
    column: $table.applyTime,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FriendRequestsTableOrderingComposer
    extends Composer<_$AppDatabase, $FriendRequestsTable> {
  $$FriendRequestsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sendId => $composableBuilder(
    column: $table.sendId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sendNickName => $composableBuilder(
    column: $table.sendNickName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sendHeadImage => $composableBuilder(
    column: $table.sendHeadImage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recvId => $composableBuilder(
    column: $table.recvId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recvNickName => $composableBuilder(
    column: $table.recvNickName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recvHeadImage => $composableBuilder(
    column: $table.recvHeadImage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remark => $composableBuilder(
    column: $table.remark,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get applyTime => $composableBuilder(
    column: $table.applyTime,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FriendRequestsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FriendRequestsTable> {
  $$FriendRequestsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get sendId =>
      $composableBuilder(column: $table.sendId, builder: (column) => column);

  GeneratedColumn<String> get sendNickName => $composableBuilder(
    column: $table.sendNickName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sendHeadImage => $composableBuilder(
    column: $table.sendHeadImage,
    builder: (column) => column,
  );

  GeneratedColumn<int> get recvId =>
      $composableBuilder(column: $table.recvId, builder: (column) => column);

  GeneratedColumn<String> get recvNickName => $composableBuilder(
    column: $table.recvNickName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recvHeadImage => $composableBuilder(
    column: $table.recvHeadImage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remark =>
      $composableBuilder(column: $table.remark, builder: (column) => column);

  GeneratedColumn<int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get applyTime =>
      $composableBuilder(column: $table.applyTime, builder: (column) => column);
}

class $$FriendRequestsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FriendRequestsTable,
          FriendRequest,
          $$FriendRequestsTableFilterComposer,
          $$FriendRequestsTableOrderingComposer,
          $$FriendRequestsTableAnnotationComposer,
          $$FriendRequestsTableCreateCompanionBuilder,
          $$FriendRequestsTableUpdateCompanionBuilder,
          (
            FriendRequest,
            BaseReferences<_$AppDatabase, $FriendRequestsTable, FriendRequest>,
          ),
          FriendRequest,
          PrefetchHooks Function()
        > {
  $$FriendRequestsTableTableManager(
    _$AppDatabase db,
    $FriendRequestsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FriendRequestsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FriendRequestsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FriendRequestsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> sendId = const Value.absent(),
                Value<String?> sendNickName = const Value.absent(),
                Value<String?> sendHeadImage = const Value.absent(),
                Value<int?> recvId = const Value.absent(),
                Value<String?> recvNickName = const Value.absent(),
                Value<String?> recvHeadImage = const Value.absent(),
                Value<String?> remark = const Value.absent(),
                Value<int> status = const Value.absent(),
                Value<int?> applyTime = const Value.absent(),
              }) => FriendRequestsCompanion(
                id: id,
                sendId: sendId,
                sendNickName: sendNickName,
                sendHeadImage: sendHeadImage,
                recvId: recvId,
                recvNickName: recvNickName,
                recvHeadImage: recvHeadImage,
                remark: remark,
                status: status,
                applyTime: applyTime,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> sendId = const Value.absent(),
                Value<String?> sendNickName = const Value.absent(),
                Value<String?> sendHeadImage = const Value.absent(),
                Value<int?> recvId = const Value.absent(),
                Value<String?> recvNickName = const Value.absent(),
                Value<String?> recvHeadImage = const Value.absent(),
                Value<String?> remark = const Value.absent(),
                Value<int> status = const Value.absent(),
                Value<int?> applyTime = const Value.absent(),
              }) => FriendRequestsCompanion.insert(
                id: id,
                sendId: sendId,
                sendNickName: sendNickName,
                sendHeadImage: sendHeadImage,
                recvId: recvId,
                recvNickName: recvNickName,
                recvHeadImage: recvHeadImage,
                remark: remark,
                status: status,
                applyTime: applyTime,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FriendRequestsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FriendRequestsTable,
      FriendRequest,
      $$FriendRequestsTableFilterComposer,
      $$FriendRequestsTableOrderingComposer,
      $$FriendRequestsTableAnnotationComposer,
      $$FriendRequestsTableCreateCompanionBuilder,
      $$FriendRequestsTableUpdateCompanionBuilder,
      (
        FriendRequest,
        BaseReferences<_$AppDatabase, $FriendRequestsTable, FriendRequest>,
      ),
      FriendRequest,
      PrefetchHooks Function()
    >;
typedef $$SyncCursorsTableCreateCompanionBuilder =
    SyncCursorsCompanion Function({
      required String key,
      Value<int> value,
      Value<int> rowid,
    });
typedef $$SyncCursorsTableUpdateCompanionBuilder =
    SyncCursorsCompanion Function({
      Value<String> key,
      Value<int> value,
      Value<int> rowid,
    });

class $$SyncCursorsTableFilterComposer
    extends Composer<_$AppDatabase, $SyncCursorsTable> {
  $$SyncCursorsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncCursorsTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncCursorsTable> {
  $$SyncCursorsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncCursorsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncCursorsTable> {
  $$SyncCursorsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<int> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SyncCursorsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncCursorsTable,
          SyncCursor,
          $$SyncCursorsTableFilterComposer,
          $$SyncCursorsTableOrderingComposer,
          $$SyncCursorsTableAnnotationComposer,
          $$SyncCursorsTableCreateCompanionBuilder,
          $$SyncCursorsTableUpdateCompanionBuilder,
          (
            SyncCursor,
            BaseReferences<_$AppDatabase, $SyncCursorsTable, SyncCursor>,
          ),
          SyncCursor,
          PrefetchHooks Function()
        > {
  $$SyncCursorsTableTableManager(_$AppDatabase db, $SyncCursorsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncCursorsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncCursorsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncCursorsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<int> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncCursorsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                Value<int> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncCursorsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncCursorsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncCursorsTable,
      SyncCursor,
      $$SyncCursorsTableFilterComposer,
      $$SyncCursorsTableOrderingComposer,
      $$SyncCursorsTableAnnotationComposer,
      $$SyncCursorsTableCreateCompanionBuilder,
      $$SyncCursorsTableUpdateCompanionBuilder,
      (
        SyncCursor,
        BaseReferences<_$AppDatabase, $SyncCursorsTable, SyncCursor>,
      ),
      SyncCursor,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ChatsTableTableManager get chats =>
      $$ChatsTableTableManager(_db, _db.chats);
  $$MessagesTableTableManager get messages =>
      $$MessagesTableTableManager(_db, _db.messages);
  $$FriendsTableTableManager get friends =>
      $$FriendsTableTableManager(_db, _db.friends);
  $$GroupsTableTableManager get groups =>
      $$GroupsTableTableManager(_db, _db.groups);
  $$GroupMembersTableTableManager get groupMembers =>
      $$GroupMembersTableTableManager(_db, _db.groupMembers);
  $$FriendRequestsTableTableManager get friendRequests =>
      $$FriendRequestsTableTableManager(_db, _db.friendRequests);
  $$SyncCursorsTableTableManager get syncCursors =>
      $$SyncCursorsTableTableManager(_db, _db.syncCursors);
}
