import 'package:screenshot_inbox/core/utils/id_generator.dart';
import 'package:uuid/uuid.dart';

final class UuidIdGenerator implements IdGenerator {
  UuidIdGenerator([Uuid? uuid]) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;

  @override
  String next() => _uuid.v4();
}
