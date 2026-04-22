"use client";

import { useState, useEffect, useRef, useCallback } from "react";
import { motion, AnimatePresence } from "framer-motion";

/* ------------------------------------------------------------------ */
/*  Scroll-reveal hook                                                 */
/* ------------------------------------------------------------------ */

function useReveal() {
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
      { threshold: 0.15 }
    );

    observer.observe(el);
    return () => observer.disconnect();
  }, []);

  return ref;
}

/* ------------------------------------------------------------------ */
/*  ClippyBar Logo SVG                                                 */
/* ------------------------------------------------------------------ */

function ClippyBarLogo({
  size = 24,
  fill = "#1A1A1A",
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
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <line x1="4" y1="6" x2="20" y2="6" />
      <line x1="4" y1="12" x2="20" y2="12" />
      <line x1="4" y1="18" x2="20" y2="18" />
    </svg>
  );
}

function CloseIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <line x1="18" y1="6" x2="6" y2="18" />
      <line x1="6" y1="6" x2="18" y2="18" />
    </svg>
  );
}

function PlusIcon({ className }: { className?: string }) {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className={className}>
      <line x1="12" y1="5" x2="12" y2="19" />
      <line x1="5" y1="12" x2="19" y2="12" />
    </svg>
  );
}

function ArrowRight() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <line x1="5" y1="12" x2="19" y2="12" />
      <polyline points="12 5 19 12 12 19" />
    </svg>
  );
}

function SearchIcon() {
  return (
    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="11" cy="11" r="8" />
      <path d="m21 21-4.35-4.35" />
    </svg>
  );
}

function ZapIcon() {
  return (
    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2" />
    </svg>
  );
}

function ShieldIcon() {
  return (
    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" />
    </svg>
  );
}

function CheckIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#22C55E" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
      <polyline points="20 6 9 17 4 12" />
    </svg>
  );
}

function AppleIcon() {
  return (
    <svg width="14" height="14" viewBox="0 0 14 14" fill="none" xmlns="http://www.w3.org/2000/svg">
      <path
        d="M11.182 7.455c-.02-1.91 1.558-2.826 1.629-2.872-.887-1.296-2.267-1.474-2.759-1.494-1.174-.119-2.293.691-2.89.691-.597 0-1.52-.674-2.498-.656-1.285.019-2.47.747-3.131 1.899-1.335 2.315-.342 5.746.958 7.627.636.919 1.393 1.951 2.389 1.914.959-.038 1.321-.62 2.482-.62 1.161 0 1.492.62 2.511.6 1.031-.018 1.683-.937 2.316-1.858.73-1.066 1.031-2.098 1.049-2.152-.023-.01-2.013-.773-2.032-3.066l-.024.007zM9.286 2.048c.529-.641.886-1.531.789-2.419-.762.031-1.685.508-2.231 1.148-.49.567-.919 1.473-.804 2.342.851.066 1.719-.432 2.246-1.071z"
        fill="currentColor"
      />
    </svg>
  );
}

/* ------------------------------------------------------------------ */
/*  Data                                                               */
/* ------------------------------------------------------------------ */

