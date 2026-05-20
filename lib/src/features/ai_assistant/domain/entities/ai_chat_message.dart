import 'package:equatable/equatable.dart';

class AiMessage extends Equatable {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  const AiMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [text, isUser, timestamp];
}
