class PickedFile {
  const PickedFile({required this.name, required this.bytes});
  final String name;
  final List<int> bytes;
}

abstract class FileSource {
  Future<PickedFile?> pick();
}
