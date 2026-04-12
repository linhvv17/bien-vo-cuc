# Flutter modules (trong cùng project mobile)

Các package local nằm tại:

**`apps/mobile/packages/`**

Mở trong IDE: thư mục **`mobile/packages`** (bên cạnh `lib/`, `android/`, …).

| Package | Vai trò |
|--------|---------|
| `bvc_network` | Dio, base URL, parse API |
| `bvc_common` | `ymd`, `formatVnd` |
| `bvc_ui` | Theme + widget chung |
| `bvc_auth` | Auth (stub, mở rộng sau) |
| `bvc_home` | Màn Home |
| `bvc_services` | Ăn & Ở / combo |
| `bvc_booking` | Đặt dịch vụ |

Khai báo trong `apps/mobile/pubspec.yaml`:

```yaml
bvc_home:
  path: packages/bvc_home
```

**Backend NestJS** không nằm đây — vẫn ở `apps/api/`.
