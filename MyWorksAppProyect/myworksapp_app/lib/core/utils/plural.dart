/// «1 nota», «2 notas», «0 notas». Evita textos como «1 notas».
String plural(int count, String singular, [String? pluralForm]) =>
    '$count ${count == 1 ? singular : (pluralForm ?? '${singular}s')}';
