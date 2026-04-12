import { AdminLoadError } from "@/components/admin-load-error";
import { apiGet, describeFetchFailure } from "@/lib/api";
import { ServiceEditor } from "./service-editor";

type ServiceItem = {
  id: string;
  type: "ACCOMMODATION" | "FOOD" | "TOUR" | "VEHICLE";
  name: string;
  description: string;
  price: number;
  maxCapacity: number;
  isActive: boolean;
  createdAt: string;
};

export default async function ServicesPage({
  searchParams,
}: {
  searchParams: Promise<{ type?: string }>;
}) {
  const sp = await searchParams;
  const type = (sp.type ?? "ACCOMMODATION") as ServiceItem["type"];

  let data: ServiceItem[] = [];
  let meta: Record<string, unknown> | undefined;
  let loadError: string | null = null;
  try {
    const res = await apiGet<ServiceItem[]>(`/services?type=${encodeURIComponent(type)}`);
    data = res.data;
    meta = res.meta;
  } catch (e) {
    loadError = describeFetchFailure(e);
  }

  if (loadError) {
    return (
      <div className="space-y-4">
        <h1 className="text-xl font-semibold">Dịch vụ</h1>
        <AdminLoadError title="Không tải được danh sách" message={loadError} />
      </div>
    );
  }

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-xl font-semibold">Dịch vụ</h1>
          <p className="text-sm text-zinc-400">Khách sạn & ăn uống (nhập từ Admin)</p>
        </div>
        <div className="flex gap-2">
          <Tab href="/services?type=ACCOMMODATION" active={type === "ACCOMMODATION"}>
            Khách sạn
          </Tab>
          <Tab href="/services?type=FOOD" active={type === "FOOD"}>
            Ăn uống
          </Tab>
        </div>
      </div>

      <div className="flex items-center justify-between rounded-xl border border-white/10 bg-white/5 px-4 py-3">
        <div className="text-sm text-zinc-300">
          Total: <span className="font-semibold">{String(meta?.total ?? data.length)}</span>
        </div>
        <div className="text-xs text-zinc-500">page {String(meta?.page ?? 1)}</div>
      </div>

      <ServiceEditor type={type} initialItems={data} />
    </div>
  );
}

function Tab({ href, active, children }: { href: string; active: boolean; children: React.ReactNode }) {
  return (
    <a
      href={href}
      className={
        "rounded-full px-3 py-1.5 text-sm transition " +
        (active ? "bg-white/15 text-white" : "bg-white/5 text-zinc-300 hover:bg-white/10")
      }
    >
      {children}
    </a>
  );
}

