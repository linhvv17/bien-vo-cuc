import { motion } from "framer-motion";
import { MapPin, Car, Navigation, ExternalLink } from "lucide-react";

const routes = [
  { from: "Hà Nội", distance: "~140km", time: "~2.5 tiếng", via: "QL10" },
  { from: "Hải Phòng", distance: "~80km", time: "~1.5 tiếng", via: "QL10" },
];

/** Mapbox Static Images — token **public** (pk.*), không hardcode trong repo (GitHub secret scanning). */
function mapboxStaticPreviewUrl(token: string): string {
  const t = token.trim();
  return `https://api.mapbox.com/styles/v1/mapbox/streets-v12/static/pin-l-marker+E8834A(106.6192557,20.5774021)/106.6192557,20.5774021,12,0/600x400@2x?access_token=${encodeURIComponent(t)}`;
}

export default function DirectionsSection() {
  const mapboxToken = import.meta.env.VITE_MAPBOX_PUBLIC_TOKEN?.trim();
  const mapImageSrc = mapboxToken ? mapboxStaticPreviewUrl(mapboxToken) : null;
  return (
    <section className="section-light py-16 md:py-24">
      <div className="container">
        <motion.h2
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="font-display text-3xl md:text-4xl font-bold text-foreground text-center mb-12"
        >
          Cách Đến Biển Vô Cực
        </motion.h2>

        <div className="grid md:grid-cols-2 gap-8 max-w-5xl mx-auto">
          {/* Left: Info */}
          <div className="space-y-4">
            {routes.map((r, i) => (
              <motion.div
                key={i}
                initial={{ opacity: 0, x: -20 }}
                whileInView={{ opacity: 1, x: 0 }}
                viewport={{ once: true }}
                transition={{ delay: i * 0.1 }}
                className="bg-card rounded-xl p-5 shadow-sm border border-border"
              >
                <div className="flex items-center gap-3 mb-2">
                  <Car className="text-primary" size={20} />
                  <span className="font-semibold">Từ {r.from}</span>
                </div>
                <p className="text-sm text-muted-foreground ml-8">
                  {r.distance} • {r.time} (via {r.via})
                </p>
              </motion.div>
            ))}

            <motion.div
              initial={{ opacity: 0, x: -20 }}
              whileInView={{ opacity: 1, x: 0 }}
              viewport={{ once: true }}
              transition={{ delay: 0.2 }}
              className="bg-card rounded-xl p-5 shadow-sm border border-border"
            >
              <div className="flex items-center gap-3 mb-2">
                <MapPin className="text-primary" size={20} />
                <span className="font-semibold">Địa chỉ</span>
              </div>
              <p className="text-sm text-muted-foreground ml-8">
                Xã Thụy Xuân, Huyện Thái Thụy, Tỉnh Thái Bình
              </p>
            </motion.div>

            <motion.div
              initial={{ opacity: 0, x: -20 }}
              whileInView={{ opacity: 1, x: 0 }}
              viewport={{ once: true }}
              transition={{ delay: 0.3 }}
              className="bg-card rounded-xl p-5 shadow-sm border border-border"
            >
              <div className="flex items-center gap-3 mb-2">
                <Navigation className="text-primary" size={20} />
                <span className="font-semibold">Tọa độ</span>
              </div>
              <p className="text-sm text-muted-foreground ml-8">20.5774°N, 106.6193°E</p>
            </motion.div>
          </div>

          {/* Right: Map placeholder */}
          <motion.div
            initial={{ opacity: 0, x: 20 }}
            whileInView={{ opacity: 1, x: 0 }}
            viewport={{ once: true }}
            className="rounded-xl overflow-hidden min-h-[300px] md:min-h-[400px] relative bg-surface"
          >
            {mapImageSrc ? (
              <img
                src={mapImageSrc}
                alt="Bản đồ Biển Vô Cực - Thụy Xuân, Thái Thụy, Thái Bình"
                className="w-full h-full object-cover absolute inset-0"
                loading="lazy"
              />
            ) : (
              <div
                className="absolute inset-0 bg-gradient-to-br from-slate-800 via-slate-700 to-slate-900"
                role="img"
                aria-label="Khu vực bãi biển (thêm VITE_MAPBOX_PUBLIC_TOKEN để hiện ảnh Mapbox)"
              />
            )}
            <div className="absolute inset-0 flex flex-col items-center justify-center bg-ocean/30">
              <MapPin className="text-primary mb-3 drop-shadow-lg" size={48} />
              <h3 className="font-display text-lg font-bold text-ocean-foreground mb-1 drop-shadow">
                Biển Vô Cực
              </h3>
              <p className="text-ocean-foreground/80 text-sm mb-4 drop-shadow">
                Thụy Xuân, Thái Thụy, Thái Bình
              </p>
              <a
                href="https://maps.app.goo.gl/WP2bvGszwnZPFeZk9"
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center gap-2 bg-primary text-primary-foreground px-6 py-3 rounded-lg font-semibold hover:brightness-110 transition shadow-lg"
              >
                <ExternalLink size={16} /> Mở Google Maps
              </a>
            </div>
          </motion.div>
        </div>
      </div>
    </section>
  );
}
