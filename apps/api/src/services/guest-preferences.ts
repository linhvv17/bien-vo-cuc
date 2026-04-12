/** Tiêu chí đặt phòng (key lưu trong Booking.guestPreferences). */
export const GUEST_PREFERENCE_OPTIONS = [
  { key: 'quiet', label: 'Ưu tiên phòng yên tĩnh' },
  { key: 'high_floor', label: 'Tầng cao / view tốt hơn' },
  { key: 'near_elevator', label: 'Gần thang máy / cầu thang' },
  { key: 'bathtub', label: 'Có bồn tắm / nước nóng' },
  { key: 'early_checkin', label: 'Nhận phòng sớm (tuỳ cơ sở)' },
  { key: 'window', label: 'Ưu tiên phòng có cửa sổ lớn' },
] as const;
