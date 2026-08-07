import type { Metadata, Viewport } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";
import { Toaster } from "@/components/ui/toaster";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

const APP_ICON = `data:image/svg+xml,${encodeURIComponent(
  `<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 64 64'>
    <defs><linearGradient id='g' x1='0' y1='0' x2='1' y2='1'>
      <stop offset='0' stop-color='%23d4a853'/>
      <stop offset='1' stop-color='%23f090ac'/>
    </linearGradient></defs>
    <rect width='64' height='64' rx='16' fill='%230f0d0a'/>
    <rect x='0.75' y='0.75' width='62.5' height='62.5' rx='15.25' fill='none' stroke='rgba(255,255,255,0.14)'/>
    <text x='32' y='45' font-family='Arial,Helvetica,sans-serif' font-size='40' font-weight='900' font-style='italic' fill='url(%23g)' text-anchor='middle'>S</text>
  </svg>`
)}`;

export const metadata: Metadata = {
  title: "Synesthesia — Hear Colors. See Sound. Feel Music.",
  description:
    "An iOS app that turns the world into music — point your camera at a color and hear it as a note, listen as sound becomes light, and feel rhythms through Core Haptics. Swift Student Challenge 2026.",
  keywords: [
    "Synesthesia",
    "Swift Student Challenge",
    "iOS",
    "SwiftUI",
    "AVFoundation",
    "Core Haptics",
    "cross-sensory",
    "accessibility",
  ],
  authors: [{ name: "Subhansh" }],
  applicationName: "Synesthesia",
  icons: {
    icon: APP_ICON,
    apple: APP_ICON,
  },
  appleWebApp: {
    capable: true,
    title: "Synesthesia",
    statusBarStyle: "black-translucent",
  },
  openGraph: {
    title: "Synesthesia — Hear Colors. See Sound. Feel Music.",
    description:
      "An iOS app that turns the world into music — see colors, hear notes, and feel rhythms through real camera, microphone, and Core Haptics. Swift Student Challenge 2026.",
    type: "website",
    siteName: "Synesthesia",
  },
  twitter: {
    card: "summary_large_image",
    title: "Synesthesia — Hear Colors. See Sound. Feel Music.",
    description:
      "Cross-sensory AI for iOS: see sound, hear color, feel music.",
  },
};

export const viewport: Viewport = {
  themeColor: "#0f0d0a",
  width: "device-width",
  initialScale: 1,
  viewportFit: "cover",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className="dark" suppressHydrationWarning>
      <head>
        <meta name="format-detection" content="telephone=no" />
        <meta name="apple-mobile-web-app-title" content="Synesthesia" />
        <meta name="apple-mobile-web-app-capable" content="yes" />
      </head>
      <body
        className={`${geistSans.variable} ${geistMono.variable} antialiased bg-[var(--bg)] text-ink selection:bg-teal/30`}
      >
        {children}
        <Toaster />
      </body>
    </html>
  );
}