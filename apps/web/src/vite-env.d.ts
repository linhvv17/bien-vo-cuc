/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_API_BASE_URL?: string;
  /** Dev: backend mà Vite proxy `/api` chuyển tới (mặc định 127.0.0.1:3001, khớp apps/api `.env.example`). */
  readonly VITE_API_PROXY_TARGET?: string;
  /** `true` = không gọi API (dữ liệu & đặt chỗ demo). */
  readonly VITE_USE_MOCK?: string;
  readonly VITE_RECAPTCHA_SITE_KEY?: string;
  readonly VITE_APP_ENV?: string;
  readonly VITE_APP_NAME?: string;
  /** Mapbox public token (pk.*) — ảnh bản đồ tĩnh ở DirectionsSection; lấy tại https://account.mapbox.com */
  readonly VITE_MAPBOX_PUBLIC_TOKEN?: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