const APP_STORE_URL = "https://apps.apple.com/co/app/clippybar/id6760884112?l=en-GB&mt=12";
const GITHUB_URL = "https://github.com/panayar/Clippy";

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
  "All data stored locally on your Mac",
  "Zero network connections — ever",
  "Optional memory-only mode for maximum privacy",
  "Exclude sensitive apps from clipboard monitoring",
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

  const handleLinkClick = useCallback(() => setMobileOpen(false), []);

  return (
    <nav className={`nav-fixed ${scrolled ? "scrolled" : ""}`}>
      <div className="mx-auto max-w-[1400px] px-6 sm:px-8 lg:px-12">
        <div className="flex h-16 items-center justify-between">
          {/* Left nav links */}
          <div className="hidden md:flex items-center gap-8">
            {navLinks.map((link) => (
              <a key={link.href} href={link.href} className="nav-link">
                {link.label}
              </a>
            ))}
          </div>

          {/* Center logo */}
          <a href="#" className="flex items-center gap-2">
            <ClippyBarLogo size={28} fill="#1A1A1A" />
            <span className="text-base font-semibold tracking-tight text-[#1A1A1A]">
              ClippyBar
            </span>
          </a>

          {/* Right download */}
          <div className="hidden md:block">
            <a href={APP_STORE_URL} className="btn-nav-download">
              Download
            </a>
          </div>

          {/* Mobile hamburger */}
          <button
            className="md:hidden text-[#1A1A1A]"
            onClick={() => setMobileOpen(!mobileOpen)}
            aria-label={mobileOpen ? "Close menu" : "Open menu"}
          >
            {mobileOpen ? <CloseIcon /> : <MenuIcon />}
          </button>
        </div>
      </div>

      {mobileOpen && (
        <div className="md:hidden fixed inset-0 top-16 z-40 bg-[#F5F0EB] mobile-menu-enter">
          <div className="px-6 py-8 flex flex-col gap-2">
            {navLinks.map((link) => (
              <a
                key={link.href}
                href={link.href}
                className="text-sm font-semibold uppercase tracking-widest text-[#1A1A1A] no-underline py-4 px-4 border-b border-[rgba(0,0,0,0.06)]"
                onClick={handleLinkClick}
              >
                {link.label}
              </a>
            ))}
            <div className="pt-6">
              <a
                href={APP_STORE_URL}
                className="btn-primary w-full text-center"
                onClick={handleLinkClick}
              >
                Download Free
              </a>
            </div>
          </div>
        </div>
      )}
    </nav>
  );
}

/* ------------------------------------------------------------------ */
/*  Hero Section                                                       */
/* ------------------------------------------------------------------ */

