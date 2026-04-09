"use client";

import { useState, useEffect, useRef } from "react";
import dynamic from "next/dynamic";

const GradientBackground = dynamic(() => import("shadergradient").then((mod) => {
  const { ShaderGradientCanvas, ShaderGradient } = mod;
  function Gradient() {
    const [ready, setReady] = useState(false);
    useEffect(() => {
      // Delay reveal so the shader settles into its configured state
      const timer = setTimeout(() => setReady(true), 600);
      return () => clearTimeout(timer);
    }, []);
    return (
      <div style={{
        width: "100%", height: "100%",
        opacity: ready ? 1 : 0,
        transition: "opacity 0.8s ease-in",
      }}>
        <ShaderGradientCanvas
          style={{ width: "100%", height: "100%", pointerEvents: "none" }}
        >
          <ShaderGradient
            animate="on"
            brightness={1}
            cAzimuthAngle={180}
            cDistance={2.8}
            cPolarAngle={80}
            cameraZoom={9.1}
            color1="#606080"
            color2="#8d7dca"
            color3="#212121"
            envPreset="city"
            grain="on"
            lightType="3d"
            positionX={0}
            positionY={0}
            positionZ={0}
            reflection={0.1}
            rotationX={50}
            rotationY={0}
            rotationZ={-60}
            type="waterPlane"
            uAmplitude={0}
            uDensity={1.5}
            uFrequency={0}
            uSpeed={0.3}
            uStrength={1.5}
            uTime={8}
          />
        </ShaderGradientCanvas>
      </div>
    );
  }
  return { default: Gradient };
}), { ssr: false });

/* ------------------------------------------------------------------ */
/*  Scroll-reveal hook (per Act, triggers at 20% visibility)           */
/* ------------------------------------------------------------------ */

function useActReveal() {
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;

    const prefersReduced = window.matchMedia(
      "(prefers-reduced-motion: reduce)"
    ).matches;
    if (prefersReduced) {
      el.classList.add("visible");
      return;
    }

    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          el.classList.add("visible");
          observer.unobserve(el);
        }
      },
      { threshold: 0.2 }
    );

    observer.observe(el);
    return () => observer.disconnect();
  }, []);

  return ref;
}

/* ------------------------------------------------------------------ */
/*  ClippyBar Logo SVG                                                   */
/* ------------------------------------------------------------------ */

function ClippyBarLogo({
  size = 24,
  fill = "#1D1D1F",
  className = "",
}: {
  size?: number;
  fill?: string;
  className?: string;
}) {
  const h = size;
  const w = Math.round((188 / 232) * size);
  return (
    <svg
      width={w}
      height={h}
      viewBox="0 0 188 232"
      xmlns="http://www.w3.org/2000/svg"
      className={className}
      aria-hidden="true"
    >
      <path
        fill={fill}
        fillRule="evenodd"
        d="M 114.00 45.00 C 110.00 43.83, 102.67 42.50, 99.00 42.00 C 95.33 41.50, 96.17 41.33, 92.00 42.00 C 87.83 42.67, 78.83 44.33, 74.00 46.00 C 69.17 47.67, 66.50 49.50, 63.00 52.00 C 59.50 54.50, 55.67 58.00, 53.00 61.00 C 50.33 64.00, 47.00 69.83, 45.00 74.00 C 43.00 78.17, 41.67 86.00, 41.00 91.00 C 40.33 96.00, 40.33 107.67, 41.00 113.00 C 41.67 118.33, 43.17 126.67, 44.00 131.00 C 44.83 135.33, 46.83 143.17, 48.00 146.00 C 49.17 148.83, 52.17 154.00, 54.00 156.00 C 55.83 158.00, 59.17 161.67, 61.00 163.00 C 62.83 164.33, 67.17 166.67, 70.00 168.00 C 72.83 169.33, 78.83 171.17, 83.00 172.00 C 87.17 172.83, 94.83 173.67, 100.00 174.00 C 105.17 174.33, 111.17 174.00, 114.00 174.00 C 116.83 174.00, 122.17 173.17, 125.00 172.00 C 127.83 170.83, 132.50 168.00, 135.00 166.00 C 137.50 164.00, 141.17 159.67, 143.00 156.00 C 144.83 152.33, 146.83 145.83, 148.00 141.00 C 149.17 136.17, 150.00 126.67, 150.00 120.00 C 150.00 113.33, 149.17 103.50, 148.00 98.00 C 146.83 92.50, 144.67 85.17, 143.00 82.00 C 141.33 78.83, 137.83 74.33, 135.00 72.00 C 132.17 69.67, 126.50 66.83, 122.00 66.00 C 117.50 65.17, 108.33 65.33, 103.00 66.00 C 97.67 66.67, 89.33 69.00, 85.00 71.00 C 80.67 73.00, 75.67 77.00, 74.00 79.00 C 72.33 81.00, 70.33 84.67, 70.00 87.00 C 69.67 89.33, 69.67 96.67, 70.00 100.00 C 70.33 103.33, 71.67 109.50, 73.00 113.00 C 74.33 116.50, 77.00 122.33, 79.00 125.00 C 81.00 127.67, 84.67 131.33, 87.00 133.00 C 89.33 134.67, 93.67 136.83, 96.00 137.00 C 98.33 137.17, 102.50 136.83, 105.00 136.00 C 107.50 135.17, 110.83 133.67, 112.00 132.00 C 113.17 130.33, 114.00 126.67, 114.00 124.00 C 114.00 121.33, 113.17 117.17, 112.00 115.00 C 110.83 112.83, 108.00 109.83, 106.00 108.00 C 104.00 106.17, 100.83 103.33, 99.00 102.00 C 97.17 100.67, 95.00 98.50, 95.00 97.00 C 95.00 95.50, 95.67 93.33, 97.00 92.00 C 98.33 90.67, 101.33 89.00, 104.00 89.00 C 106.67 89.00, 111.17 90.17, 114.00 92.00 C 116.83 93.83, 120.33 97.33, 122.00 100.00 C 123.67 102.67, 125.50 107.50, 126.00 111.00 C 126.50 114.50, 126.33 121.33, 126.00 125.00 C 125.67 128.67, 124.50 133.83, 123.00 137.00 C 121.50 140.17, 118.50 144.33, 116.00 146.00 C 113.50 147.67, 108.67 149.67, 105.00 150.00 C 101.33 150.33, 95.83 149.83, 93.00 149.00 C 90.17 148.17, 85.33 146.00, 83.00 144.00 C 80.67 142.00, 76.83 137.50, 74.00 134.00 C 71.17 130.50, 67.83 125.00, 66.00 122.00 C 64.17 119.00, 62.33 114.00, 61.00 111.00 C 59.67 108.00, 58.33 101.83, 58.00 97.00 C 57.67 92.17, 58.00 83.83, 58.00 80.00 C 58.00 76.17, 59.33 70.50, 61.00 67.00 C 62.67 63.50, 66.33 58.50, 69.00 56.00 C 71.67 53.50, 77.50 50.33, 82.00 49.00 C 86.50 47.67, 94.00 46.00, 98.00 46.00 C 102.00 46.00, 110.00 46.17, 114.00 45.00 Z"
      />
    </svg>
  );
}

