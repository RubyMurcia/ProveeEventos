import type { ReactNode } from 'react';

import './globals.css';

export const metadata = { title: 'ProveeEventos' };

export default function RootLayout({ children }: Readonly<{ children: ReactNode }>) {
  return (
    <html lang="es-CO">
      <body>{children}</body>
    </html>
  );
}
