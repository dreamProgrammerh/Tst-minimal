import 'values.dart';

class EvalEntry {
  String key;
  RuntimeValue value;
  EvalEntry({this.key = "", this.value = InvalidValue.instance});
  
  @override
  String toString() => '($key: $value)';
} 

abstract class EvalResult {
  int _i = -1;
  
  int get length => 0;
  bool get end => _i >= length;
  EvalEntry? get current => null;
  
  EvalResult();
  
  RuntimeValue? operator [] (Object index) => InvalidValue.instance;
  void operator []= (Object index, RuntimeValue val) => null;
  
  bool next() {
    if (end)
      return false;
      
    _i++;
    return true;
  }
  
  void reset() {
    _i = -1;
  }
}

class EvalList extends EvalResult {
  final List<EvalEntry> list;
  
  int get length => list.length;
  EvalEntry? get current => end ? null : list[_i];

  EvalList(this.list);
  
  int _find(Object index) {
    switch (index) {
      case int i:
        return -1 < i && i < list.length
          ? i
          : -1;
          
      case String s:
        return list.indexWhere((e) => e.key == s);
      
      default:
        return -1;
    }
  }
  
  RuntimeValue? operator [] (Object index) {
    final i = _find(index);
    
    if (i == -1) return null;
    else return list[i].value;
  }
  
  void operator []= (Object index, RuntimeValue val) {
    final i = _find(index);
    
    if (i == -1) return null;
    else list[i].value = val;
  }
  
  @override
  String toString() => list.toString();
}

class EvalMap extends EvalResult {
  final Map<String, RuntimeValue> map;
  Iterable<MapEntry<String, RuntimeValue>> _it;
  
  int get length => map.length;
  
  EvalEntry? get current {
   if (end) return null;
   final cur = _it.elementAt(_i);
   
   return EvalEntry(key: cur.key, value: cur.value);
  }
  
  EvalMap(this.map): _it = map.entries;

  RuntimeValue? operator [] (Object index) {
    switch (index) {
      case String s:
        return map[s];
      
      default:
        return null;
    }
  }

  void operator []= (Object index, RuntimeValue val) {
    switch (index) {
      case String s:
        map[s] = val;
        break;
      
      default:
        return null;
    }
  }
  
  @override
  String toString() => map.toString();
}