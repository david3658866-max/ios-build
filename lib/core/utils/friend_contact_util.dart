/// 手机通讯录行。对齐 friend-contact.vue contact item。
class DeviceContactRow {
  const DeviceContactRow({
    required this.id,
    required this.name,
    required this.phones,
  });

  final String id;
  final String name;
  final List<String> phones;

  String get primaryPhone => phones.isNotEmpty ? phones.first : '';
}

/// 按姓名或任意号码过滤联系人。
List<DeviceContactRow> filterDeviceContacts(
  List<DeviceContactRow> contacts,
  String query,
) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return contacts;
  return contacts
      .where(
        (c) =>
            c.name.toLowerCase().contains(q) ||
            c.phones.any((p) => p.toLowerCase().contains(q)),
      )
      .toList();
}
