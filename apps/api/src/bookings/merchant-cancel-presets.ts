/** Mã lý do hủy đơn do nhà cung cấp chọn (lưu DB + hiển thị admin). */
export const MERCHANT_CANCEL_PRESETS = [
  'full',
  'weather',
  'duplicate',
  'customer',
  'price',
  'other',
] as const;

export type MerchantCancelPreset = (typeof MERCHANT_CANCEL_PRESETS)[number];

export function isMerchantCancelPreset(s: string): s is MerchantCancelPreset {
  return (MERCHANT_CANCEL_PRESETS as readonly string[]).includes(s);
}