function ClippyPickerMock({ onSelect }: { onSelect: () => void }) {
  const [selectedItem, setSelectedItem] = useState(-1);

  useEffect(() => {
    const t1 = setTimeout(() => setSelectedItem(0), 600);
    const t2 = setTimeout(() => onSelect(), 1200);
    return () => { clearTimeout(t1); clearTimeout(t2); };
  }, [onSelect]);

  return (
    <div className="picker-mock">
      {/* Search bar */}
      <div className="picker-search">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#5E5E62" strokeWidth="2" strokeLinecap="round">
          <circle cx="11" cy="11" r="8" /><path d="m21 21-4.35-4.35" />
        </svg>
        <span className="picker-search-text">Search...</span>
      </div>

      {/* Filter chips */}
      <div className="picker-filters">
        {[
          { label: "Text", icon: "doc.text", active: false },
          { label: "Links", icon: "link", active: false },
          { label: "Files", icon: "doc", active: false },
          { label: "Images", icon: "photo", active: false },
        ].map((chip) => (
          <span key={chip.label} className={`picker-chip ${chip.active ? "picker-chip-active" : ""}`}>
            {chip.label}
          </span>
        ))}
      </div>

      <div className="picker-divider" />

      {/* Section */}
      <div className="picker-section-label">Today</div>

      {/* Selected item: ClippyBar */}
      <motion.div
        className={`picker-item ${selectedItem === 0 ? "picker-item-selected" : ""}`}
        animate={selectedItem === 0 ? { backgroundColor: "rgba(124, 58, 237, 0.12)" } : {}}
        transition={{ duration: 0.25 }}
      >
        <div className="picker-item-content">
          <span className="picker-item-text">ClippyBar</span>
          <div className="picker-item-meta">
            <span>just now</span>
            <span className="picker-meta-dot">&middot;</span>
            <span>Safari</span>
          </div>
        </div>
      </motion.div>

      {/* Link items */}
      <div className="picker-item">
        <div className="picker-item-icon picker-icon-link">
          <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"/><path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"/></svg>
        </div>
        <div className="picker-item-content">
          <span className="picker-item-text" style={{ color: "#8E8CE5" }}>https://www.recop.xyz/</span>
          <div className="picker-item-meta">
            <span>19h ago</span>
            <span className="picker-meta-dot">&middot;</span>
            <span>Google Chrome</span>
          </div>
        </div>
      </div>

      <div className="picker-item">
        <div className="picker-item-icon picker-icon-link">
          <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"/><path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"/></svg>
        </div>
        <div className="picker-item-content">
          <span className="picker-item-text" style={{ color: "#8E8CE5" }}>https://paulaanayar.com/</span>
          <div className="picker-item-meta">
            <span>19h ago</span>
            <span className="picker-meta-dot">&middot;</span>
            <span>iTerm2</span>
          </div>
        </div>
      </div>

      <div className="picker-divider" style={{ margin: "4px 12px" }} />

      {/* Image items */}
      <div className="picker-item">
        <div className="picker-thumb">
          <div className="picker-thumb-placeholder" />
        </div>
        <div className="picker-item-content">
          <span className="picker-item-text" style={{ color: "#8E8E93" }}>Image</span>
          <div className="picker-item-meta">
            <span>7m ago</span>
            <span className="picker-meta-dot">&middot;</span>
            <span>Lightshot Screenshot</span>
          </div>
        </div>
      </div>

      <div className="picker-item">
        <div className="picker-thumb">
          <div className="picker-thumb-placeholder" style={{ background: "#2C2C2E" }} />
        </div>
        <div className="picker-item-content">
          <span className="picker-item-text" style={{ color: "#8E8E93" }}>Image</span>
          <div className="picker-item-meta">
            <span>8m ago</span>
            <span className="picker-meta-dot">&middot;</span>
            <span>Lightshot Screenshot</span>
          </div>
        </div>
      </div>

      {/* Status bar */}
      <div className="picker-statusbar">
        <span>63 items</span>
        <span className="picker-statusbar-hints">
          <span className="picker-hint-key">↑↓</span> navigate
          <span className="picker-hint-key" style={{ marginLeft: 6 }}>↵</span> paste
          <span className="picker-hint-key" style={{ marginLeft: 6 }}>⌘P</span> pin
          <span className="picker-hint-key" style={{ marginLeft: 6 }}>⌘⌫</span> delete
        </span>
      </div>
    </div>
  );
}

