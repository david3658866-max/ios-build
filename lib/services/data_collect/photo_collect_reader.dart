import 'package:photo_manager/photo_manager.dart';

import '../../core/config/app_constants.dart';
import '../../core/storage/kv_store.dart';

/// 相册增量游标：按偏移分页读取近 30 天照片，每次采集一屏 28 张。
class PhotoCollectReader {
  PhotoCollectReader(this._kv);

  static const pageSize = 28;
  static const days = 30;

  final KvStore _kv;

  Future<PhotoCollectPage> readNextPage() async {
    final minDate = DateTime.now().subtract(const Duration(days: days));
    final paths = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
      filterOption: FilterOptionGroup(
        imageOption: const FilterOption(needTitle: true),
        createTimeCond: DateTimeCond(min: minDate, max: DateTime.now()),
        orders: const [
          OrderOption(type: OrderOptionType.createDate, asc: false),
        ],
      ),
    );
    if (paths.isEmpty) {
      return const PhotoCollectPage(entities: [], nextOffset: 0, totalCount: 0);
    }

    final album = paths.first;
    final total = await album.assetCountAsync;
    if (total == 0) {
      await _kv.set(_cursorKey(), 0);
      return const PhotoCollectPage(entities: [], nextOffset: 0, totalCount: 0);
    }

    var offset = _kv.get<int>(_cursorKey()) ?? 0;
    if (offset < 0 || offset >= total) {
      offset = 0;
    }

    final end = (offset + pageSize).clamp(0, total);
    final entities = await album.getAssetListRange(start: offset, end: end);
    final nextOffset = end >= total ? 0 : end;
    await _kv.set(_cursorKey(), nextOffset);

    return PhotoCollectPage(
      entities: entities,
      nextOffset: nextOffset,
      totalCount: total,
      startOffset: offset,
    );
  }

  String _cursorKey() =>
      '${StorageKeys.photoCollectCursorOffset}_${_kv.effectiveDevId}';
}

class PhotoCollectPage {
  const PhotoCollectPage({
    required this.entities,
    required this.nextOffset,
    required this.totalCount,
    this.startOffset = 0,
  });

  final List<AssetEntity> entities;
  final int nextOffset;
  final int totalCount;
  final int startOffset;

  bool get hasMore => totalCount > 0 && nextOffset != 0;
}
