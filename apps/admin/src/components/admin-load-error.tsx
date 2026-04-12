export function AdminLoadError({
  title = "Không tải được dữ liệu",
  message,
}: {
  title?: string;
  message: string;
}) {
  return (
    <div className="rounded-xl border border-amber-500/30 bg-amber-500/10 px-4 py-4 text-sm text-amber-100">
      <p className="font-medium">{title}</p>
      <p className="mt-2 text-amber-200/90">{message}</p>
    </div>
  );
}