/* ------------------------------------------------------------------ */
/*  Icon components                                                    */
/* ------------------------------------------------------------------ */

function MenuIcon() {
  return (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <line x1="4" y1="6" x2="20" y2="6" />
      <line x1="4" y1="12" x2="20" y2="12" />
      <line x1="4" y1="18" x2="20" y2="18" />
    </svg>
  );
}

function CloseIcon() {
  return (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <line x1="18" y1="6" x2="6" y2="18" />
      <line x1="6" y1="6" x2="18" y2="18" />
    </svg>
  );
}

function PlusIcon({ className }: { className?: string }) {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className={className}>
      <line x1="12" y1="5" x2="12" y2="19" />
      <line x1="5" y1="12" x2="19" y2="12" />
    </svg>
  );
}

function AppleIcon() {
  return (
    <svg width="14" height="14" viewBox="0 0 14 14" fill="none" xmlns="http://www.w3.org/2000/svg">
      <path
        d="M11.182 7.455c-.02-1.91 1.558-2.826 1.629-2.872-.887-1.296-2.267-1.474-2.759-1.494-1.174-.119-2.293.691-2.89.691-.597 0-1.52-.674-2.498-.656-1.285.019-2.47.747-3.131 1.899-1.335 2.315-.342 5.746.958 7.627.636.919 1.393 1.951 2.389 1.914.959-.038 1.321-.62 2.482-.62 1.161 0 1.492.62 2.511.6 1.031-.018 1.683-.937 2.316-1.858.73-1.066 1.031-2.098 1.049-2.152-.023-.01-2.013-.773-2.032-3.066l-.024.007zM9.286 2.048c.529-.641.886-1.531.789-2.419-.762.031-1.685.508-2.231 1.148-.49.567-.919 1.473-.804 2.342.851.066 1.719-.432 2.246-1.071z"
        fill="#86868B"
      />
    </svg>
  );
}

function DownArrowIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M12 5v14" />
      <path d="m19 12-7 7-7-7" />
    </svg>
  );
}

function CheckmarkIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#34C759" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
      <polyline points="20 6 9 17 4 12" />
    </svg>
  );
}

/* ------------------------------------------------------------------ */
/*  Data                                                               */
/* ------------------------------------------------------------------ */

// TODO: Replace with actual App Store ID once available
const APP_STORE_URL = "https://apps.apple.com/app/clippybar/id#"; // placeholder


const tabData = [
  {
    id: "history",
    label: "History",
    title: "Never lose a copy again",
    description:
      "Every text, link, and snippet you copy is saved automatically. Scroll through your full clipboard history and pick exactly what you need.",
    shortcut: null,
    illustration: "history",
  },
  {
    id: "search",
    label: "Search",
    title: "Find anything instantly",
    description:
      "Start typing to filter your entire clipboard history in milliseconds. No more hunting through windows or tabs for that one thing you copied.",
    shortcut: null,
    illustration: "search",
  },
  {
    id: "shortcuts",
    label: "Shortcuts",
    title: "One shortcut. Fully yours.",
    description:
      "Default Option+V opens ClippyBar anywhere. Customize it in Settings to any key combination that fits your workflow.",
    shortcut: true,
    illustration: "shortcuts",
  },
  {
    id: "pinning",
    label: "Pinning",
    title: "Keep the important stuff",
    description:
      "Pin frequently-used snippets to the top of your picker. They stay there until you unpin them, no matter how many new items you copy.",
    shortcut: null,
    illustration: "pinning",
  },
  {
    id: "exclusions",
    label: "Exclusions",
    title: "Block sensitive apps",
    description:
      "Automatically disable clipboard monitoring for password managers, banking apps, and anything else you want to keep private.",
    shortcut: null,
    illustration: "exclusions",
  },
  {
    id: "autopaste",
    label: "Auto-Paste",
    title: "Select and paste in one motion",
    description:
      "When Auto-Paste is on, selecting an item immediately pastes it into the active app. One step instead of two. Toggle on or off anytime.",
    shortcut: null,
    illustration: "autopaste",
  },
];

