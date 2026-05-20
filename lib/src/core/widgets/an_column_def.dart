import 'package:flutter/material.dart';

/// Loại header của cột trong bảng dữ liệu.
enum AnColumnType {
  /// Header text thuần tuý, không có icon.
  text,

  /// Header có icon sort (arrow up/down).
  sortable,

  /// Header có icon dropdown filter.
  filterable,
}

/// Định nghĩa một cột cho bảng dữ liệu.
///
/// Generic [T] là kiểu dữ liệu của mỗi row item.
class AnColumnDef<T> {
  const AnColumnDef({
    required this.key,
    required this.label,
    required this.valueGetter,
    this.width,
    this.flex = 1,
    this.type = AnColumnType.text,
    this.cellBuilder,
    this.textAlign = TextAlign.left,
  });

  /// Key duy nhất dùng để phân biệt cột (dùng cho sort/filter callbacks).
  final String key;

  /// Label hiển thị trên header.
  final String label;

  /// Chiều rộng cố định. Nếu null, sẽ dùng [flex].
  final double? width;

  /// Flex factor khi không có [width]. Mặc định = 1.
  final int flex;

  /// Loại header: text / sortable / filterable.
  final AnColumnType type;

  /// Hàm lấy giá trị text từ item T để hiển thị trong cell.
  final String Function(T item) valueGetter;

  /// Custom widget builder cho cell. Nếu null, sẽ dùng [valueGetter] + Text.
  final Widget Function(T item, int index)? cellBuilder;

  /// Text alignment trong cell. Mặc định = TextAlign.left.
  final TextAlign textAlign;

  AnColumnDef<T> copyWith({
    String? key,
    String? label,
    String Function(T item)? valueGetter,
    double? width,
    int? flex,
    AnColumnType? type,
    Widget Function(T item, int index)? cellBuilder,
    TextAlign? textAlign,
  }) {
    return AnColumnDef<T>(
      key: key ?? this.key,
      label: label ?? this.label,
      valueGetter: valueGetter ?? this.valueGetter,
      width: width ?? this.width,
      flex: flex ?? this.flex,
      type: type ?? this.type,
      cellBuilder: cellBuilder ?? this.cellBuilder,
      textAlign: textAlign ?? this.textAlign,
    );
  }
}
