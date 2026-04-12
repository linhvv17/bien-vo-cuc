"use client";

import { FormEvent, useCallback, useEffect, useState } from "react";

import {
  createProviderAccount,
  createProviderForAdmin,
  deleteProviderAccount,
  listProviderAccounts,
  listProvidersForAdmin,
  loadAuth,
  updateProviderAccount,
  type ProviderAccountRow,
  type ProviderRow,
} from "@/lib/api";

const NCC_EMAIL_SUFFIX = "@ncc.local";

function isNccSyntheticEmail(email: string): boolean {
  return email.endsWith(NCC_EMAIL_SUFFIX);
}

export default function ProviderAccountsPage() {
  /** Tránh hydration mismatch: server không có localStorage; chỉ đọc auth sau mount. */
  const [ready, setReady] = useState(false);
  useEffect(() => {
    setReady(true);
  }, []);

  const token = ready ? loadAuth()?.token ?? "" : "";

  const [providers, setProviders] = useState<ProviderRow[]>([]);
  const [accounts, setAccounts] = useState<ProviderAccountRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [done, setDone] = useState<string | null>(null);

  const [providerId, setProviderId] = useState("");
  const [username, setUsername] = useState("");
  const [name, setName] = useState("");
  const [password, setPassword] = useState("");
  const [submitting, setSubmitting] = useState(false);

  const [editing, setEditing] = useState<ProviderAccountRow | null>(null);
  const [editUsername, setEditUsername] = useState("");
  const [editName, setEditName] = useState("");
  const [editProviderId, setEditProviderId] = useState("");
  const [editPassword, setEditPassword] = useState("");
  const [savingEdit, setSavingEdit] = useState(false);
  const [deletingId, setDeletingId] = useState<string | null>(null);

  const [newProviderName, setNewProviderName] = useState("");
  const [newProviderPhone, setNewProviderPhone] = useState("");
  const [creatingProvider, setCreatingProvider] = useState(false);

  const refreshAccounts = useCallback(async () => {
    if (!token) return;
    const accs = await listProviderAccounts(token);
    setAccounts(accs);
  }, [token]);

  useEffect(() => {
    if (!ready) return;
    if (!token) {
      setLoading(false);
      return;
    }
    let cancelled = false;
    (async () => {
      try {
        const [rows, accs] = await Promise.all([
          listProvidersForAdmin(token),
          listProviderAccounts(token),
        ]);
        if (!cancelled) {
          setProviders(rows);
          setAccounts(accs);
          if (rows.length && !providerId) setProviderId(rows[0].id);
        }
      } catch (e) {
        if (!cancelled) setError(e instanceof Error ? e.message : "Không tải được danh sách NCC");
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [ready, token]);

  function openEdit(row: ProviderAccountRow) {
    setEditing(row);
    setEditUsername(row.username);
    setEditName(row.name);
    setEditProviderId(row.providerId ?? "");
    setEditPassword("");
    setError(null);
    setDone(null);
  }

  function closeEdit() {
    setEditing(null);
    setEditPassword("");
  }

  async function onSubmitNewProvider(e: FormEvent) {
    e.preventDefault();
    setError(null);
    setDone(null);
    if (!token) return;
    const n = newProviderName.trim();
    if (n.length < 2) {
      setError("Nhập tên nhà cung cấp (ít nhất 2 ký tự).");
      return;
    }
    setCreatingProvider(true);
    try {
      const row = await createProviderForAdmin(token, {
        name: n,
        ...(newProviderPhone.trim() ? { phone: newProviderPhone.trim() } : {}),
      });
      setDone(`Đã thêm nhà cung cấp «${row.name}». Giờ có thể tạo tài khoản NCC gắn với NCC này.`);
      setNewProviderName("");
      setNewProviderPhone("");
      const rows = await listProvidersForAdmin(token);
      setProviders(rows);
      setProviderId(row.id);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Thêm NCC thất bại");
    } finally {
      setCreatingProvider(false);
    }
  }

  async function onSubmitCreate(e: FormEvent) {
    e.preventDefault();
    setError(null);
    setDone(null);
    if (!token) return;
    setSubmitting(true);
    try {
      const row = await createProviderAccount(token, {
        providerId,
        username: username.trim(),
        password,
        ...(name.trim() ? { name: name.trim() } : {}),
      });
      setDone(`Đã tạo tài khoản NCC «${row.username}» (MERCHANT / PROVIDER_ACCOUNT).`);
      setUsername("");
      setName("");
      setPassword("");
      await refreshAccounts();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Tạo thất bại");
    } finally {
      setSubmitting(false);
    }
  }

  async function onSubmitEdit(e: FormEvent) {
    e.preventDefault();
    if (!token || !editing) return;
    setError(null);
    setDone(null);
    setSavingEdit(true);
    try {
      const patch: { username?: string; name?: string; providerId?: string; password?: string } = {};
      const ncc = isNccSyntheticEmail(editing.email);
      const u = editUsername.trim().toLowerCase();
      if (ncc && u !== editing.username.toLowerCase()) {
        patch.username = u;
      }
      if (editName.trim() !== editing.name) {
        patch.name = editName.trim();
      }
      if (editProviderId !== (editing.providerId ?? "")) {
        patch.providerId = editProviderId;
      }
      if (editPassword.length > 0) {
        patch.password = editPassword;
      }
      if (Object.keys(patch).length === 0) {
        setDone("Không có thay đổi nào để lưu.");
        setSavingEdit(false);
        return;
      }
      const row = await updateProviderAccount(token, editing.id, patch);
      setDone(`Đã cập nhật tài khoản «${row.username}».`);
      closeEdit();
      await refreshAccounts();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Cập nhật thất bại");
    } finally {
      setSavingEdit(false);
    }
  }

  async function onDelete(row: ProviderAccountRow) {
    if (!token) return;
    const ok = window.confirm(
      `Xóa tài khoản «${row.username}»? Hành động không hoàn tác (trừ khi tạo lại).`,
    );
    if (!ok) return;
    setError(null);
    setDone(null);
    setDeletingId(row.id);
    try {
      await deleteProviderAccount(token, row.id);
      setDone(`Đã xóa tài khoản «${row.username}».`);
      if (editing?.id === row.id) closeEdit();
      await refreshAccounts();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Xóa thất bại");
    } finally {
      setDeletingId(null);
    }
  }

  if (!ready) {
    return (
      <div className="max-w-3xl space-y-6">
        <p className="text-sm text-zinc-400">Đang tải phiên…</p>
      </div>
    );
  }

  if (!token) {
    return <p className="text-sm text-zinc-400">Đăng nhập admin để quản lý tài khoản NCC.</p>;
  }

  return (
    <div className="max-w-3xl space-y-6">
      <div>
        <h1 className="text-lg font-semibold text-white">Tài khoản nhà cung cấp</h1>
        <p className="mt-1 text-sm text-zinc-400">
          Khách hàng đăng ký qua app (APP_CUSTOMER). Mỗi tài khoản đăng nhập NCC phải gắn với một{" "}
          <strong>bản ghi nhà cung cấp</strong> (tên homestay, quán ăn, …). Trên DB mới (production) chưa
          có NCC nào — thêm nhà cung cấp ở form bên dưới trước, rồi mới tạo tài khoản.
        </p>
      </div>

      <form
        onSubmit={onSubmitNewProvider}
        className="space-y-3 rounded-xl border border-amber-500/20 bg-amber-950/20 p-4"
      >
        <p className="text-xs font-medium text-amber-200/90">1. Thêm nhà cung cấp (NCC)</p>
        <p className="text-xs text-zinc-500">
          Chưa có dữ liệu demo như môi trường dev — cần ít nhất một bản ghi ở đây thì dropdown «Nhà cung
          cấp» mới chọn được.
        </p>
        <div className="grid gap-3 sm:grid-cols-2">
          <div className="sm:col-span-2">
            <label className="block text-xs text-zinc-400">Tên nhà cung cấp</label>
            <input
              value={newProviderName}
              onChange={(e) => setNewProviderName(e.target.value)}
              className="mt-1 w-full rounded-md border border-white/10 bg-zinc-950 px-3 py-2 text-sm outline-none focus:border-sky-500/60"
              placeholder="VD: Homestay Biển Vô Cực"
              minLength={2}
              required
            />
          </div>
          <div>
            <label className="block text-xs text-zinc-400">Số điện thoại (tuỳ chọn)</label>
            <input
              value={newProviderPhone}
              onChange={(e) => setNewProviderPhone(e.target.value)}
              className="mt-1 w-full rounded-md border border-white/10 bg-zinc-950 px-3 py-2 text-sm outline-none focus:border-sky-500/60"
              placeholder="090…"
            />
          </div>
        </div>
        <button
          type="submit"
          disabled={creatingProvider}
          className="rounded-md border border-amber-500/40 bg-amber-900/40 px-4 py-2 text-sm font-medium text-amber-100 hover:bg-amber-900/60 disabled:opacity-50"
        >
          {creatingProvider ? "Đang thêm…" : "Thêm nhà cung cấp"}
        </button>
      </form>

      {!loading ? (
        <div className="rounded-xl border border-white/10 bg-zinc-900/40 overflow-hidden">
          <p className="px-4 py-2 text-xs font-medium text-zinc-400 border-b border-white/10">
            Tài khoản NCC ({accounts.length})
          </p>
          {accounts.length === 0 ? (
            <p className="px-4 py-3 text-sm text-zinc-500">Chưa có tài khoản nào.</p>
          ) : (
            <div className="max-h-80 overflow-auto">
              <table className="w-full text-left text-sm">
                <thead className="text-xs text-zinc-500 sticky top-0 bg-zinc-900/95">
                  <tr>
                    <th className="px-4 py-2 font-medium">Tên đăng nhập</th>
                    <th className="px-4 py-2 font-medium">NCC</th>
                    <th className="px-4 py-2 font-medium">Tên hiển thị</th>
                    <th className="px-4 py-2 font-medium w-36 text-right">Thao tác</th>
                  </tr>
                </thead>
                <tbody>
                  {accounts.map((a) => (
                    <tr key={a.id} className="border-t border-white/5 text-zinc-300">
                      <td className="px-4 py-2 font-mono text-xs">{a.username}</td>
                      <td className="px-4 py-2">{a.providerName ?? "—"}</td>
                      <td className="px-4 py-2">{a.name}</td>
                      <td className="px-4 py-2 text-right whitespace-nowrap">
                        <button
                          type="button"
                          onClick={() => openEdit(a)}
                          className="text-sky-400 hover:text-sky-300 text-xs mr-3"
                        >
                          Sửa
                        </button>
                        <button
                          type="button"
                          disabled={deletingId === a.id}
                          onClick={() => onDelete(a)}
                          className="text-rose-400 hover:text-rose-300 text-xs disabled:opacity-50"
                        >
                          {deletingId === a.id ? "…" : "Xóa"}
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      ) : null}

      {loading ? <p className="text-sm text-zinc-500">Đang tải…</p> : null}
      {error ? <p className="text-sm text-rose-400">{error}</p> : null}
      {done ? <p className="text-sm text-emerald-400">{done}</p> : null}

      <form
        onSubmit={onSubmitCreate}
        className="space-y-4 rounded-xl border border-white/10 bg-zinc-900/40 p-4"
      >
        <p className="text-xs font-medium text-zinc-400">2. Tạo tài khoản đăng nhập NCC</p>
        <div>
          <label className="block text-xs text-zinc-400">Nhà cung cấp</label>
          <select
            value={providerId}
            onChange={(e) => setProviderId(e.target.value)}
            className="mt-1 w-full rounded-md border border-white/10 bg-zinc-950 px-3 py-2 text-sm outline-none focus:border-sky-500/60"
            required
          >
            {providers.map((p) => (
              <option key={p.id} value={p.id}>
                {p.name}
              </option>
            ))}
          </select>
        </div>
        <div>
          <label className="block text-xs text-zinc-400">Tên đăng nhập (3–32 ký tự: chữ, số, gạch dưới)</label>
          <input
            type="text"
            autoComplete="off"
            spellCheck={false}
            value={username}
            onChange={(e) => setUsername(e.target.value)}
            className="mt-1 w-full rounded-md border border-white/10 bg-zinc-950 px-3 py-2 text-sm outline-none focus:border-sky-500/60"
            required
            minLength={3}
            maxLength={32}
            pattern="[a-zA-Z0-9_]{3,32}"
          />
        </div>
        <div>
          <label className="block text-xs text-zinc-400">Họ tên hiển thị (tùy chọn — mặc định = tên đăng nhập)</label>
          <input
            value={name}
            onChange={(e) => setName(e.target.value)}
            className="mt-1 w-full rounded-md border border-white/10 bg-zinc-950 px-3 py-2 text-sm outline-none focus:border-sky-500/60"
            placeholder="Để trống = dùng tên đăng nhập"
          />
        </div>
        <div>
          <label className="block text-xs text-zinc-400">Mật khẩu ban đầu (8–64 ký tự, chữ + số)</label>
          <input
            type="password"
            autoComplete="new-password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            className="mt-1 w-full rounded-md border border-white/10 bg-zinc-950 px-3 py-2 text-sm outline-none focus:border-sky-500/60"
            required
            minLength={8}
          />
        </div>
        <button
          type="submit"
          disabled={submitting || providers.length === 0}
          className="w-full rounded-md bg-sky-600 py-2 text-sm font-medium text-white hover:bg-sky-500 disabled:opacity-50"
        >
          {submitting ? "Đang tạo…" : "Tạo tài khoản NCC"}
        </button>
      </form>

      {editing ? (
        <div
          className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 px-4 py-8"
          role="dialog"
          aria-modal="true"
          aria-labelledby="edit-ncc-title"
        >
          <div className="w-full max-w-md rounded-xl border border-white/10 bg-zinc-900 p-5 shadow-xl">
            <h2 id="edit-ncc-title" className="text-base font-semibold text-white">
              Sửa tài khoản NCC
            </h2>
            <p className="mt-1 text-xs text-zinc-500">
              {isNccSyntheticEmail(editing.email)
                ? "Đổi tên đăng nhập, tên hiển thị, NCC hoặc mật khẩu."
                : "Tài khoản đăng nhập bằng email — không đổi tên đăng nhập kiểu NCC tại đây. Có thể sửa tên, NCC, mật khẩu."}
            </p>
            <form onSubmit={onSubmitEdit} className="mt-4 space-y-3">
              <div>
                <label className="block text-xs text-zinc-400">Tên đăng nhập</label>
                <input
                  type="text"
                  spellCheck={false}
                  autoComplete="off"
                  value={editUsername}
                  onChange={(e) => setEditUsername(e.target.value)}
                  disabled={!isNccSyntheticEmail(editing.email)}
                  className="mt-1 w-full rounded-md border border-white/10 bg-zinc-950 px-3 py-2 text-sm outline-none focus:border-sky-500/60 disabled:opacity-60 disabled:cursor-not-allowed"
                  minLength={isNccSyntheticEmail(editing.email) ? 3 : undefined}
                  maxLength={isNccSyntheticEmail(editing.email) ? 32 : undefined}
                  pattern={isNccSyntheticEmail(editing.email) ? "[a-zA-Z0-9_]{3,32}" : undefined}
                  required={isNccSyntheticEmail(editing.email)}
                />
              </div>
              <div>
                <label className="block text-xs text-zinc-400">Họ tên hiển thị</label>
                <input
                  value={editName}
                  onChange={(e) => setEditName(e.target.value)}
                  className="mt-1 w-full rounded-md border border-white/10 bg-zinc-950 px-3 py-2 text-sm outline-none focus:border-sky-500/60"
                  minLength={2}
                  required
                />
              </div>
              <div>
                <label className="block text-xs text-zinc-400">Nhà cung cấp</label>
                <select
                  value={editProviderId}
                  onChange={(e) => setEditProviderId(e.target.value)}
                  className="mt-1 w-full rounded-md border border-white/10 bg-zinc-950 px-3 py-2 text-sm outline-none focus:border-sky-500/60"
                  required
                >
                  {providers.map((p) => (
                    <option key={p.id} value={p.id}>
                      {p.name}
                    </option>
                  ))}
                </select>
              </div>
              <div>
                <label className="block text-xs text-zinc-400">Mật khẩu mới (để trống = giữ nguyên)</label>
                <input
                  type="password"
                  autoComplete="new-password"
                  value={editPassword}
                  onChange={(e) => setEditPassword(e.target.value)}
                  className="mt-1 w-full rounded-md border border-white/10 bg-zinc-950 px-3 py-2 text-sm outline-none focus:border-sky-500/60"
                  minLength={8}
                />
              </div>
              <div className="flex gap-2 pt-2">
                <button
                  type="submit"
                  disabled={savingEdit}
                  className="flex-1 rounded-md bg-sky-600 py-2 text-sm font-medium text-white hover:bg-sky-500 disabled:opacity-50"
                >
                  {savingEdit ? "Đang lưu…" : "Lưu"}
                </button>
                <button
                  type="button"
                  onClick={closeEdit}
                  className="rounded-md border border-white/15 px-4 py-2 text-sm text-zinc-300 hover:bg-white/5"
                >
                  Hủy
                </button>
              </div>
            </form>
          </div>
        </div>
      ) : null}
    </div>
  );
}
