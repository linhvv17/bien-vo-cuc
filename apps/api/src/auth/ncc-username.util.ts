/** Tài khoản NCC đăng nhập bằng username — lưu unique qua cột email dạng `xxx@ncc.local`. */

export const NCC_EMAIL_SUFFIX = '@ncc.local';

export function isNccSyntheticEmail(email: string): boolean {
  return email.endsWith(NCC_EMAIL_SUFFIX);
}

export function nccLocalPartFromUsername(raw: string): string {
  return raw
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9_]/g, '');
}

export function nccEmailFromUsername(raw: string): string {
  const slug = nccLocalPartFromUsername(raw);
  return `${slug}${NCC_EMAIL_SUFFIX}`;
}

export function isValidNccUsernameSlug(slug: string): boolean {
  return /^[a-z0-9_]{3,32}$/.test(slug);
}

/** Hiển thị trong admin: local-part nếu là tài khoản @ncc.local, không thì email đầy đủ (dữ liệu cũ). */
export function displayLoginFromStoredEmail(email: string): string {
  if (email.endsWith(NCC_EMAIL_SUFFIX)) {
    return email.slice(0, -NCC_EMAIL_SUFFIX.length);
  }
  return email;
}
