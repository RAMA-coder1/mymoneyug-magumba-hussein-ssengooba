/// UGX has no minor unit in everyday use, so amounts show as whole shillings.
String ugx(double v) {
  final negative = v < 0;
  final whole = v.abs().round().toString();
  final buf = StringBuffer();
  for (var i = 0; i < whole.length; i++) {
    if (i > 0 && (whole.length - i) % 3 == 0) buf.write(',');
    buf.write(whole[i]);
  }
  return '${negative ? '-' : ''}UGX $buf';
}

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
];

String shortDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';
