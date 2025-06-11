/// Returns a new list of Map<String, dynamic> where each element is
/// assigned an 'index' key starting from 1.
/// Example:
///   final indexed = indexListElements(['a', 'b', 'c']);
///   // indexed: [ {'index': 1, 'value': 'a'}, ... ]
List<Map<String, dynamic>> indexListElements<T>(
  List<T> items, {
  String valueKey = 'value',
}) {
  return List.generate(
    items.length,
    (i) => {'index': i + 1, valueKey: items[i]},
  );
}
