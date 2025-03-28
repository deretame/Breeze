import '../main.dart';

class StackList<T> {
  // 私有构造函数
  final List<T> _items = [];

  // 压入元素
  void push(T item) {
    _items.add(item);
  }

  // 弹出栈顶元素
  T pop() {
    if (_items.isEmpty) {
      throw Exception('Stack is empty');
    }
    return _items.removeLast();
  }

  // 获取栈顶元素
  T get top {
    if (_items.isEmpty) {
      throw Exception('Stack is empty');
    }
    return _items.last;
  }

  // 栈是否为空
  bool get isEmpty => _items.isEmpty;

  // 栈是否不为空
  bool get isNotEmpty => _items.isNotEmpty;

  // 栈中是否包含元素
  bool contains(T element) => _items.contains(element);

  // 清空栈
  void clear() {
    _items.clear();
  }

  // 打印栈
  void print() {
    logger.d('Stack: $_items');
  }

  // 栈大小
  int size() => _items.length;
}
