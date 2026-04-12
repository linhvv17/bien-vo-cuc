import { AdminLoadError } from "@/components/admin-load-error";
import { apiGet, describeFetchFailure } from "@/lib/api";
import { ComboEditor } from "./combo-editor";

type ServiceItem = {
  id: string;
  type: "ACCOMMODATION" | "FOOD" | "TOUR" | "VEHICLE";
  name: string;
  price: number;
  isActive: boolean;
};

type Combo = {
  id: string;
  title?: string | null;
  discountPercent: number;
  isActive: boolean;
  hotel: ServiceItem;
  food: ServiceItem;
  createdAt: string;
};

export default async function CombosPage() {
  let combosRes: { data: Combo[] };
  let hotelsRes: { data: ServiceItem[] };
  let foodsRes: { data: ServiceItem[] };
  let loadError: string | null = null;
  try {
    [combosRes, hotelsRes, foodsRes] = await Promise.all([
      apiGet<Combo[]>("/combos"),
      apiGet<ServiceItem[]>("/services?type=ACCOMMODATION&limit=50"),
      apiGet<ServiceItem[]>("/services?type=FOOD&limit=50"),
    ]);
  } catch (e) {
    loadError = describeFetchFailure(e);
    combosRes = { data: [] };
    hotelsRes = { data: [] };
    foodsRes = { data: [] };
  }

  return (
    <div className="space-y-4">
      <div>
        <h1 className="text-xl font-semibold">Combo</h1>
        <p className="text-sm text-zinc-400">
          Tạo combo bằng cách chọn 1 khách sạn + 1 ăn uống. Discount mặc định 10% và sửa sau được.
        </p>
      </div>

      {loadError && <AdminLoadError message={loadError} />}

      <ComboEditor combos={combosRes.data} hotels={hotelsRes.data} foods={foodsRes.data} />
    </div>
  );
}

