import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "ClippyBar",
  description:
    "A beautiful clipboard manager for macOS. Save your clipboard history, search, pin, and paste with a single shortcut. 100% local, 100% private.",
  openGraph: {
    title: "ClippyBar — Everything you copy, instantly recalled.",
    description:
      "A beautiful clipboard manager for macOS. Save your clipboard history, search, pin, and paste with a single shortcut. 100% local, 100% private.",
    type: "website",
    siteName: "ClippyBar",
  },
  twitter: {
    card: "summary_large_image",
    title: "ClippyBar — Everything you copy, instantly recalled.",
    description:
      "A beautiful clipboard manager for macOS. Save your clipboard history, search, pin, and paste with a single shortcut. 100% local, 100% private.",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <head>
        <meta httpEquiv="Cache-Control" content="no-store, no-cache, must-revalidate" />
        <meta httpEquiv="Pragma" content="no-cache" />
      </head>
      <body
        className="min-h-screen antialiased"
        style={{
          fontFamily:
            '-apple-system, BlinkMacSystemFont, "SF Pro Display", "SF Pro Text", system-ui, sans-serif',
          background: "#F5F5F7",
          color: "#1D1D1F",
        }}
      >
        {children}
      </body>
    </html>
  );
}
