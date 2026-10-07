'use client';
import { MapContainer, TileLayer, CircleMarker, Popup } from 'react-leaflet';

export default function SosMap({ items }: { items: any[] }) {
  const c: [number, number] = items[0] ? [items[0].lat, items[0].lng] : [17.385, 78.4867];
  return (
    <MapContainer center={c} zoom={12} style={{ height: 420, borderRadius: 12 }} key={items.length}>
      <TileLayer url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png" attribution="© OpenStreetMap" />
      {items.map((e) => (
        <CircleMarker key={e.id} center={[e.lat, e.lng]} radius={12} pathOptions={{ color: '#c62828', fillOpacity: 0.7 }}>
          <Popup>{e.ride?.customer?.name} ({e.ride?.customer?.phone})<br />Captain: {e.ride?.captain?.name}</Popup>
        </CircleMarker>
      ))}
    </MapContainer>
  );
}