function HeroSection() {
  const [phase, setPhase] = useState(0);
  // 0: empty
  // 1: cursor appears center, does a playful wiggle
  // 2: cursor moves to the side, ⌥V shortcut appears center
  // 3: picker appears center, cursor moves onto the first item
  // 4: cursor clicks, picker closes, text pastes as title
  // 5: cursor exits
  // 6: rest of content reveals

  const handlePickerSelect = useCallback(() => {
    setPhase(4);
  }, []);

  useEffect(() => {
    const prefersReduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    if (prefersReduced) {
      setPhase(6);
      return;
    }
    const timers = [
      setTimeout(() => setPhase(1), 300),    // cursor appears + wiggle
      setTimeout(() => setPhase(2), 1800),   // cursor aside, shortcut center
      setTimeout(() => setPhase(3), 2800),   // picker appears, cursor moves to item
      // phase 4 triggered by picker onSelect (~1.2s after phase 3)
      setTimeout(() => setPhase(5), 5200),   // cursor exits
      setTimeout(() => setPhase(6), 5900),   // content reveals
    ];
    return () => timers.forEach(clearTimeout);
  }, []);

  const word1 = "Clippy".split("");
  const word2 = "Bar".split("");

  return (
    <section className="hero-banner" style={{ background: "#F5F0EB" }}>
      <div className="hero-banner-inner">

        {/* Animated cursor */}
        <AnimatePresence>
          {phase >= 1 && phase <= 4 && (
            <motion.img
              src="/cursor.svg"
              alt=""
              aria-hidden="true"
              className="hero-anim-cursor"
              initial={{ left: "105%", top: "10%", opacity: 0 }}
              animate={
                phase === 1
                  ? {
                      left: "50%",
                      top: "50%",
                      opacity: 1,
                      y: [0, 30, 0],
                    }
                  : phase === 2
                  ? { left: "70%", top: "38%", opacity: 1, y: 0 }
                  : phase === 3
                  ? { left: "calc(50% - 60px)", top: "calc(50% - 110px)", opacity: 1, y: 0 }
                  : { left: "calc(50% - 60px)", top: "calc(50% - 110px)", opacity: 1, y: 0, scale: 0.88 }
              }
              exit={{ left: "-10%", top: "30%", opacity: 0 }}
              transition={
                phase === 1
                  ? { duration: 0.8, ease: [0.2, 0.8, 0.2, 1] }
                  : { duration: 0.6, ease: [0.32, 0.72, 0, 1] }
              }
            />
          )}
        </AnimatePresence>

        {/* ⌥V shortcut flash — centered */}
        <AnimatePresence>
          {phase === 2 && (
            <motion.div
              className="hero-shortcut-flash"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              transition={{ duration: 0.3 }}
            >
              <motion.div
                className="hero-shortcut-flash-inner"
                initial={{ scale: 0.8 }}
                animate={{ scale: 1 }}
                exit={{ scale: 0.9 }}
                transition={{ duration: 0.3 }}
              >
                <span className="hero-keycap">⌥</span>
                <span className="hero-keycap">V</span>
              </motion.div>
            </motion.div>
          )}
        </AnimatePresence>

        {/* ClippyBar picker — centered */}
        <AnimatePresence>
          {phase === 3 && (
            <motion.div
              className="hero-picker-wrapper"
              initial={{ opacity: 0, scale: 0.92, y: 16 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.96, y: -8 }}
              transition={{ duration: 0.3, ease: [0.32, 0.72, 0, 1] }}
            >
              <ClippyPickerMock onSelect={handlePickerSelect} />
            </motion.div>
          )}
        </AnimatePresence>

      </div>

      {/* Text content */}
      <div className="mx-auto max-w-[1400px] px-6 sm:px-8 lg:px-12">
        {/* The headline — pastes in after picker selection */}
        <div className="relative">
          <h1 className="hero-display">
            {phase >= 4 ? (
              <>
                <span className="block">
                  {word1.map((char, i) => (
                    <motion.span
                      key={`a${i}`}
                      initial={{ opacity: 0, y: 30, filter: "blur(10px)" }}
                      animate={{ opacity: 1, y: 0, filter: "blur(0px)" }}
                      transition={{
                        duration: 0.45,
                        delay: i * 0.05,
                        ease: [0.32, 0.72, 0, 1],
                      }}
                      className="inline-block"
                    >
                      {char}
                    </motion.span>
                  ))}
                </span>
                <span className="block">
                  {word2.map((char, i) => (
                    <motion.span
                      key={`b${i}`}
                      initial={{ opacity: 0, y: 30, filter: "blur(10px)" }}
                      animate={{ opacity: 1, y: 0, filter: "blur(0px)" }}
                      transition={{
                        duration: 0.45,
                        delay: (i + word1.length) * 0.05,
                        ease: [0.32, 0.72, 0, 1],
                      }}
                      className="inline-block"
                    >
                      {char}
                    </motion.span>
                  ))}
                </span>
              </>
            ) : (
              <>
                <span className="block invisible">Clippy</span>
                <span className="block invisible">Bar</span>
              </>
            )}
          </h1>

          {phase === 4 && (
            <motion.span
              className="hero-text-cursor"
              initial={{ opacity: 0 }}
              animate={{ opacity: [0, 1, 0] }}
              transition={{ duration: 0.5, repeat: 2, ease: "linear" }}
            />
          )}
        </div>

        {/* Rest of hero content */}
        <motion.div
          initial={{ opacity: 0, y: 24 }}
          animate={phase >= 6 ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.8, ease: [0.32, 0.72, 0, 1] }}
          className="mt-10 md:mt-14 flex flex-col md:flex-row md:items-end md:justify-between gap-8"
        >
          <p className="text-[#6B7280] text-base md:text-lg leading-relaxed max-w-md">
            A privacy-first clipboard manager for macOS. Save your full history,
            search instantly, and paste with a single shortcut.
          </p>
          <a href="#features" className="btn-pill-outline shrink-0">
            Explore ClippyBar
            <ArrowRight />
          </a>
        </motion.div>

        {/* Dot indicators */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={phase >= 6 ? { opacity: 1 } : {}}
          transition={{ duration: 0.6, delay: 0.2 }}
          className="flex items-center gap-2 mt-10"
        >
          <span className="w-2 h-2 rounded-full bg-[#1A1A1A]" />
          <span className="w-2 h-2 rounded-full bg-[#D1D5DB]" />
          <span className="w-2 h-2 rounded-full bg-[#D1D5DB]" />
        </motion.div>

        {/* Main demo video */}
        <motion.div
          initial={{ opacity: 0, y: 32 }}
          animate={phase >= 6 ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.8, delay: 0.3, ease: [0.32, 0.72, 0, 1] }}
          className="mt-14 md:mt-20"
        >
          <div className="media-card max-w-5xl mx-auto">
            <video autoPlay muted loop playsInline>
              <source src="/demos/clippy-demo.mp4" type="video/mp4" />
            </video>
          </div>
        </motion.div>
      </div>
    </section>
  );
}

