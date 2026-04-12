"use client";
/* eslint-disable @next/next/no-img-element */

import { useState } from "react";

import { MERCHANT_CANCEL_OPTIONS, formatMerchantCancelLine } from "@/lib/merchant-cancel-reasons";

export type BookingRequestRow = {
  id: string;
  createdAt: string;
  date: string;
  quantity: number;
  totalPrice: number;
  status: string;
  merchantCancelPreset?: string | null;
  merchantCancelDetail?: string | null;
  customerName: string;
  customerPhone: string;
  customerNote: string | null;
  bookingGroupId: string | null;
  service: {
    id: string;
    name: string;
    type: string;
    description: string;
    price: number;
    maxCapacity: number;
    images: string[];
    provider: {
      name: string;
      phone: string | null;
      address: string | null;
    } | null;
  };
  combo: {
    id: string;
    title: string | null;
    discountPercent: number;
    hotel: {
      id: string;
      name: string;
      price: number;
      images: string[];
      type: string;
    };
    food: {
      id: string;
      name: string;
      price: number;
      images: string[];
      type: string;
    };
  } | null;
};

const STATUS_VI: Record<string, string> = {
  PENDING: "Chờ xử lý",
  CONFIRMED: "Đã xác nhận",
  CANCELLED: "Đã hủy",
};

const TYPE_VI: Record<string, string> = {
  ACCOMMODATION: "Nhà nghỉ / lưu trú",
  FOOD: "Ăn uống",
  VEHICLE: "Xe / vận chuyển",
  TOUR: "Tour / chụp ảnh",
};

export const BOOKING_STATUSES = ["PENDING", "CONFIRMED", "CANCELLED"] as const;

export type CancelMeta = { preset: string; detail: string };

type Props = {
  booking: BookingRequestRow;
  onStatusChange: (
    id: string,
    status: (typeof BOOKING_STATUSES)[number],
    cancelMeta?: CancelMeta,
  ) => void;
  updating: boolean;
  /** NCC: nút bấm + modal hủy có lý do. Admin: dropdown nhanh. */
  merchantUi?: boolean;
};

