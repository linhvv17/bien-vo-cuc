import { useEffect } from "react";
import { useLocation } from "react-router-dom";
import StickyNav from "@/components/StickyNav";
import HeroSection from "@/components/HeroSection";
import WeatherSection from "@/components/WeatherSection";
import GallerySection from "@/components/GallerySection";
import ServicesSection from "@/components/ServicesSection";
import DirectionsSection from "@/components/DirectionsSection";
import FooterSection from "@/components/FooterSection";

const Index = () => {
  const { hash } = useLocation();

  useEffect(() => {
    if (!hash || hash === "#") return;
    const id = hash.replace(/^#/, "");
    const el = document.getElementById(id);
    if (!el) return;
    const t = window.setTimeout(() => {
      el.scrollIntoView({ behavior: "smooth", block: "start" });
    }, 80);
    return () => window.clearTimeout(t);
  }, [hash]);

  return (
    <div className="min-h-screen">
      <StickyNav />
      <HeroSection />
      <WeatherSection />
      <GallerySection />
      <ServicesSection />
      <DirectionsSection />
      <FooterSection />
    </div>
  );
};

export default Index;
