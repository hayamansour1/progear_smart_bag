import 'package:logger/logger.dart';

/// [logger] custom log
Logger logger(Type type) => Logger(printer: CustomLogPrinter(type.toString()));

class CustomLogPrinter extends LogPrinter {
  CustomLogPrinter(this.className);
  final String className;
  @override
  List<String> log(LogEvent event) {
    AnsiColor? color = PrettyPrinter.defaultLevelColors[event.level];
    String? emoji = PrettyPrinter.defaultLevelEmojis[event.level];
    final message = event.message;
    Object? error = event.error;

    return [color!('$emoji: $className: $message \n${error ?? ''}')];
  }
}
