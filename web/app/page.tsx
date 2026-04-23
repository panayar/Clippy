"use client";

import { useState, useEffect, useRef, useCallback, useImperativeHandle, forwardRef } from "react";
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

const heroSlides = [
  "A privacy-first clipboard manager for macOS. Save your full history, search instantly, and paste with a single shortcut.",
  "Never lose a snippet again. Every copy stays on your Mac. Recall anything with ⌥V, no accounts, no cloud, no tracking.",
  "Pin what matters, filter what doesn’t. Flip between text, links, files, and images in milliseconds without leaving your keyboard.",
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
          <a href="#" className="flex items-center gap-0.5">
            <ClippyBarLogo size={36} fill="#1A1A1A" />
            <span className="text-base font-semibold tracking-tight text-[#1A1A1A]">
              ClippyBar
            </span>
          </a>

          {/* Right download */}
          <div className="hidden md:block">
            <a
              href={APP_STORE_URL}
              target="_blank"
              rel="noopener noreferrer"
              className="btn-nav-download gap-2"
            >
              <AppleIcon />
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
        <div
          className="md:hidden fixed inset-0 top-16 z-[9998] mobile-menu-enter shadow-sm"
          style={{ backgroundColor: "#FFFFFF" }}
        >
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
                target="_blank"
                rel="noopener noreferrer"
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

function ClippyPickerMock({ onClick, onPaste }: { onClick: () => void; onPaste: () => void }) {
  const [selectedItem, setSelectedItem] = useState(-1);

  useEffect(() => {
    // Fire the click pulse and the highlight at the same instant so the
    // visual cause-and-effect feels natural.
    const t1 = setTimeout(() => {
      setSelectedItem(0);
      onClick();
    }, 700);
    const t2 = setTimeout(() => onPaste(), 1400);
    return () => { clearTimeout(t1); clearTimeout(t2); };
  }, [onClick, onPaste]);

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

/* ------------------------------------------------------------------ */
/*  Hero ripples — ambient "clipboard content" snippets                */
/* ------------------------------------------------------------------ */

type RippleSnippet =
  | { kind: "text" | "code" | "url"; content: string; meta: string; pinned?: boolean }
  | { kind: "image"; src: string; meta: string; pinned?: boolean };

const RIPPLE_SNIPPETS: RippleSnippet[] = [
  // Casual text messages
  { kind: "text", content: "running late lol 🏃‍♀️", meta: "1m ago · Messages" },
  { kind: "text", content: "omg yes 😹", meta: "3m ago · Messages" },
  { kind: "text", content: "can't even rn 💀", meta: "5m ago · Messages" },
  { kind: "text", content: "coffee first ☕", meta: "8m ago · Messages" },
  { kind: "text", content: "this slaps 🔥", meta: "12m ago · Messages" },
  { kind: "text", content: "pizza night 🍕🍕", meta: "16m ago · Messages" },
  { kind: "text", content: "miss u 🐱", meta: "20m ago · Messages" },
  { kind: "text", content: "it's giving main character", meta: "22m ago · Messages" },
  { kind: "text", content: "sending love 💕", meta: "28m ago · Messages" },
  { kind: "text", content: "deadass 🫡", meta: "35m ago · Messages" },
  { kind: "text", content: "gn 🌙", meta: "48m ago · Messages" },
  // Notes / todos (some pinned)
  { kind: "text", content: "TODO: buy milk", meta: "9m ago · Notes", pinned: true },
  { kind: "text", content: "Meeting @ 3pm", meta: "14m ago · Notes" },
  { kind: "text", content: "Mom's birthday!!", meta: "1h ago · Notes", pinned: true },
  { kind: "text", content: "don't forget keys", meta: "2h ago · Notes" },
  { kind: "text", content: "gift ideas: socks?", meta: "3h ago · Notes" },
  // Images — cats, animals, random screenshots
  { kind: "image", src: "https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=120&h=120&fit=crop",  meta: "4m ago · Lightshot Screenshot" },
  { kind: "image", src: "https://images.unsplash.com/photo-1533738363-b7f9aef128ce?w=120&h=120&fit=crop",    meta: "11m ago · Screenshot" },
  { kind: "image", src: "https://images.unsplash.com/photo-1561948955-570b270e7c36?w=120&h=120&fit=crop",    meta: "26m ago · Screenshot" },
  { kind: "image", src: "https://images.unsplash.com/photo-1548247416-ec66f4900b2e?w=120&h=120&fit=crop",    meta: "41m ago · Finder" },
  { kind: "image", src: "https://images.unsplash.com/photo-1517849845537-4d257902454a?w=120&h=120&fit=crop", meta: "1h ago · Screenshot" },
  { kind: "image", src: "https://images.unsplash.com/photo-1552053831-71594a27632d?w=120&h=120&fit=crop",    meta: "2h ago · Lightshot Screenshot", pinned: true },
  // URLs
  { kind: "url",  content: "https://clippybar.app",         meta: "2m ago · Arc", pinned: true },
  { kind: "url",  content: "https://youtube.com/watch?v=…", meta: "25m ago · Safari" },
  { kind: "url",  content: "https://github.com/panayar",    meta: "1h ago · Arc" },
  // Code
  { kind: "code", content: "npm install clippybar", meta: "7m ago · VS Code" },
  { kind: "code", content: "git push --force",      meta: "30m ago · iTerm2", pinned: true },
  { kind: "code", content: "console.log(42)",       meta: "1h ago · VS Code" },
];

type HeroRipplesHandle = { spawnAt: (x: number, y: number) => void };

const HeroRipples = forwardRef<HeroRipplesHandle>(function HeroRipples(_props, ref) {
  type Ripple = { id: number; x: number; y: number; snippet: RippleSnippet; tilt: number };
  const [ripples, setRipples] = useState<Ripple[]>([]);
  const idRef = useRef(0);

  const spawnAt = useCallback((x: number, y: number) => {
    const snippet = RIPPLE_SNIPPETS[Math.floor(Math.random() * RIPPLE_SNIPPETS.length)];
    const tilt = Math.random() * 14 - 7;
    const id = idRef.current++;
    const ripple: Ripple = { id, x, y, snippet, tilt };
    setRipples((prev) => [...prev, ripple]);
    window.setTimeout(() => {
      setRipples((prev) => prev.filter((r) => r.id !== id));
    }, 3400);
  }, []);

  useImperativeHandle(ref, () => ({ spawnAt }), [spawnAt]);

  return (
    <div className="hero-ripples">
      {ripples.map((r) => (
        <div
          key={r.id}
          className="hero-ripple"
          style={{ left: r.x, top: r.y, ["--tilt" as string]: `${r.tilt}deg` }}
        >
          {/* Concentric rings radiating out from the click */}
          <span className="hero-ripple-ring hero-ripple-ring-1" />
          <span className="hero-ripple-ring hero-ripple-ring-2" />
          <span className="hero-ripple-ring hero-ripple-ring-3" />
          {/* Clippy-style item that falls to the bottom of the banner */}
          <div className={`hero-ripple-item hero-ripple-${r.snippet.kind}`}>
            {r.snippet.kind === "image" ? (
              <img
                className="hero-ripple-thumb"
                src={r.snippet.src}
                alt=""
                loading="lazy"
                draggable={false}
              />
            ) : null}
            <div className="hero-ripple-body">
              <span className="hero-ripple-title">
                {r.snippet.kind === "image" ? "Image" : r.snippet.content}
              </span>
              <span className="hero-ripple-meta">{r.snippet.meta}</span>
            </div>
            {r.snippet.pinned && (
              <svg
                className="hero-ripple-pin"
                width="11"
                height="11"
                viewBox="0 0 24 24"
                fill="currentColor"
                aria-hidden="true"
              >
                <path d="M16 3v5.586l3.293 3.293a1 1 0 0 1-.293 1.621L13 15.414V21a1 1 0 0 1-2 0v-5.586l-6-1.914a1 1 0 0 1-.293-1.621L8 8.586V3a1 1 0 0 1 1-1h6a1 1 0 0 1 1 1z" />
              </svg>
            )}
          </div>
        </div>
      ))}
    </div>
  );
});

function HeroSection() {
  const [phase, setPhase] = useState(0);
  const [skipIntro, setSkipIntro] = useState(false);
  const sectionRef = useRef<HTMLElement>(null);
  const ripplesRef = useRef<HeroRipplesHandle>(null);

  const handleHeroClick = useCallback((e: React.MouseEvent<HTMLElement>) => {
    if (!sectionRef.current || !ripplesRef.current) return;
    const rect = sectionRef.current.getBoundingClientRect();
    ripplesRef.current.spawnAt(e.clientX - rect.left, e.clientY - rect.top);
  }, []);
  // 0: empty
  // 1: cursor appears center, does a playful wiggle
  // 2: cursor moves to the side, ⌥V shortcut appears center
  // 3: picker appears center, cursor moves onto the first item
  // 4: click — cursor punch + ripple fire AND item highlights (picker still visible)
  // 5: picker closes, text pastes as headline
  // 6: cursor exits
  // 7: rest of content reveals

  const handlePickerClick = useCallback(() => setPhase(4), []);
  const handlePickerPaste = useCallback(() => setPhase(5), []);

  const [activeSlide, setActiveSlide] = useState(0);

  useEffect(() => {
    // Auto-advance the tagline carousel only after the intro animation
    // finishes, and reset the timer whenever the slide changes (from either
    // auto-advance or a manual dot click).
    if (phase < 7) return;
    const t = setTimeout(() => {
      setActiveSlide((i) => (i + 1) % heroSlides.length);
    }, 11000);
    return () => clearTimeout(t);
  }, [activeSlide, phase]);

  useEffect(() => {
    const prefersReduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    if (prefersReduced) {
      setSkipIntro(true);
      setPhase(7);
      return;
    }
    const timers = [
      setTimeout(() => setPhase(1), 300),    // cursor appears + wiggle
      setTimeout(() => setPhase(2), 1800),   // cursor aside, shortcut center
      setTimeout(() => setPhase(3), 2800),   // picker appears, cursor moves to item
      // phase 4 triggered by picker onClick (~700ms after phase 3)
      // phase 5 triggered by picker onPaste (~1400ms after phase 3)
      setTimeout(() => setPhase(6), 5400),   // cursor exits
      setTimeout(() => setPhase(7), 6100),   // content reveals
    ];
    return () => timers.forEach(clearTimeout);
  }, []);

  // Handle bfcache restore (same-tab back button). useEffect won't re-run
  // and timers were cleared when the tab was frozen — force the final state.
  useEffect(() => {
    const onPageShow = (e: PageTransitionEvent) => {
      if (!e.persisted) return;
      setSkipIntro(true);
      setPhase(7);
      document
        .querySelectorAll(".section-reveal")
        .forEach((el) => el.classList.add("visible"));
    };
    window.addEventListener("pageshow", onPageShow);
    return () => window.removeEventListener("pageshow", onPageShow);
  }, []);

  const word1 = "Clippy".split("");
  const word2 = "Bar".split("");

  return (
    <section
      ref={sectionRef}
      className="hero-banner"
      style={{ background: "#FAF7F2" }}
      onClick={handleHeroClick}
    >
      {/* Ripple snippets — only on click, anywhere inside the banner */}
      <HeroRipples ref={ripplesRef} />

      {/* Hint chip — signals the banner is interactive */}
      <motion.div
        aria-hidden="true"
        className="hero-click-hint"
        initial={skipIntro ? false : { opacity: 0, y: 8 }}
        animate={phase >= 7 ? { opacity: 1, y: 0 } : {}}
        transition={{ duration: 0.6, delay: 0.9, ease: [0.22, 0.8, 0.28, 1] }}
      >
        <span className="hero-click-hint-emoji">👆</span>
        <span>click anywhere</span>
      </motion.div>

      <div className="hero-banner-inner">

        {/* Animated cursor */}
        <AnimatePresence>
          {phase >= 1 && phase <= 5 && (
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
                      scale: 1,
                    }
                  : phase === 2
                  ? { left: "70%", top: "38%", opacity: 1, y: 0, scale: 1 }
                  : phase === 3
                  ? { left: "calc(50% - 60px)", top: "calc(50% - 110px)", opacity: 1, y: 0, scale: 1 }
                  : phase === 4
                  ? { left: "calc(50% - 60px)", top: "calc(50% - 110px)", opacity: 1, y: 0, scale: [1, 0.78, 1] }
                  : { left: "calc(50% - 60px)", top: "calc(50% - 110px)", opacity: 1, y: 0, scale: 1 }
              }
              exit={{ left: "-10%", top: "30%", opacity: 0 }}
              transition={
                phase === 1
                  ? { duration: 0.8, ease: [0.2, 0.8, 0.2, 1] }
                  : phase === 4
                  ? {
                      duration: 0.6,
                      ease: [0.32, 0.72, 0, 1],
                      scale: { duration: 0.32, times: [0, 0.45, 1], ease: [0.4, 0, 0.2, 1] },
                    }
                  : { duration: 0.6, ease: [0.32, 0.72, 0, 1] }
              }
            />
          )}
        </AnimatePresence>

        {/* Click ripple — Screen Studio style feedback */}
        <AnimatePresence>
          {phase === 4 && (
            <>
              <motion.span
                className="hero-click-ripple"
                initial={{ scale: 0.2, opacity: 0.55 }}
                animate={{ scale: 2.6, opacity: 0 }}
                transition={{ duration: 0.6, ease: [0.22, 0.8, 0.28, 1] }}
              />
              <motion.span
                className="hero-click-ripple hero-click-ripple-inner"
                initial={{ scale: 0.1, opacity: 0.75 }}
                animate={{ scale: 1.6, opacity: 0 }}
                transition={{ duration: 0.45, ease: [0.22, 0.8, 0.28, 1] }}
              />
            </>
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
          {(phase === 3 || phase === 4) && (
            <motion.div
              className="hero-picker-wrapper"
              initial={{ opacity: 0, scale: 0.92, y: 16 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.96, y: -8 }}
              transition={{ duration: 0.3, ease: [0.32, 0.72, 0, 1] }}
            >
              <ClippyPickerMock onClick={handlePickerClick} onPaste={handlePickerPaste} />
            </motion.div>
          )}
        </AnimatePresence>

      </div>

      {/* Text content */}
      <div className="relative mx-auto max-w-[1400px] px-6 sm:px-8 lg:px-12" style={{ zIndex: 1 }}>
        {/* The headline — pastes in after picker selection */}
        <div className="relative">
          <h1 className="hero-display">
            {skipIntro ? (
              <>
                <span className="block">Clippy</span>
                <span className="block">Bar</span>
              </>
            ) : phase >= 5 ? (
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

          {phase === 5 && (
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
          initial={skipIntro ? false : { opacity: 0, y: 24 }}
          animate={phase >= 7 ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.8, ease: [0.32, 0.72, 0, 1] }}
          className="mt-10 md:mt-14 flex flex-col md:flex-row md:items-end md:justify-between gap-8"
        >
          <div className="hero-tagline-slot max-w-md">
            <AnimatePresence mode="wait">
              <motion.p
                key={activeSlide}
                className="text-[#6B7280] text-base md:text-lg leading-relaxed"
                initial={{ opacity: 0, y: 8 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -8 }}
                transition={{ duration: 0.4, ease: [0.32, 0.72, 0, 1] }}
              >
                {heroSlides[activeSlide]}
              </motion.p>
            </AnimatePresence>
          </div>
          <a href="#features" className="btn-pill-outline shrink-0">
            Explore ClippyBar
            <ArrowRight />
          </a>
        </motion.div>

        {/* Dot indicators */}
        <motion.div
          initial={skipIntro ? false : { opacity: 0 }}
          animate={phase >= 7 ? { opacity: 1 } : {}}
          transition={{ duration: 0.6, delay: 0.2 }}
          className="flex items-center gap-2 mt-10"
          role="tablist"
          aria-label="Tagline"
        >
          {heroSlides.map((_, i) => (
            <button
              key={i}
              type="button"
              role="tab"
              aria-selected={i === activeSlide}
              aria-label={`Show tagline ${i + 1}`}
              onClick={() => setActiveSlide(i)}
              className={`hero-dot ${i === activeSlide ? "hero-dot-active" : ""}`}
            />
          ))}
        </motion.div>

        {/* Main demo video */}
        <motion.div
          initial={skipIntro ? false : { opacity: 0, y: 32 }}
          animate={phase >= 7 ? { opacity: 1, y: 0 } : {}}
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
            We believe that a great clipboard manager is <strong>more than just storage.
            It&#39;s about creating workflows where productivity happens.</strong>{" "}
            ClippyBar is thoughtfully crafted to combine instant recall, privacy-first
            design, everyday functionality, and lasting simplicity.
          </p>
        </div>
      </div>
    </section>
  );
}

/* ------------------------------------------------------------------ */
/*  Features Showcase — alternating spotlight rows                     */
/* ------------------------------------------------------------------ */

type FeatureShortcut = { keys: string[]; label: string };

const features: Array<{
  num: string;
  title: string;
  description: string;
  media: string;
  shortcut?: FeatureShortcut;
}> = [
  {
    num: "01",
    title: "Smart Filters",
    description:
      "Narrow your clipboard by type: text, links, files, or images. Find the right snippet with a single click, without scrolling through noise.",
    media: "/demos/filters.mp4",
    shortcut: { keys: ["⌘", "F"], label: "Toggle filters" },
  },
  {
    num: "02",
    title: "Instant Search",
    description:
      "Type and find any snippet you’ve ever copied, in milliseconds. Fuzzy matching and keyboard-first controls mean you never lose track of what you need.",
    media: "/demos/search.mp4",
    shortcut: { keys: ["Type"], label: "Start searching" },
  },
  {
    num: "03",
    title: "Clean Up Fast",
    description:
      "Delete a single item or scrub a sensitive paste in a tap. Keep your history tidy without ever leaving the picker.",
    media: "/demos/delete.mp4",
    shortcut: { keys: ["⌘", "⌫"], label: "Delete selected item" },
  },
  {
    num: "04",
    title: "Edit Before Paste",
    description:
      "Tweak a snippet in place before it hits the clipboard: trim whitespace, fix a typo, adjust a link. Small fixes shouldn’t break your flow.",
    media: "/demos/edit.mp4",
    shortcut: { keys: ["⌘", "E"], label: "Edit selected item" },
  },
  {
    num: "05",
    title: "Pin Favorites",
    description:
      "Keep go-to snippets pinned to the top of your history. Always one shortcut away, never buried under fresh copies.",
    media: "/demos/pin.mp4",
    shortcut: { keys: ["⌘", "P"], label: "Pin / unpin item" },
  },
];

function FeatureRow({
  feature,
  index,
}: {
  feature: (typeof features)[number];
  index: number;
}) {
  const ref = useReveal();
  const reverse = index % 2 === 1;

  return (
    <div
      ref={ref}
      className="section-reveal grid grid-cols-1 lg:grid-cols-2 gap-10 lg:gap-20 items-center mb-24 md:mb-32 last:mb-0"
    >
      <div className={`flex ${reverse ? "lg:order-2 lg:justify-end" : "lg:justify-start"}`}>
        <div className="media-card feature-media">
          <video autoPlay muted loop playsInline>
            <source src={feature.media} type="video/mp4" />
          </video>
        </div>
      </div>
      <div className={reverse ? "lg:order-1" : ""}>
        <span className="text-xs font-semibold text-[#9CA3AF] tracking-widest uppercase block mb-4">
          {feature.num}
        </span>
        <h3 className="text-3xl md:text-4xl font-semibold text-[#1A1A1A] tracking-tight mb-5 leading-tight">
          {feature.title}
        </h3>
        <p className="text-[#6B7280] text-base md:text-lg leading-relaxed max-w-md">
          {feature.description}
        </p>
        {feature.shortcut && (
          <div className="feature-shortcut">
            <span className="feature-shortcut-keys">
              {feature.shortcut.keys.map((k, i) => (
                <kbd key={i} className="feature-key">{k}</kbd>
              ))}
            </span>
            <span className="feature-shortcut-label">{feature.shortcut.label}</span>
          </div>
        )}
      </div>
    </div>
  );
}

function FeaturesShowcase() {
  return (
    <section
      id="features"
      className="features-section py-24 md:py-36"
      style={{ background: "#FAF7F2" }}
    >
      {/* Hand-drawn walk-through line snaking between rows */}
      <svg
        className="features-walkline"
        viewBox="0 0 1200 3200"
        preserveAspectRatio="none"
        aria-hidden="true"
      >
        {/* Dashed zigzag */}
        <path
          d="M 600 0
             Q 240 360,  600 720
             Q 960 1080, 600 1440
             Q 240 1800, 600 2160
             Q 960 2520, 600 2880
             Q 300 3100, 600 3200"
          stroke="#1A1A1A"
          strokeWidth="1.5"
          strokeDasharray="5 9"
          fill="none"
          strokeLinecap="round"
          strokeLinejoin="round"
          opacity="0.55"
        />
      </svg>

      <div className="features-inner relative mx-auto max-w-[1200px] px-6 sm:px-8 lg:px-12">
        <div className="mb-16 md:mb-20">
          <div className="about-divider" />
          <h2 className="text-2xl md:text-3xl font-light text-[#1A1A1A] tracking-tight">
            Our <em className="font-semibold not-italic">Features</em>
          </h2>
        </div>
        {features.map((f, i) => (
          <FeatureRow key={f.num} feature={f} index={i} />
        ))}
      </div>
    </section>
  );
}

/* ------------------------------------------------------------------ */
/*  Trust / Stats Section                                              */
/* ------------------------------------------------------------------ */

function Clippy3DStack() {
  return (
    <div className="clippy3d-scene" aria-hidden="true">
      <div className="clippy3d-card clippy3d-card-1">
        <span className="clippy3d-badge">TXT</span>
        <span className="clippy3d-title">Meeting notes — sync with design</span>
        <span className="clippy3d-meta">just now &middot; Notes</span>
      </div>
      <div className="clippy3d-card clippy3d-card-2">
        <span className="clippy3d-badge clippy3d-badge-link">URL</span>
        <span className="clippy3d-title clippy3d-title-link">https://clippybar.app</span>
        <span className="clippy3d-meta">2m ago &middot; Arc</span>
      </div>
      <div className="clippy3d-card clippy3d-card-3">
        <span className="clippy3d-badge clippy3d-badge-img">IMG</span>
        <span className="clippy3d-thumb" />
        <span className="clippy3d-meta">7m ago &middot; Screenshot</span>
      </div>
      <div className="clippy3d-card clippy3d-card-4">
        <span className="clippy3d-badge clippy3d-badge-code">CODE</span>
        <span className="clippy3d-title clippy3d-title-code">const x = clipboard.get()</span>
        <span className="clippy3d-meta">14m ago &middot; VS Code</span>
      </div>
      <div className="clippy3d-keycap">
        <span>⌥</span>
        <span>V</span>
      </div>
    </div>
  );
}

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
          {/* Left: 3D clipboard stack */}
          <div className="flex justify-center lg:justify-start">
            <Clippy3DStack />
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
    <section id="faq" ref={ref} className="section-reveal py-24 md:py-36" style={{ background: "#FAF7F2" }}>
      <div className="mx-auto max-w-[800px] px-6 sm:px-8 lg:px-12">
        <div className="text-center mb-14 md:mb-16">
          <span className="section-label mb-5">
            <span className="section-label-dot" /> Have Questions?
          </span>
          <h2
            className="text-[#1A1A1A] font-bold leading-[1.1] mb-4"
            style={{ fontSize: "clamp(2rem, 4vw, 2.75rem)" }}
          >
            Frequently asked questions
          </h2>
          <p className="text-[#6B7280] text-base leading-relaxed max-w-lg mx-auto">
            Everything you need to know about ClippyBar: permissions, privacy,
            and getting started.
          </p>
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
    <section ref={ref} className="section-reveal cta-section">
      <div className="mx-auto max-w-[760px] px-6 sm:px-8 lg:px-12 text-center flex flex-col items-center">
        <span className="section-label mb-6">
          <span className="section-label-dot" /> Get Started
        </span>
        <div className="cta-heading-wrap">
          <h2 className="cta-heading">
            Ready to paste{" "}
            <span className="cta-heading-accent">smarter?</span>
          </h2>
          <motion.svg
            className="cta-underline"
            viewBox="0 0 300 20"
            preserveAspectRatio="none"
            aria-hidden="true"
          >
            <defs>
              <linearGradient id="cta-underline-gradient" x1="0" y1="0" x2="1" y2="0">
                <stop offset="0%"   stopColor="#F472B6" />
                <stop offset="50%"  stopColor="#FB923C" />
                <stop offset="100%" stopColor="#FBBF24" />
              </linearGradient>
            </defs>
            <motion.path
              d="M 0,10 Q 75,0 150,10 Q 225,20 300,10"
              stroke="url(#cta-underline-gradient)"
              strokeWidth="2.5"
              strokeLinecap="round"
              fill="none"
              initial={{ pathLength: 0, opacity: 0 }}
              whileInView={{ pathLength: 1, opacity: 1 }}
              viewport={{ once: true, amount: 0.6 }}
              transition={{ duration: 1.4, ease: "easeInOut" }}
            />
          </motion.svg>
        </div>
        <p className="cta-sub">
          Download ClippyBar for free and experience a clipboard that works the
          way you think. No subscriptions, no accounts, no catch.
        </p>
        <div className="mb-5 flex flex-col sm:flex-row items-center gap-3">
          <a
            href={APP_STORE_URL}
            target="_blank"
            rel="noopener noreferrer"
            className="btn-primary gap-2"
          >
            <AppleIcon />
            Download Free
          </a>
          <a
            href={GITHUB_URL}
            target="_blank"
            rel="noopener noreferrer"
            className="cta-github"
          >
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
              <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/>
            </svg>
            Leave us a star on GitHub
          </a>
        </div>
        <p className="cta-meta">
          macOS 13+ &middot; Apple Silicon &amp; Intel &middot; Free forever
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
    <footer className="py-10" style={{ background: "#1A1A1A" }}>
      <div className="mx-auto max-w-[1400px] px-6 sm:px-8 lg:px-12">
        <div className="flex flex-col md:flex-row items-center justify-between gap-6">
          <div className="flex items-center gap-0.5">
            <ClippyBarLogo size={30} fill="#FFFFFF" />
            <span className="text-sm font-semibold text-white tracking-tight">
              ClippyBar
            </span>
          </div>

          <div className="flex flex-wrap justify-center items-center gap-x-6 gap-y-3 sm:gap-8">
            <a href="#features" className="text-xs text-[#9CA3AF] uppercase tracking-widest hover:text-white transition-colors no-underline">
              Features
            </a>
            <a href="#faq" className="text-xs text-[#9CA3AF] uppercase tracking-widest hover:text-white transition-colors no-underline">
              FAQ
            </a>
            <span className="footer-tooltip">
              <button
                type="button"
                className="text-xs text-[#9CA3AF] uppercase tracking-widest hover:text-white transition-colors bg-transparent border-none p-0 cursor-help"
                aria-describedby="privacy-policy-tooltip"
              >
                Privacy
              </button>
              <span id="privacy-policy-tooltip" role="tooltip" className="footer-tooltip-panel">
                <span className="footer-tooltip-title">Privacy Policy</span>
                <span className="footer-tooltip-body">
                  ClippyBar does not collect, store, or transmit any personal
                  data. All clipboard data is stored locally on your Mac in
                  ~/Library/Application Support/ClippyBar/. The app makes zero
                  network requests. No analytics, no telemetry, no tracking.
                  Optional memory-only mode ensures nothing is written to disk.
                </span>
                <span className="footer-tooltip-meta">Last updated: March 2026</span>
              </span>
            </span>
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
        <FeaturesShowcase />
        <TrustSection />
        <FAQSection />
        <CTASection />
      </main>
      <Footer />
    </>
  );
}
