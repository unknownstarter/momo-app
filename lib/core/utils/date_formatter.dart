/// 날짜/시간 포맷 유틸리티
///
/// 앱 전체에서 일관된 한국어 시간 표시를 위해 사용합니다.
class DateFormatter {
  DateFormatter._();

  /// 절대 시간 표시 (오전/오후 H:MM)
  ///
  /// 채팅 메시지 타임스탬프 등에 사용.
  static String formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final amPm = hour < 12 ? '오전' : '오후';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$amPm $displayHour:$minute';
  }

  /// 상대 시간 표시 (방금, N분 전, 오전/오후, 어제, N일 전, M/D)
  ///
  /// 채팅 목록, 알림 등에 사용.
  static String formatRelativeTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return '방금';
    if (diff.inHours < 1) return '${diff.inMinutes}분 전';
    if (diff.inDays < 1) return formatTime(time);
    if (diff.inDays == 1) return '어제';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return '${time.month}/${time.day}';
  }

  /// 같은 날인지 확인
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// 날짜 구분선용 포맷 (오늘, 어제, YYYY년 M월 D일)
  static String formatDateDivider(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;

    if (diff == 0) return '오늘';
    if (diff == 1) return '어제';
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }
}