const faqs = [
  {
    question: "What permissions does ClippyBar need?",
    answer:
      "ClippyBar requires Accessibility permission to register global hotkeys and optionally paste for you. This is a standard macOS permission for productivity apps. No other permissions are needed.",
  },
  {
    question: "Is ClippyBar really free?",
    answer:
      "Yes, ClippyBar is completely free. No ads, no subscriptions, no data collection. Ever.",
  },
  {
    question: "Can I change the keyboard shortcut?",
    answer:
      "Open ClippyBar settings from the menu bar icon and click the hotkey recorder to set any key combination you prefer.",
  },
  {
    question: "How do I uninstall ClippyBar?",
    answer:
      "Quit ClippyBar from the menu bar, then drag it to Trash. To remove all data, also delete ~/Library/Application Support/ClippyBar/.",
  },
  {
    question: "Is it safe with password managers?",
    answer:
      "You can exclude specific apps like 1Password or banking apps from clipboard monitoring. ClippyBar also supports Memory Only mode where nothing is written to disk.",
  },
];

const privacyPoints = [
  "All data stored locally",
  "Zero network connections",
  "Optional memory-only mode",
  "Exclude sensitive apps",
];

/* ------------------------------------------------------------------ */
/*  Navigation                                                         */
/* ------------------------------------------------------------------ */

function Navigation() {
  const [mobileOpen, setMobileOpen] = useState(false);
  const [scrolled, setScrolled] = useState(false);

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 50);
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  useEffect(() => {
    if (mobileOpen) {
      document.body.style.overflow = "hidden";
    } else {
      document.body.style.overflow = "";
    }
    return () => {
      document.body.style.overflow = "";
    };
  }, [mobileOpen]);

  const navLinks = [
    { href: "#features", label: "Features" },
    { href: "#privacy", label: "Privacy" },
    { href: "#faq", label: "FAQ" },
  ];

  return (
    <nav
      className={scrolled ? "nav-scrolled" : "nav-top"}
      style={{ transition: "all 0.3s ease" }}
    >
      <div className="mx-auto max-w-[1200px] px-4 sm:px-6 lg:px-8">
        <div className="flex h-14 items-center justify-between">
          {/* Logo */}
          <a href="#" className="flex items-center gap-2" style={{ transition: "opacity 0.3s" }}>
            <span className="hidden sm:inline"><ClippyBarLogo size={72} fill={scrolled ? "#1D1D1F" : "#ffffff"} /></span>
            <span className="sm:hidden"><ClippyBarLogo size={48} fill={scrolled ? "#1D1D1F" : "#ffffff"} /></span>
            <span style={{ fontSize: 20, fontWeight: 600, color: scrolled ? "#1D1D1F" : "#ffffff", transition: "color 0.3s" }}>
              ClippyBar
            </span>
          </a>

          {/* Desktop links */}
          <div className="hidden md:flex items-center gap-7">
            {navLinks.map((link) => (
              <a
                key={link.href}
                href={link.href}
                className="link-hover"
                style={{ fontSize: 14, color: scrolled ? "#1D1D1F" : "#ffffff", textDecoration: "none", transition: "color 0.3s" }}
              >
                {link.label}
              </a>
            ))}
            <a href={APP_STORE_URL} className={scrolled ? "btn-nav" : "btn-nav-light"}>
              Mac App Store
            </a>
          </div>

          {/* Mobile menu button */}
          <button
            className="md:hidden"
            style={{ color: scrolled ? "#1D1D1F" : "#ffffff", transition: "color 0.3s" }}
            onClick={() => setMobileOpen(!mobileOpen)}
            aria-label={mobileOpen ? "Close menu" : "Open menu"}
          >
            {mobileOpen ? <CloseIcon /> : <MenuIcon />}
          </button>
        </div>
      </div>

      {/* Mobile overlay */}
      {mobileOpen && (
        <div
          className="md:hidden fixed inset-0 top-14 z-40 glass mobile-menu-enter"
          style={{ display: "flex", flexDirection: "column" }}
        >
          <div className="px-6 py-8 flex flex-col gap-2">
            {navLinks.map((link) => (
              <a
                key={link.href}
                href={link.href}
                style={{
                  fontSize: 17,
                  color: "#1D1D1F",
                  textDecoration: "none",
                  padding: "14px 16px",
                  borderRadius: 12,
                }}
                className="link-hover"
                onClick={() => setMobileOpen(false)}
              >
                {link.label}
              </a>
            ))}
            <div style={{ paddingTop: 16 }}>
              <a
                href={APP_STORE_URL}
                className="btn-primary"
                style={{ width: "100%", textAlign: "center" }}
                onClick={() => setMobileOpen(false)}
              >
                Download on the Mac App Store
              </a>
            </div>
          </div>
        </div>
      )}
    </nav>
  );
}

/* ------------------------------------------------------------------ */
/*  ACT 1: THE HOOK — Hero + Live Demo (~100vh)                        */
/* ------------------------------------------------------------------ */