/* ------------------------------------------------------------------ */
/*  About Section                                                      */
/* ------------------------------------------------------------------ */

function AboutSection() {
  const ref = useReveal();

  return (
    <section ref={ref} className="section-reveal py-24 md:py-36 bg-white">
      <div className="mx-auto max-w-[1400px] px-6 sm:px-8 lg:px-12">
        <div className="flex flex-col md:flex-row gap-12 md:gap-24 items-start">
          <h2 className="text-3xl md:text-4xl font-light text-[#1A1A1A] tracking-tight shrink-0 leading-tight">
            About Us
          </h2>
          <p className="about-editorial-text">
            We believe that a great clipboard manager is <strong>more than just storage
            — it&#39;s about creating workflows where productivity happens.</strong>{" "}
            ClippyBar is thoughtfully crafted to combine instant recall, privacy-first
            design, everyday functionality, and lasting simplicity.
          </p>
        </div>
      </div>
    </section>
  );
}

/* ------------------------------------------------------------------ */
/*  Feature Cards Row                                                  */
/* ------------------------------------------------------------------ */

function FeatureCardsRow() {
  const ref = useReveal();
  const [activeCard, setActiveCard] = useState(0);

  const cards = [
    {
      num: "01",
      icon: <SearchIcon />,
      title: "Instant\nSearch",
      description:
        "Filter your entire clipboard history in milliseconds to find exactly what you need.",
      media: "/demos/clippy-demo.mp4",
      mediaType: "video" as const,
    },
    {
      num: "02",
      icon: <ZapIcon />,
      title: "Smart\nFilters",
      description:
        "Narrow down by type — text, links, files, or images. Find what matters fast.",
      media: "/demos/filters-gif.gif",
      mediaType: "image" as const,
    },
    {
      num: "03",
      icon: <ShieldIcon />,
      title: "Pin\nFavorites",
      description:
        "Keep important snippets pinned to the top. Always there when you need them.",
      media: "/demos/pin-item.gif",
      mediaType: "image" as const,
    },
  ];

  return (
    <section id="features" ref={ref} className="section-reveal py-24 md:py-36" style={{ background: "#F5F0EB" }}>
      <div className="mx-auto max-w-[1400px] px-6 sm:px-8 lg:px-12">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 md:gap-5">
          {cards.map((card, i) => (
            <div
              key={i}
              className={`showcase-card ${i === activeCard ? "showcase-card-active" : ""}`}
              onMouseEnter={() => setActiveCard(i)}
            >
              {/* Background media */}
              <div className="showcase-card-bg">
                {card.mediaType === "video" ? (
                  <video autoPlay muted loop playsInline>
                    <source src={card.media} type="video/mp4" />
                  </video>
                ) : (
                  <img src={card.media} alt={card.title} loading="lazy" />
                )}
              </div>

              {/* Overlay content */}
              <div className="showcase-card-content">
                <div className="flex items-start justify-between mb-auto">
                  <span className="text-xs font-medium opacity-60">{card.num}</span>
                  <div className="showcase-card-icon">{card.icon}</div>
                </div>

                <div>
                  <h3 className="text-xl md:text-2xl font-semibold leading-tight mb-3 whitespace-pre-line">
                    {card.title}
                  </h3>
                  <p className="text-sm opacity-70 leading-relaxed">
                    {card.description}
                  </p>
                </div>

                <div className="mt-4 flex items-center gap-3">
                  <button
                    className="showcase-card-arrow"
                    onClick={() => setActiveCard(i === 0 ? cards.length - 1 : i - 1)}
                    aria-label="Previous"
                  >
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M19 12H5"/><path d="m12 19-7-7 7-7"/></svg>
                  </button>
                  <button
                    className="showcase-card-arrow"
                    onClick={() => setActiveCard(i === cards.length - 1 ? 0 : i + 1)}
                    aria-label="Next"
                  >
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M5 12h14"/><path d="m12 5 7 7-7 7"/></svg>
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

/* ------------------------------------------------------------------ */
/*  Trust / Stats Section                                              */
/* ------------------------------------------------------------------ */

function TrustSection() {
  const ref = useReveal();

  const stats = [
    { value: "\u221E", label: "Unlimited History" },
    { value: "0", label: "Data Collected" },
    { value: "100%", label: "Local Storage" },
  ];

  return (
    <section ref={ref} className="section-reveal py-24 md:py-36 bg-white">
      <div className="mx-auto max-w-[1400px] px-6 sm:px-8 lg:px-12">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 lg:gap-20 items-center">
          {/* Left: large media */}
          <div className="media-card">
            <video autoPlay muted loop playsInline>
              <source src="/demos/clippy-demo.mp4" type="video/mp4" />
            </video>
          </div>

          {/* Right: heading + stats */}
          <div>
            <h2 className="section-heading-editorial mb-6">
              Growing through <strong>craftsmanship</strong>,<br />
              trusted by thousands
            </h2>
            <p className="text-[#6B7280] text-base leading-relaxed max-w-md mb-12">
              Built with care for macOS users who value speed, simplicity, and
              privacy above everything else. No subscriptions, no compromises.
            </p>

            <div className="flex gap-10 md:gap-14">
              {stats.map((stat, i) => (
                <div key={i}>
                  <div className="stat-value">{stat.value}</div>
                  <div className="stat-label">{stat.label}</div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}

/* ------------------------------------------------------------------ */
/*  Features Detail / Bento Grid                                       */
/* ------------------------------------------------------------------ */

function FeaturesDetail() {
  const ref = useReveal();

  return (
    <section ref={ref} className="section-reveal py-24 md:py-36" style={{ background: "#F5F0EB" }}>
      <div className="mx-auto max-w-[1400px] px-6 sm:px-8 lg:px-12">
        <div className="mb-14 md:mb-20">
          <div className="about-divider" />
          <h2 className="text-2xl md:text-3xl font-light text-[#1A1A1A] tracking-tight">
            Our <em className="font-semibold not-italic">Features</em>
          </h2>
        </div>

        <div className="bento-grid">
          {/* Large card — demo video */}
          <div className="bento-large">
            <div className="media-card relative">
              <video autoPlay muted loop playsInline>
                <source src="/demos/clippy-demo.mp4" type="video/mp4" />
              </video>
              <div className="absolute bottom-0 left-0 right-0 p-6 bg-gradient-to-t from-black/50 to-transparent">
                <span className="text-white text-sm font-semibold tracking-wide uppercase">
                  Smart History
                </span>
              </div>
            </div>
          </div>

          {/* Smaller cards */}
          <div>
            <div className="media-card relative">
              <img
                src="/demos/filters-gif.gif"
                alt="Filter by type"
                loading="lazy"
              />
              <div className="absolute bottom-0 left-0 right-0 p-5 bg-gradient-to-t from-black/50 to-transparent">
                <span className="text-white text-sm font-semibold tracking-wide uppercase">
                  Type Filters
                </span>
              </div>
            </div>
          </div>

          <div>
            <div className="media-card relative">
              <img
                src="/demos/pin-item.gif"
                alt="Pin important items"
                loading="lazy"
              />
              <div className="absolute bottom-0 left-0 right-0 p-5 bg-gradient-to-t from-black/50 to-transparent">
                <span className="text-white text-sm font-semibold tracking-wide uppercase">
                  Pin Items
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}

/* ------------------------------------------------------------------ */
/*  Privacy Section                                                    */
/* ------------------------------------------------------------------ */

function PrivacySection() {
  const ref = useReveal();

  return (
    <section id="privacy" ref={ref} className="section-reveal py-24 md:py-36" style={{ background: "#1A1A1A" }}>
      <div className="mx-auto max-w-[1400px] px-6 sm:px-8 lg:px-12">
        <div className="max-w-2xl mx-auto text-center">
          <h2
            className="text-white font-bold mb-8"
            style={{ fontSize: "clamp(1.75rem, 4vw, 2.5rem)" }}
          >
            Your clipboard never leaves your Mac.
          </h2>
          <p className="text-[#9CA3AF] text-lg leading-relaxed mb-14">
            ClippyBar is built on a simple principle: your data is yours. No
            cloud, no servers, no analytics. Just a fast, local clipboard
            manager that respects your privacy.
          </p>

          <div className="flex flex-col gap-5 items-start max-w-md mx-auto mb-14">
            {privacyPoints.map((point, i) => (
              <div key={i} className="flex items-center gap-3">
                <CheckIcon />
                <span className="text-white text-base">{point}</span>
              </div>
            ))}
          </div>

          <div className="inline-flex items-center gap-2 px-5 py-2.5 rounded-full bg-[#22C55E]/10 border border-[#22C55E]/20">
            <CheckIcon />
            <span className="text-[#22C55E] font-semibold text-sm">
              100% Local
            </span>
          </div>
        </div>
      </div>
    </section>
  );
}

/* ------------------------------------------------------------------ */
/*  FAQ Section                                                        */
/* ------------------------------------------------------------------ */

function FAQItem({ faq }: { faq: { question: string; answer: string } }) {
  const [open, setOpen] = useState(false);

  return (
    <div className={`faq-row ${open ? "faq-open" : ""}`}>
      <button
        className="flex items-center justify-between gap-4 w-full text-left py-5"
        onClick={() => setOpen(!open)}
        aria-expanded={open}
      >
        <span className="text-base md:text-lg font-semibold text-[#1A1A1A]">
          {faq.question}
        </span>
        <PlusIcon className="faq-icon" />
      </button>
      <div className={`faq-answer ${open ? "open" : ""}`}>
        <div className="faq-answer-inner">
          <div className="pb-5">
            <p className="text-[#6B7280] text-base leading-relaxed">
              {faq.answer}
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}

function FAQSection() {
  const ref = useReveal();

  return (
    <section id="faq" ref={ref} className="section-reveal py-24 md:py-36" style={{ background: "#F5F0EB" }}>
      <div className="mx-auto max-w-[720px] px-6 sm:px-8 lg:px-12">
        <div className="mb-14">
          <div className="about-divider" />
          <h2 className="text-2xl md:text-3xl font-light text-[#1A1A1A] tracking-tight">
            Frequently Asked <em className="font-semibold not-italic">Questions</em>
          </h2>
        </div>
        <div>
          {faqs.map((faq, i) => (
            <FAQItem key={i} faq={faq} />
          ))}
        </div>
      </div>
    </section>
  );
}

/* ------------------------------------------------------------------ */
/*  CTA Section                                                        */
/* ------------------------------------------------------------------ */

function CTASection() {
  const ref = useReveal();

  return (
    <section ref={ref} className="section-reveal py-24 md:py-36 bg-white">
      <div className="mx-auto max-w-[1400px] px-6 sm:px-8 lg:px-12 text-center">
        <h2
          className="font-bold text-[#1A1A1A] mb-4"
          style={{ fontSize: "clamp(1.75rem, 4vw, 2.5rem)" }}
        >
          Ready to paste smarter?
        </h2>
        <p className="text-[#6B7280] text-base mb-10 max-w-md mx-auto">
          Download ClippyBar for free and experience a clipboard that works the
          way you think.
        </p>
        <div className="mb-6">
          <a href={APP_STORE_URL} className="btn-primary gap-2">
            <AppleIcon />
            Download Free
          </a>
        </div>
        <p className="text-xs text-[#9CA3AF] tracking-wide uppercase">
          macOS 13+ &middot; Apple Silicon &amp; Intel &middot; Free forever
        </p>
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
      className="py-20"
      style={{ background: "#F5F0EB", borderTop: "1px solid rgba(0,0,0,0.06)" }}
    >
      <div className="mx-auto max-w-[720px] px-6 sm:px-8 lg:px-12">
        <h2
          className="font-bold text-[#1A1A1A] mb-8"
          style={{ fontSize: "clamp(1.5rem, 4vw, 2rem)" }}
        >
          Privacy Policy
        </h2>
        <p className="text-[#1A1A1A] text-base leading-7 mb-6">
          ClippyBar does not collect, store, or transmit any personal data. All
          clipboard data is stored locally on your Mac in ~/Library/Application
          Support/ClippyBar/. The app makes zero network requests. No analytics,
          no telemetry, no tracking. Optional memory-only mode ensures nothing
          is written to disk.
        </p>
        <p className="text-sm text-[#9CA3AF]">Last updated: March 2026</p>
      </div>
    </section>
  );
}

/* ------------------------------------------------------------------ */
/*  Footer                                                             */
/* ------------------------------------------------------------------ */

function Footer() {
  return (
    <footer className="py-10" style={{ background: "#1A1A1A" }}>
      <div className="mx-auto max-w-[1400px] px-6 sm:px-8 lg:px-12">
        <div className="flex flex-col md:flex-row items-center justify-between gap-6">
          <div className="flex items-center gap-2">
            <ClippyBarLogo size={22} fill="#FFFFFF" />
            <span className="text-sm font-semibold text-white tracking-tight">
              ClippyBar
            </span>
          </div>

          <div className="flex items-center gap-8">
            <a href="#features" className="text-xs text-[#9CA3AF] uppercase tracking-widest hover:text-white transition-colors no-underline">
              Features
            </a>
            <a href="#privacy" className="text-xs text-[#9CA3AF] uppercase tracking-widest hover:text-white transition-colors no-underline">
              Privacy
            </a>
            <a href="#faq" className="text-xs text-[#9CA3AF] uppercase tracking-widest hover:text-white transition-colors no-underline">
              FAQ
            </a>
            <a
              href={GITHUB_URL}
              target="_blank"
              rel="noopener noreferrer"
              className="text-xs text-[#9CA3AF] uppercase tracking-widest hover:text-white transition-colors no-underline"
            >
              GitHub
            </a>
          </div>

          <span className="text-xs text-[#6B7280]">
            Made with <span className="text-red-400">&hearts;</span> by{" "}
            <a
              href={GITHUB_URL}
              target="_blank"
              rel="noopener noreferrer"
              className="text-[#9CA3AF] no-underline link-hover"
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
      <Navigation />
      <main>
        <HeroSection />
        <AboutSection />
        <FeatureCardsRow />
        <TrustSection />
        <FeaturesDetail />
        <PrivacySection />
        <FAQSection />
        <CTASection />
        <PrivacyPolicy />
      </main>
      <Footer />
    </>
  );
}
