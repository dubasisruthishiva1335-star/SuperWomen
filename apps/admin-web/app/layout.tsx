import Link from 'next/link';
import 'leaflet/dist/leaflet.css';
import './globals.css';

export const metadata = { title: 'Super Women Admin' };

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en"><body>
      <nav>
        <b>💜 Super Women Admin</b>
        <Link href="/">Dashboard</Link><Link href="/kyc">KYC</Link><Link href="/sos">SOS</Link><Link href="/support">Support</Link>
      </nav>
      <main>{children}</main>
    </body></html>
  );
}