function HeroAppMockup() {
  return (
    <div className="hero-mockup-wrapper">
      {/* macOS desktop frame */}
      <div className="hero-desktop-frame">
        {/* Menu bar */}
        <div style={{
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          padding: "4px 16px",
          background: "rgba(30,30,40,0.95)",
          backdropFilter: "blur(20px)",
          fontSize: 13,
          color: "rgba(255,255,255,0.9)",
          fontWeight: 500,
        }}>
          <div style={{ display: "flex", alignItems: "center", gap: 16 }}>
            <svg width="14" height="14" viewBox="0 0 24 24" fill="rgba(255,255,255,0.9)">
              <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/>
            </svg>
            <span>Finder</span>
            <span style={{ opacity: 0.7 }}>File</span>
            <span style={{ opacity: 0.7 }}>Edit</span>
            <span style={{ opacity: 0.7 }}>View</span>
          </div>
          <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
            <ClippyBarLogo size={16} fill="rgba(255,255,255,0.9)" />
            <span style={{ fontSize: 12, opacity: 0.7 }}>Tue 3:42 PM</span>
          </div>
        </div>

        {/* Desktop wallpaper area */}
        <div style={{
          position: "relative",
          background: "linear-gradient(135deg, #1a1a2e 0%, #16213e 40%, #0f3460 100%)",
          minHeight: 420,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          overflow: "hidden",
        }}>
          {/* Soft glow spots on wallpaper */}
          <div style={{ position: "absolute", top: "20%", left: "30%", width: 300, height: 300, borderRadius: "50%", background: "radial-gradient(circle, rgba(88,86,214,0.15) 0%, transparent 70%)", filter: "blur(40px)", pointerEvents: "none" }} />
          <div style={{ position: "absolute", bottom: "10%", right: "20%", width: 250, height: 250, borderRadius: "50%", background: "radial-gradient(circle, rgba(0,122,255,0.1) 0%, transparent 70%)", filter: "blur(40px)", pointerEvents: "none" }} />

          {/* ClippyBar picker window — centered on desktop */}
          <div style={{
            background: "rgba(255,255,255,0.97)",
            borderRadius: 12,
            boxShadow: "0 25px 80px rgba(0,0,0,0.35), 0 0 0 0.5px rgba(255,255,255,0.1)",
            width: "min(400px, 80%)",
            overflow: "hidden",
          }}>
            {/* Title bar */}
            <div style={{
              display: "flex",
              alignItems: "center",
              gap: 12,
              padding: "12px 16px",
              borderBottom: "0.5px solid rgba(0,0,0,0.08)",
            }}>
              <div className="macos-dots">
                <div className="macos-dot macos-dot-red" />
                <div className="macos-dot macos-dot-yellow" />
                <div className="macos-dot macos-dot-green" />
              </div>
              <div style={{
                flex: 1,
                display: "flex",
                alignItems: "center",
                gap: 8,
                background: "rgba(0,0,0,0.04)",
                borderRadius: 8,
                padding: "6px 10px",
              }}>
                <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="#86868B" strokeWidth="2">
                  <circle cx="11" cy="11" r="8" />
                  <path d="m21 21-4.35-4.35" />
                </svg>
                <span style={{ fontSize: 13, color: "#86868B" }}>Search clipboard...</span>
              </div>
            </div>

            {/* Pinned section */}
            <div style={{ padding: "6px 12px 2px", fontSize: 10, color: "#86868B", textTransform: "uppercase", letterSpacing: "0.06em", fontWeight: 600 }}>Pinned</div>
            {[
              { text: "ssh deploy@prod.server.com", label: "CMD", cls: "pill-cmd" },
              { text: "hello@clippy.bar", label: "EMAIL", cls: "pill-email" },
            ].map((item, i) => (
              <div key={i} style={{
                display: "flex", alignItems: "center", height: 40, padding: "0 12px", gap: 10, margin: "0 8px", borderRadius: 8,
                background: "rgba(255,149,0,0.04)",
              }}>
                <svg width="10" height="10" viewBox="0 0 24 24" fill="#FF9500" stroke="#FF9500" strokeWidth="2"><path d="M12 17v5"/><path d="M9 10.76a2 2 0 0 1-1.11 1.79l-1.78.9A2 2 0 0 0 5 15.24V16h14v-.76a2 2 0 0 0-1.11-1.79l-1.78-.9A2 2 0 0 1 15 10.76V7a1 1 0 0 1 1-1 2 2 0 0 0 2-2H6a2 2 0 0 0 2 2 1 1 0 0 1 1 1z"/></svg>
                <span style={{ flex: 1, fontSize: 13, fontFamily: "SF Mono, Menlo, monospace", color: "#1D1D1F", overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{item.text}</span>
                <span className={`pill-badge ${item.cls}`} style={{ fontSize: 10 }}>{item.label}</span>
              </div>
            ))}

            {/* Recent section */}
            <div style={{ padding: "8px 12px 2px", fontSize: 10, color: "#86868B", textTransform: "uppercase", letterSpacing: "0.06em", fontWeight: 600, borderTop: "0.5px solid rgba(0,0,0,0.06)", marginTop: 4 }}>Recent</div>
            {[
              { text: "const api = await fetch(...)", label: "CODE", cls: "pill-code", active: true },
              { text: "https://github.com/clipbar", label: "URL", cls: "pill-url", active: false },
              { text: "Meeting notes: Q4 planning...", label: "NOTE", cls: "pill-note", active: false },
            ].map((item, i) => (
              <div key={i} style={{
                display: "flex", alignItems: "center", height: 40, padding: "0 12px", gap: 10, margin: "0 8px", borderRadius: 8,
                background: item.active ? "rgba(0,122,255,0.06)" : "transparent",
              }}>
                <span style={{ flex: 1, fontSize: 13, fontFamily: "SF Mono, Menlo, monospace", color: item.active ? "#007AFF" : "#1D1D1F", overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{item.text}</span>
                <span className={`pill-badge ${item.cls}`} style={{ fontSize: 10 }}>{item.label}</span>
              </div>
            ))}
            <div style={{ height: 8 }} />
          </div>
        </div>
      </div>
    </div>
  );
}

function Act1Hook() {
  const [starCount, setStarCount] = useState<number | null>(null);
  const [gradientKey, setGradientKey] = useState(() => Date.now());

  useEffect(() => {
    const onPageShow = (e: PageTransitionEvent) => {
      if (e.persisted) setGradientKey((k) => k + 1);
    };
    window.addEventListener("pageshow", onPageShow);
    return () => window.removeEventListener("pageshow", onPageShow);
  }, []);

  useEffect(() => {
    fetch("https://api.github.com/repos/panayar/Clippy")
      .then((r) => r.ok ? r.json() : null)
      .then((data) => {
        if (data?.stargazers_count != null) setStarCount(data.stargazers_count);
      })
      .catch(() => {});
  }, []);

  return (
    <section
      className="hero-section"
      style={{
        position: "relative",
        zIndex: 1,
        overflow: "hidden",
        display: "flex",
        flexDirection: "column",
      }}
    >
      {/* Shader gradient background */}
      <div
        key={gradientKey}
        style={{
          position: "absolute",
          top: -80,
          left: 0,
          right: 0,
          bottom: 0,
          zIndex: 0,
          opacity: 0.85,
          pointerEvents: "none",
        }}
      >
        <GradientBackground />
      </div>

      {/* Content overlay */}
      <div style={{ position: "relative", zIndex: 1, flex: 1, display: "flex", flexDirection: "column" }}>
        {/* Top section: text + app mockup */}
        <div className="mx-auto max-w-[1200px] px-4 sm:px-6 lg:px-8 w-full" style={{ flex: 1, display: "flex", flexDirection: "column", justifyContent: "center", paddingTop: 80 }}>
          {/* Bold headline overlaid */}
          <div className="hero-text-enter" style={{ marginBottom: 40 }}>
            <h1 className="hero-headline">
              EVERYTHING{" "}
              <span style={{ color: "rgba(175,130,255,0.9)", fontStyle: "italic" }}>YOU COPY,</span>
              <br />
              INSTANTLY
              <br />
              RECALLED
            </h1>
          </div>

          {/* App screenshot mockup */}
          <div className="hero-demo-enter">
            <HeroAppMockup />
          </div>
        </div>

        {/* Bottom feature pills bar */}
        <div className="hero-bottom-bar">
          <div className="mx-auto max-w-[1200px] px-4 sm:px-6 lg:px-8 w-full">
            <div className="hero-pills-row">
              <div className="hero-pill">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="rgba(255,255,255,0.7)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <rect x="9" y="9" width="13" height="13" rx="2" ry="2" />
                  <path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1" />
                </svg>
                <div>
                  <span className="hero-pill-label">History</span>
                  <span className="hero-pill-value">Unlimited</span>
                </div>
              </div>
              <div className="hero-pill">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="rgba(255,255,255,0.7)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9" />
                  <path d="M13.73 21a2 2 0 0 1-3.46 0" />
                </svg>
                <div>
                  <span className="hero-pill-label">Shortcut</span>
                  <span className="hero-pill-value">&#x2325;V</span>
                </div>
              </div>
              <div className="hero-pill">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="rgba(255,255,255,0.7)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <rect x="3" y="11" width="18" height="11" rx="2" ry="2" />
                  <path d="M7 11V7a5 5 0 0 1 10 0v4" />
                </svg>
                <div>
                  <span className="hero-pill-label">Privacy</span>
                  <span className="hero-pill-value">100% Local</span>
                </div>
              </div>
              <div className="hero-pill">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="rgba(255,255,255,0.7)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M12 2v20M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6" />
                </svg>
                <div>
                  <span className="hero-pill-label">Price</span>
                  <span className="hero-pill-value">Free</span>
                </div>
              </div>
              <a
                href={APP_STORE_URL}
                className="hero-pill-cta"
              >
                Download
              </a>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}

/* ------------------------------------------------------------------ */
/*  Tab Illustrations                                                  */
/* ------------------------------------------------------------------ */

function TabIllustration({ type }: { type: string }) {
  const miniWindowStyle: React.CSSProperties = {
    borderRadius: 8,
    overflow: "hidden",
    border: "0.5px solid rgba(0,0,0,0.06)",
    background: "rgba(255,255,255,0.8)",
    boxShadow: "0 4px 16px rgba(0,0,0,0.06)",
  };
  const miniBarStyle: React.CSSProperties = {
    display: "flex",
    alignItems: "center",
    gap: 4,
    padding: "6px 10px",
    borderBottom: "0.5px solid rgba(0,0,0,0.06)",
  };
  const miniDot: React.CSSProperties = {
    width: 6,
    height: 6,
    borderRadius: "50%",
  };
  const rowStyle: React.CSSProperties = {
    display: "flex",
    alignItems: "center",
    padding: "6px 10px",
    gap: 8,
    fontSize: 11,
    fontFamily: "SF Mono, Menlo, monospace",
  };

  if (type === "history") {
    return (
      <div style={miniWindowStyle}>
        <div style={miniBarStyle}>
          <div style={{ ...miniDot, background: "#FF5F57" }} />
          <div style={{ ...miniDot, background: "#FFBD2E" }} />
          <div style={{ ...miniDot, background: "#28C840" }} />
          <span style={{ flex: 1, textAlign: "center", fontSize: 10, color: "#86868B" }}>ClippyBar</span>
        </div>
        {["const api = fetch(...)", "https://github.com/...", "Meeting notes: Q4...", "ssh deploy@prod...", "hello@clippy.bar"].map(
          (t, i) => (
            <div key={i} style={{ ...rowStyle, background: i === 0 ? "rgba(0,122,255,0.06)" : "transparent" }}>
              <span style={{ color: i === 0 ? "#007AFF" : "#1D1D1F", flex: 1, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{t}</span>
              <span style={{ fontSize: 9, color: "#86868B" }}>{["5s", "2m", "8m", "15m", "1h"][i]}</span>
            </div>
          )
        )}
      </div>
    );
  }

  if (type === "search") {
    return (
      <div style={miniWindowStyle}>
        <div style={miniBarStyle}>
          <div style={{ ...miniDot, background: "#FF5F57" }} />
          <div style={{ ...miniDot, background: "#FFBD2E" }} />
          <div style={{ ...miniDot, background: "#28C840" }} />
        </div>
        <div style={{ padding: "6px 10px" }}>
          <div style={{ background: "rgba(0,0,0,0.04)", borderRadius: 6, padding: "4px 8px", fontSize: 11, color: "#1D1D1F", fontFamily: "SF Mono, Menlo, monospace" }}>
            github
          </div>
        </div>
        <div style={{ ...rowStyle, background: "rgba(0,122,255,0.06)" }}>
          <span style={{ color: "#007AFF", flex: 1 }}>https://<strong>github</strong>.com/clipbar</span>
          <span className="pill-badge pill-url" style={{ fontSize: 9 }}>URL</span>
        </div>
        <div style={{ ...rowStyle, opacity: 0.4 }}>
          <span style={{ color: "#86868B", flex: 1 }}>No more results</span>
        </div>
      </div>
    );
  }

  if (type === "shortcuts") {
    return (
      <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 16, padding: 20 }}>
        <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
          <span className="keycap">&#x2325;</span>
          <span style={{ color: "#86868B", fontSize: 16 }}>+</span>
          <span className="keycap">V</span>
        </div>
        <span style={{ fontSize: 12, color: "#86868B" }}>Customize in Settings</span>
      </div>
    );
  }

  if (type === "pinning") {
    return (
      <div style={miniWindowStyle}>
        <div style={miniBarStyle}>
          <div style={{ ...miniDot, background: "#FF5F57" }} />
          <div style={{ ...miniDot, background: "#FFBD2E" }} />
          <div style={{ ...miniDot, background: "#28C840" }} />
        </div>
        <div style={{ padding: "4px 10px 2px", fontSize: 9, color: "#86868B", textTransform: "uppercase", letterSpacing: "0.05em", fontWeight: 600 }}>Pinned</div>
        {["ssh deploy@prod...", "hello@clippy.bar"].map((t, i) => (
          <div key={i} style={{ ...rowStyle, background: "rgba(255,149,0,0.04)" }}>
            <svg width="10" height="10" viewBox="0 0 24 24" fill="#FF9500" stroke="#FF9500" strokeWidth="2"><path d="M12 17v5"/><path d="M9 10.76a2 2 0 0 1-1.11 1.79l-1.78.9A2 2 0 0 0 5 15.24V16h14v-.76a2 2 0 0 0-1.11-1.79l-1.78-.9A2 2 0 0 1 15 10.76V7a1 1 0 0 1 1-1 2 2 0 0 0 2-2H6a2 2 0 0 0 2 2 1 1 0 0 1 1 1z"/></svg>
            <span style={{ color: "#1D1D1F", flex: 1 }}>{t}</span>
          </div>
        ))}
        <div style={{ padding: "4px 10px 2px", fontSize: 9, color: "#86868B", textTransform: "uppercase", letterSpacing: "0.05em", fontWeight: 600, borderTop: "0.5px solid rgba(0,0,0,0.06)", marginTop: 2, paddingTop: 6 }}>Recent</div>
        <div style={rowStyle}>
          <span style={{ color: "#1D1D1F", flex: 1 }}>const api = fetch(...)</span>
        </div>
      </div>
    );
  }

  if (type === "exclusions") {
    return (
      <div style={miniWindowStyle}>
        <div style={miniBarStyle}>
          <div style={{ ...miniDot, background: "#FF5F57" }} />
          <div style={{ ...miniDot, background: "#FFBD2E" }} />
          <div style={{ ...miniDot, background: "#28C840" }} />
          <span style={{ flex: 1, textAlign: "center", fontSize: 10, color: "#86868B" }}>Excluded Apps</span>
        </div>
        {["1Password", "Chase Banking", "Signal"].map((app, i) => (
          <div key={i} style={{ ...rowStyle, justifyContent: "space-between" }}>
            <span style={{ color: "#1D1D1F", fontFamily: "inherit" }}>{app}</span>
            <div style={{ width: 28, height: 16, borderRadius: 8, background: "#34C759", position: "relative" }}>
              <div style={{ position: "absolute", right: 2, top: 2, width: 12, height: 12, borderRadius: "50%", background: "white", boxShadow: "0 1px 2px rgba(0,0,0,0.1)" }} />
            </div>
          </div>
        ))}
      </div>
    );
  }

  if (type === "autopaste") {
    return (
      <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 12, padding: 16 }}>
        <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
          <div style={{ padding: "6px 12px", background: "rgba(0,122,255,0.06)", borderRadius: 6, fontSize: 12, color: "#007AFF", fontFamily: "SF Mono, Menlo, monospace" }}>
            Select item
          </div>
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#86868B" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
            <path d="M5 12h14" />
            <path d="m12 5 7 7-7 7" />
          </svg>
          <div style={{ padding: "6px 12px", background: "rgba(52,199,89,0.06)", borderRadius: 6, fontSize: 12, color: "#34C759", fontFamily: "SF Mono, Menlo, monospace" }}>
            Auto-pasted
          </div>
        </div>
        <span style={{ fontSize: 11, color: "#86868B" }}>One click. Instantly pasted.</span>
      </div>
    );
  }

  return null;
}

/* ------------------------------------------------------------------ */
/*  ACT 2: THE PROOF — Features as tab panel                          */
/* ------------------------------------------------------------------ */

function Act2Proof() {
  const ref = useActReveal();
  const [activeTab, setActiveTab] = useState(0);
  const tabBarRef = useRef<HTMLDivElement>(null);
  const [indicatorStyle, setIndicatorStyle] = useState<React.CSSProperties>({});

  // Update indicator position
  useEffect(() => {
    const tabBar = tabBarRef.current;
    if (!tabBar) return;
    const buttons = tabBar.querySelectorAll<HTMLButtonElement>(".tab-item");
    const activeBtn = buttons[activeTab];
    if (activeBtn) {
      setIndicatorStyle({
        left: activeBtn.offsetLeft,
        width: activeBtn.offsetWidth,
      });
    }
  }, [activeTab]);

  const currentTab = tabData[activeTab];

  return (
    <section
      id="features"
      ref={ref}
      className="act-reveal"
      style={{
        position: "relative",
        zIndex: 2,
        background: "#F5F5F7",
        paddingBottom: 100,
      }}
    >
      {/* Tab bar — straddles the hero/features boundary */}
      <div
        className="tab-bar-wrapper"
        style={{
          display: "flex",
          justifyContent: "center",
          position: "relative",
          zIndex: 10,
          paddingTop: 8,
        }}
      >
        <div
          ref={tabBarRef}
          className="glass-card tab-bar"
          style={{
            position: "relative",
            flexWrap: "wrap",
            justifyContent: "center",
            padding: "10px 16px",
            background: "#ffffff",
            boxShadow: "0 12px 48px rgba(0, 0, 0, 0.18), 0 0 0 0.5px rgba(0, 0, 0, 0.08)",
          }}
        >
          {/* Sliding indicator */}
          <div className="tab-indicator" style={indicatorStyle} />
          {tabData.map((tab, i) => (
            <button
              key={tab.id}
              className={`tab-item ${activeTab === i ? "active" : ""}`}
              onClick={() => setActiveTab(i)}
            >
              {tab.label}
            </button>
          ))}
        </div>
      </div>

      <div className="mx-auto max-w-[1200px] px-4 sm:px-6 lg:px-8" style={{ position: "relative", zIndex: 1 }}>

        {/* Content panel */}
        <div
          style={{
            display: "grid",
            gridTemplateColumns: "1fr",
            gap: 48,
            alignItems: "center",
          }}
          className="lg:!grid-cols-2"
        >
          {/* Left: text */}
          <div key={currentTab.id} className="tab-content active">
            <h3
              style={{
                fontSize: "clamp(20px, 4.5vw, 24px)",
                fontWeight: 600,
                color: "#1D1D1F",
                marginBottom: 12,
              }}
            >
              {currentTab.title}
            </h3>
            <p
              style={{
                fontSize: "clamp(15px, 3.5vw, 17px)",
                color: "#86868B",
                lineHeight: 1.6,
              }}
            >
              {currentTab.description}
            </p>
            {currentTab.shortcut && (
              <div style={{ marginTop: 20, display: "flex", gap: 8, alignItems: "center" }}>
                <span className="keycap">&#x2325;</span>
                <span style={{ color: "#86868B", fontSize: 14 }}>+</span>
                <span className="keycap">V</span>
              </div>
            )}
          </div>

          {/* Right: illustration */}
          <div
            key={`illus-${currentTab.id}`}
            className="tab-content active"
            style={{
              display: "flex",
              justifyContent: "center",
            }}
          >
            <div style={{ maxWidth: 320, width: "100%" }}>
              <TabIllustration type={currentTab.illustration} />
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}

/* ------------------------------------------------------------------ */
/*  FAQ Item                                                           */
/* ------------------------------------------------------------------ */

function FAQItem({ faq }: { faq: { question: string; answer: string } }) {
  const [open, setOpen] = useState(false);

  return (
    <div className={`faq-row ${open ? "faq-open" : ""}`}>
      <button
        className="flex items-center justify-between gap-4 w-full text-left"
        style={{ padding: "20px 0" }}
        onClick={() => setOpen(!open)}
        aria-expanded={open}
      >
        <span style={{ fontSize: "clamp(15px, 3.5vw, 17px)", fontWeight: 600, color: "#1D1D1F" }}>
          {faq.question}
        </span>
        <PlusIcon className="faq-icon flex-shrink-0" />
      </button>
      <div className={`faq-answer ${open ? "open" : ""}`}>
        <div className="faq-answer-inner">
          <div style={{ paddingBottom: 20 }}>
            <p style={{ fontSize: 15, color: "#86868B", lineHeight: 1.6 }}>
              {faq.answer}
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}

/* ------------------------------------------------------------------ */
/*  ACT 3: THE CLOSE — Privacy + FAQ + CTA                            */
/* ------------------------------------------------------------------ */

function Act3Close() {
  const ref = useActReveal();

  return (
    <section
      id="privacy"
      ref={ref}
      className="act-reveal act3-section"
      style={{
        background: "#F0F0F2",
        position: "relative",
        overflow: "hidden",
      }}
    >
      {/* Dot grid background */}
      <div
        aria-hidden="true"
        style={{
          position: "absolute",
          inset: 0,
          backgroundImage: "radial-gradient(circle, rgba(0,0,0,0.18) 0.8px, transparent 0.8px)",
          backgroundSize: "22px 22px",
          pointerEvents: "none",
          maskImage: "radial-gradient(ellipse at center, black 40%, transparent 80%)",
          WebkitMaskImage: "radial-gradient(ellipse at center, black 40%, transparent 80%)",
        }}
      />
      <div className="mx-auto max-w-[1200px] px-4 sm:px-6 lg:px-8" style={{ position: "relative" }}>
        <div
          style={{
            display: "grid",
            gridTemplateColumns: "1fr",
            gap: 64,
          }}
          className="lg:!grid-cols-2"
        >
          {/* LEFT COLUMN (sticky) */}
          <div
            className="lg:sticky"
            style={{ top: 100, alignSelf: "start" }}
          >
            {/* Headline */}
            <h2
              className="privacy-heading"
              style={{
                fontWeight: 600,
                color: "#1D1D1F",
                lineHeight: 1.15,
                marginBottom: 32,
              }}
            >
              Your clipboard never leaves your Mac.
            </h2>

            {/* Privacy points */}
            <div style={{ display: "flex", flexDirection: "column", gap: 16, marginBottom: 40 }}>
              {privacyPoints.map((point, i) => (
                <div
                  key={i}
                  style={{
                    display: "flex",
                    alignItems: "center",
                    gap: 12,
                  }}
                >
                  <CheckmarkIcon />
                  <span style={{ fontSize: 16, color: "#1D1D1F" }}>
                    {point}
                  </span>
                </div>
              ))}
            </div>

            {/* Glass CTA card */}
            <div
              className="cta-glass-card cta-card-inner"
            >
              <div style={{ display: "flex", alignItems: "center", gap: 12, marginBottom: 16 }}>
                <ClippyBarLogo size={48} fill="#1D1D1F" />
                <div>
                  <p style={{ fontSize: "clamp(16px, 4vw, 20px)", fontWeight: 600, color: "#1D1D1F", margin: 0 }}>
                    Ready to paste smarter?
                  </p>
                </div>
              </div>
              {/* TODO: Replace href with actual App Store URL once ID is available */}
              <a
                href={APP_STORE_URL}
                className="btn-primary"
                style={{
                  width: "100%",
                  textAlign: "center",
                  marginBottom: 12,
                  gap: 8,
                }}
              >
                Download on the Mac App Store
              </a>
              <p style={{ fontSize: 12, color: "#86868B", textAlign: "center", margin: 0 }}>
                macOS 13 (Ventura) or later &middot; Apple Silicon &amp; Intel
              </p>
            </div>
          </div>

          {/* RIGHT COLUMN (scrollable FAQ) */}
          <div id="faq">
            {faqs.map((faq, i) => (
              <FAQItem key={i} faq={faq} />
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}

/* ------------------------------------------------------------------ */
/*  Privacy Policy                                                     */
/* ------------------------------------------------------------------ */

function PrivacyPolicy() {
  return (
    <section
      id="privacy-policy"
      style={{
        background: "#ffffff",
        padding: "80px 0",
        borderTop: "1px solid rgba(0,0,0,0.06)",
      }}
    >
      <div className="mx-auto max-w-[1200px] px-4 sm:px-6 lg:px-8" style={{ maxWidth: 720 }}>
        <h2
          style={{
            fontSize: "clamp(24px, 5vw, 36px)",
            fontWeight: 600,
            color: "#1D1D1F",
            marginBottom: 32,
          }}
        >
          Privacy Policy
        </h2>
        <p
          style={{
            fontSize: 16,
            color: "#1D1D1F",
            lineHeight: 1.7,
            marginBottom: 24,
          }}
        >
          ClippyBar does not collect, store, or transmit any personal data. All clipboard
          data is stored locally on your Mac in ~/Library/Application Support/ClippyBar/.
          The app makes zero network requests. No analytics, no telemetry, no tracking.
          Optional memory-only mode ensures nothing is written to disk.
        </p>
        <p style={{ fontSize: 13, color: "#86868B" }}>
          Last updated: March 2026
        </p>
      </div>
    </section>
  );
}

/* ------------------------------------------------------------------ */
/*  Footer                                                             */
/* ------------------------------------------------------------------ */

function Footer() {
  return (
    <footer
      style={{
        borderTop: "1px solid rgba(0,0,0,0.06)",
        padding: "24px 0",
        background: "#F0F0F2",
      }}
    >
      <div className="mx-auto max-w-[1200px] px-4 sm:px-6 lg:px-8">
        <div
          style={{
            display: "flex",
            alignItems: "center",
            justifyContent: "space-between",
            flexWrap: "wrap",
            gap: 8,
          }}
        >
          <span style={{ fontSize: 13, color: "#86868B" }}>
            ClippyBar — Paste smarter, not harder.
          </span>
          <span style={{ fontSize: 13, color: "#86868B" }}>
            macOS &middot; 2026 &middot; Free
          </span>
        </div>
        <div style={{ textAlign: "center", marginTop: 12 }}>
          <span style={{ fontSize: 13, color: "#86868B" }}>
            Made with <span style={{ color: "#FF2D55" }}>&hearts;</span> by{" "}
            <a
              href="https://github.com/panayar/Clippy"
              target="_blank"
              rel="noopener noreferrer"
              style={{ color: "#86868B", textDecoration: "none" }}
              className="link-hover"
            >
              @panayar
            </a>
          </span>
        </div>
      </div>
    </footer>
  );
}

/* ------------------------------------------------------------------ */
/*  Main Page                                                          */
/* ------------------------------------------------------------------ */

export default function Home() {
  return (
    <>
      {/* Animated mesh gradient background */}
      <div className="mesh-gradient" aria-hidden="true">
        <div className="mesh-blob" />
      </div>

      <Navigation />
      <main>
        <Act1Hook />
        <Act2Proof />
        <Act3Close />
        <PrivacyPolicy />
      </main>
      <Footer />
    </>
  );
}
