"use client";

import { useEffect, useState } from "react";

export default function Home() {
  const [power, setPower] = useState(0);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [lastUpdate, setLastUpdate] = useState<string>("");

  // Polling toutes les 2 secondes
  useEffect(() => {
    async function fetchPower() {
      try {
        setIsLoading(true);

        // Essaie d'abord le proxy Next.js
        const res = await fetch("/api/usage/current");

        if (!res.ok) {
          // Si le proxy échoue, essaie directement
          const fallbackRes = await fetch("http://localhost:8083/usage/current");
          if (!fallbackRes.ok) {
            throw new Error(`Both proxy and direct connection failed`);
          }
          const fallbackData = await fallbackRes.json();
          setPower(fallbackData.totalPowerKw);
          setError("Using direct connection (proxy failed)");
        } else {
          const data = await res.json();
          setPower(data.totalPowerKw);
          setError(null);
        }

        setLastUpdate(new Date().toLocaleTimeString());
      } catch (err) {
        console.error("Fetch error:", err);
        setError("Unable to connect to energy monitor API");
        setPower(0);
      } finally {
        setIsLoading(false);
      }
    }

    fetchPower();
    const interval = setInterval(fetchPower, 2000);
    return () => clearInterval(interval);
  }, []);

  return (
      <main className="flex flex-col items-center justify-center min-h-screen bg-gradient-to-br from-gray-50 to-gray-100 p-4">
        <div className="text-center mb-8">
          <h1 className="text-4xl md:text-5xl font-bold text-gray-800 mb-4">
            🏠 Smart Home Energy Monitor
          </h1>
          <p className="text-gray-600 text-lg">
            Real-time power consumption tracking
          </p>
        </div>

        <div className="bg-white shadow-2xl rounded-2xl p-6 md:p-10 text-center w-full max-w-2xl border border-gray-200">
          <p className="text-gray-500 text-xl md:text-2xl mb-4">Current Power Usage</p>

          {isLoading ? (
              <div className="flex flex-col justify-center items-center h-40">
                <div className="animate-spin rounded-full h-16 w-16 border-b-4 border-blue-600 mb-4"></div>
                <p className="text-gray-500">Connecting to energy monitor...</p>
              </div>
          ) : (
              <>
                <div className="flex items-center justify-center mb-6">
                  <div className="text-center">
                    <p className="text-6xl md:text-8xl font-black bg-gradient-to-r from-blue-600 to-blue-800 bg-clip-text text-transparent">
                      {power.toFixed(3)}
                    </p>
                    <p className="text-lg md:text-xl text-gray-500 mt-2">kilowatts (kW)</p>
                  </div>
                </div>

                {/* Jauge visuelle */}
                <div className="mt-8">
                  <div className="w-full bg-gray-200 rounded-full h-3 md:h-4">
                    <div
                        className="bg-gradient-to-r from-green-400 via-blue-500 to-purple-600 h-3 md:h-4 rounded-full transition-all duration-500"
                        style={{ width: `${Math.min(power * 10, 100)}%` }}
                    ></div>
                  </div>
                  <div className="flex justify-between text-xs md:text-sm text-gray-500 mt-2">
                    <span>0 kW</span>
                    <span>Low</span>
                    <span>Medium</span>
                    <span>High</span>
                    <span>10 kW</span>
                  </div>
                </div>
              </>
          )}

          {/* État de la connexion */}
          <div className="mt-6">
            {error ? (
                <div className="inline-flex items-center px-4 py-2 rounded-full bg-red-100 text-red-800">
                  <div className="w-3 h-3 rounded-full bg-red-500 mr-2"></div>
                  {error}
                </div>
            ) : (
                <div className="inline-flex items-center px-4 py-2 rounded-full bg-green-100 text-green-800">
                  <div className="w-3 h-3 rounded-full bg-green-500 animate-pulse mr-2"></div>
                  Connected to smart home API
                </div>
            )}
            {lastUpdate && (
                <p className="text-sm text-gray-500 mt-2">
                  Last updated: {lastUpdate}
                </p>
            )}
          </div>
        </div>

        <footer className="mt-8 text-gray-500 text-center text-sm">
          <p>Data updates every 2 seconds • Smart Home Load Balancer</p>
          <p className="mt-1">Backend: localhost:8083 • Frontend: localhost:3000</p>
        </footer>
      </main>
  );
}