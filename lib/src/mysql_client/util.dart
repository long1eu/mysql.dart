import 'package:mysql_client/exception.dart';

String substituteParams(String query, Map<String, dynamic> params) {
  // convert params to string
  Map<String, String> convertedParams = {};

  for (final param in params.entries) {
    String value;

    if (param.value == null) {
      value = "NULL";
    } else if (param.value is String) {
      value = "'" + _escapeString(param.value) + "'";
    } else if (param.value is num) {
      value = param.value.toString();
    } else if (param.value is bool) {
      value = param.value ? "TRUE" : "FALSE";
    } else {
      value = "'" + _escapeString(param.value.toString()) + "'";
    }

    convertedParams[param.key] = value;
  }

  // find all :placeholders, which can be substituted
  final pattern = RegExp(r":(\w+)");

  final matches = pattern.allMatches(query).where((match) {
    final subString = query.substring(0, match.start);

    int count = "'".allMatches(subString).length;
    if (count > 0 && count.isOdd) {
      return false;
    }

    count = '"'.allMatches(subString).length;
    if (count > 0 && count.isOdd) {
      return false;
    }

    return true;
  }).toList();

  int lengthShift = 0;

  for (final match in matches) {
    final paramName = match.group(1);

    // check param exists
    if (false == convertedParams.containsKey(paramName)) {
      throw MySQLClientException("There is no parameter with name: $paramName");
    }

    final newQuery = query.replaceFirst(
      match.group(0)!,
      convertedParams[paramName]!,
      match.start + lengthShift,
    );

    lengthShift += newQuery.length - query.length;
    query = newQuery;
  }

  return query;
}

String _escapeString(String value) {
  value = value.replaceAll(r"\", r'\\');
  value = value.replaceAll(r"'", r"''");
  return value;
}
