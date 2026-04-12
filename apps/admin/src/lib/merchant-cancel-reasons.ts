/** Đồng bộ mã với API: `apps/api/src/bookings/merchant-cancel-presets.ts` */
export const MERCHANT_CANCEL_OPTIONS = [
  { code: "full", label: "Hết phòng / hết chỗ (slot)" },
  { code: "weather", label: "Thời tiết / sự cố khách quan" },
  { code: "duplicate", label: "Trùng đơn / nhập nhầm" },
  { code: "customer", label: "Khách hủy / không liên hệ được" },
  { code: "price", label: "Giá, thanh toán, chính sách" },
  { code: "other", label: "Khác (ghi rõ bên dưới)" },
] as const;

const LABELS: Record<string, string> = Object.fromEntries(
  MERCHANT_CANCEL_OPTIONS.map((o) => [o.code, o.label]),
);

export function merchantCancelPresetLabel(code: string | null | undefined): string {
  if (!code) return "";
  return LABELS[code] ?? code;
}

export function formatMerchantCancelLine(booking: {
  merchantCancelPreset?: string | null;
  merchantCancelDetail?: string | null;
}): string | null {
  const preset = booking.merchantCancelPreset?.trim();
  const detail = booking.merchantCancelDetail?.trim();
  if (!preset && !detail) return null;
  const label = merchantCancelPresetLabel(preset ?? "");
  if (preset === "other") {
    return detail ? `${label}: ${detail}` : label || null;
  }
  if (detail) {
    return label ? `${label} — ${detail}` : detail;
  }
  return label || null;
}