export function BookingRequestCard({ booking: b, onStatusChange, updating, merchantUi }: Props) {
  const bStatus = b.status as (typeof BOOKING_STATUSES)[number];
  const isPending = b.status === "PENDING";
  const imgs = b.service.images?.length ? b.service.images : [];
  const typeLabel = TYPE_VI[b.service.type] ?? b.service.type;
  const statusLabel = STATUS_VI[b.status] ?? b.status;
  const cancelReasonLine = formatMerchantCancelLine(b);

  const [cancelModalOpen, setCancelModalOpen] = useState(false);
  const [cancelPreset, setCancelPreset] = useState<string>(MERCHANT_CANCEL_OPTIONS[0].code);
  const [cancelDetail, setCancelDetail] = useState("");

  function openCancelModal() {
    setCancelPreset(MERCHANT_CANCEL_OPTIONS[0].code);
    setCancelDetail("");
    setCancelModalOpen(true);
  }

  function confirmCancel() {
    const detail = cancelDetail.trim();
    if (cancelPreset === "other" && detail.length < 3) {
      return;
    }
    onStatusChange(b.id, "CANCELLED", { preset: cancelPreset, detail });
    setCancelModalOpen(false);
  }

  const canAct = b.status === "PENDING" || b.status === "CONFIRMED";

  return (
    <article
      className={`overflow-hidden rounded-xl border bg-zinc-900/50 ${
        isPending ? "border-amber-500/35 ring-1 ring-amber-500/15" : "border-white/10"
      }`}
    >
      <div className="grid gap-4 p-4 md:grid-cols-[minmax(0,140px)_1fr]">
        <div className="space-y-2">
          {imgs.length > 0 ? (
            <div className="flex gap-2 overflow-x-auto pb-1 md:flex-col md:overflow-visible">
              {imgs.slice(0, 4).map((src, i) => (
                <img
                  key={`${b.id}-img-${i}`}
                  src={src}
                  alt=""
                  className="h-24 w-full shrink-0 rounded-lg object-cover md:h-28 md:w-full"
                  loading="lazy"
                />
              ))}
            </div>
          ) : (
            <div className="flex h-24 items-center justify-center rounded-lg border border-dashed border-white/15 bg-zinc-950/80 text-xs text-zinc-500 md:h-full md:min-h-[7rem]">
              Chưa có ảnh
            </div>
          )}
        </div>

        <div className="min-w-0 space-y-3">
          <div className="flex flex-wrap items-start justify-between gap-2">
            <div>
              <div className="flex flex-wrap items-center gap-2">
                <h2 className="text-base font-semibold text-white">{b.service.name}</h2>
                {b.combo ? (
                  <span className="rounded-full bg-violet-500/20 px-2 py-0.5 text-[11px] font-medium text-violet-200">
                    Combo −{b.combo.discountPercent}%
                  </span>
                ) : null}
                <span className="rounded-full border border-white/10 bg-white/5 px-2 py-0.5 text-[11px] text-zinc-400">
                  {typeLabel}
                </span>
              </div>
              {b.service.description ? (
                <p className="mt-1 text-sm leading-relaxed text-zinc-400">{b.service.description}</p>
              ) : null}
            </div>
            <div className="text-right">
              <div
                className={`inline-flex rounded-lg px-2.5 py-1 text-xs font-medium ${
                  b.status === "CONFIRMED"
                    ? "bg-emerald-500/15 text-emerald-200"
                    : b.status === "CANCELLED"
                      ? "bg-rose-500/15 text-rose-200"
                      : "bg-amber-500/15 text-amber-200"
                }`}
              >
                {statusLabel}
              </div>
            </div>
          </div>

          {b.status === "CANCELLED" && cancelReasonLine ? (
            <div className="rounded-lg border border-rose-500/25 bg-rose-950/25 p-3 text-sm">
              <div className="text-xs font-medium text-rose-200/90">Lý do hủy (từ NCC)</div>
              <p className="mt-1 text-zinc-200 leading-relaxed">{cancelReasonLine}</p>
            </div>
          ) : null}

          {b.combo && b.combo.hotel && b.combo.food ? (
            <div className="rounded-lg border border-violet-500/20 bg-violet-950/20 p-3 text-sm">
              <div className="text-xs font-medium text-violet-200/90">Combo đặt kèm</div>
              <div className="mt-2 grid gap-2 sm:grid-cols-2">
                <div className="rounded-md bg-black/20 px-2 py-1.5">
                  <div className="text-[11px] text-zinc-500">Nghỉ</div>
                  <div className="font-medium text-zinc-100">{b.combo.hotel.name}</div>
                  <div className="text-xs text-zinc-400">Giá gốc {formatVnd(b.combo.hotel.price)}</div>
                </div>
                <div className="rounded-md bg-black/20 px-2 py-1.5">
                  <div className="text-[11px] text-zinc-500">Ăn</div>
                  <div className="font-medium text-zinc-100">{b.combo.food.name}</div>
                  <div className="text-xs text-zinc-400">{formatVnd(b.combo.food.price)}</div>
                </div>
              </div>
              {b.combo.title ? <p className="mt-2 text-xs text-zinc-500">{b.combo.title}</p> : null}
              <div className="mt-2 flex flex-wrap gap-2">
                {b.combo.hotel.images?.slice(0, 2).map((src, i) => (
                  <img
                    key={`h-${i}`}
                    src={src}
                    alt=""
                    className="h-14 w-20 rounded object-cover"
                    loading="lazy"
                  />
                ))}
                {b.combo.food.images?.slice(0, 2).map((src, i) => (
                  <img
                    key={`f-${i}`}
                    src={src}
                    alt=""
                    className="h-14 w-20 rounded object-cover"
                    loading="lazy"
                  />
                ))}
              </div>
            </div>
          ) : null}

          <div className="grid gap-3 sm:grid-cols-2">
            <div className="rounded-lg border border-sky-500/20 bg-sky-950/20 p-3">
              <div className="text-xs font-medium text-sky-200/90">Khách & liên hệ</div>
              <div className="mt-1 font-medium text-white">{b.customerName}</div>
              <a href={`tel:${b.customerPhone}`} className="text-sm text-sky-300 hover:underline">
                {b.customerPhone}
              </a>
              {b.customerNote ? (
                <p className="mt-2 border-t border-white/10 pt-2 text-sm text-zinc-300">
                  <span className="text-zinc-500">Ghi chú: </span>
                  {b.customerNote}
                </p>
              ) : (
                <p className="mt-1 text-xs text-zinc-500">Không có ghi chú thêm.</p>
              )}
            </div>

            <div className="rounded-lg border border-white/10 bg-zinc-950/60 p-3">
              <div className="text-xs font-medium text-zinc-400">Nhà cung cấp (NCC)</div>
              {b.service.provider ? (
                <>
                  <div className="mt-1 font-medium text-zinc-100">{b.service.provider.name}</div>
                  {b.service.provider.phone ? (
                    <a href={`tel:${b.service.provider.phone}`} className="text-sm text-sky-300 hover:underline">
                      {b.service.provider.phone}
                    </a>
                  ) : null}
                  {b.service.provider.address ? (
                    <p className="mt-1 text-xs text-zinc-500">{b.service.provider.address}</p>
                  ) : null}
                </>
              ) : (
                <p className="mt-1 text-xs text-zinc-500">Không gắn NCC.</p>
              )}
            </div>
          </div>

          <div className="flex flex-wrap items-end justify-between gap-3 border-t border-white/10 pt-3 text-sm">
            <div className="flex flex-wrap gap-x-6 gap-y-1 text-zinc-400">
              <span>
                <span className="text-zinc-500">Ngày dùng:</span>{" "}
                <span className="text-zinc-200">{formatDateTime(b.date)}</span>
              </span>
              <span>
                <span className="text-zinc-500">Đặt lúc:</span>{" "}
                <span className="text-zinc-200">{formatDateTime(b.createdAt)}</span>
              </span>
              {b.bookingGroupId ? (
                <span className="font-mono text-xs text-zinc-500" title="Nhóm combo">
                  Nhóm: {b.bookingGroupId.slice(0, 8)}…
                </span>
              ) : null}
            </div>
            <div className="text-right">
              <div className="text-xs text-zinc-500">
                SL × {b.quantity} · Tối đa {b.service.maxCapacity} khách · Đơn giá {formatVnd(b.service.price)}
                {b.service.type === "ACCOMMODATION" ? "/đêm" : b.service.type === "FOOD" ? "/suất" : ""}
              </div>
              <div className="text-lg font-semibold text-amber-200">
                Thành tiền: {formatVnd(b.totalPrice)}
              </div>
            </div>
          </div>

          <div className="border-t border-white/10 pt-3">
            <div className="text-xs font-medium text-zinc-500 mb-2">Trạng thái đơn</div>
            {merchantUi ? (
              <div className="flex flex-wrap gap-2">
                {b.status === "PENDING" ? (
                  <button
                    type="button"
                    disabled={updating}
                    onClick={() => onStatusChange(b.id, "CONFIRMED")}
                    className="rounded-lg bg-emerald-600 px-4 py-2 text-sm font-medium text-white hover:bg-emerald-500 disabled:opacity-50"
                  >
                    Xác nhận đơn
                  </button>
                ) : null}
                {canAct ? (
                  <button
                    type="button"
                    disabled={updating}
                    onClick={openCancelModal}
                    className="rounded-lg border border-rose-500/50 bg-rose-500/10 px-4 py-2 text-sm font-medium text-rose-200 hover:bg-rose-500/20 disabled:opacity-50"
                  >
                    Hủy đơn
                  </button>
                ) : null}
                {!canAct ? (
                  <span className="text-xs text-zinc-500 self-center">
                    {b.status === "CANCELLED" ? "Đơn đã hủy — không đổi được." : "—"}
                  </span>
                ) : null}
              </div>
            ) : (
              <div className="flex flex-wrap items-center gap-2">
                <span className="text-xs text-zinc-500">Đổi nhanh:</span>
                <select
                  className="rounded-lg border border-white/10 bg-zinc-950 px-3 py-1.5 text-sm text-zinc-200 max-w-[220px]"
                  value={bStatus}
                  disabled={updating}
                  onChange={(e) =>
                    onStatusChange(b.id, e.target.value as (typeof BOOKING_STATUSES)[number])
                  }
                >
                  {BOOKING_STATUSES.map((s) => (
                    <option key={s} value={s}>
                      {STATUS_VI[s] ?? s}
                    </option>
                  ))}
                </select>
              </div>
            )}
          </div>
        </div>
      </div>

      {cancelModalOpen && merchantUi ? (
        <div
          className="fixed inset-0 z-[100] flex items-center justify-center bg-black/70 px-4 py-8"
          role="dialog"
          aria-modal="true"
          aria-labelledby={`cancel-title-${b.id}`}
          onClick={() => setCancelModalOpen(false)}
        >
          <div
            className="w-full max-w-md rounded-xl border border-white/10 bg-zinc-900 p-5 shadow-xl"
            onClick={(e) => e.stopPropagation()}
          >
            <h3 id={`cancel-title-${b.id}`} className="text-base font-semibold text-white">
              Hủy đơn đặt
            </h3>
            <p className="mt-1 text-xs text-zinc-400">
              Chọn lý do (bắt buộc). Có thể bổ sung chi tiết — admin sẽ xem được.
            </p>
            <div className="mt-4 space-y-2 max-h-48 overflow-y-auto">
              {MERCHANT_CANCEL_OPTIONS.map((opt) => (
                <label
                  key={opt.code}
                  className={`flex cursor-pointer items-start gap-2 rounded-lg border px-3 py-2 text-sm ${
                    cancelPreset === opt.code
                      ? "border-sky-500/50 bg-sky-500/10 text-zinc-100"
                      : "border-white/10 bg-zinc-950 text-zinc-300 hover:border-white/20"
                  }`}
                >
                  <input
                    type="radio"
                    name={`cancel-preset-${b.id}`}
                    className="mt-0.5"
                    checked={cancelPreset === opt.code}
                    onChange={() => setCancelPreset(opt.code)}
                  />
                  <span>{opt.label}</span>
                </label>
              ))}
            </div>
            <div className="mt-3">
              <label className="block text-xs text-zinc-500 mb-1">Chi tiết thêm (khuyến nghị)</label>
              <textarea
                value={cancelDetail}
                onChange={(e) => setCancelDetail(e.target.value)}
                rows={3}
                placeholder={
                  cancelPreset === "other"
                    ? "Bắt buộc ghi rõ lý do…"
                    : "Ví dụ: phòng 201, khách đổi ngày…"
                }
                className="w-full rounded-lg border border-white/10 bg-zinc-950 px-3 py-2 text-sm text-zinc-200 placeholder:text-zinc-600 outline-none focus:border-sky-500/50"
              />
              {cancelPreset === "other" && cancelDetail.trim().length < 3 ? (
                <p className="mt-1 text-xs text-amber-400/90">Với «Khác», cần ít nhất 3 ký tự.</p>
              ) : null}
            </div>
            <div className="mt-4 flex flex-wrap gap-2 justify-end">
              <button
                type="button"
                className="rounded-lg border border-white/15 px-4 py-2 text-sm text-zinc-300 hover:bg-white/5"
                onClick={() => setCancelModalOpen(false)}
              >
                Đóng
              </button>
              <button
                type="button"
                disabled={
                  updating ||
                  (cancelPreset === "other" && cancelDetail.trim().length < 3)
                }
                className="rounded-lg bg-rose-600 px-4 py-2 text-sm font-medium text-white hover:bg-rose-500 disabled:opacity-50"
                onClick={confirmCancel}
              >
                Xác nhận hủy đơn
              </button>
            </div>
          </div>
        </div>
      ) : null}
    </article>
  );
}

function formatVnd(n: number) {
  return `${n.toLocaleString("vi-VN")} đ`;
}

function formatDateTime(iso: string) {
  const d = new Date(iso);
  return d.toLocaleString("vi-VN", {
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
}
