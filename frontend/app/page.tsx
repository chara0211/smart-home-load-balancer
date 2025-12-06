"use client";

import { useEffect, useState } from "react";

export default function Home() {
  const [power, setPower] = useState(0);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Polling toutes les 2 secondes
  useEffect(() => {
    async function fetchPower() {
      try {
        setIsLoading(true);
        // Utilise le proxy Next.js au lieu de l'URL directe
        const res = await fetch("/api/usage/current");

        if (!res.ok) {
          throw new Error(`API error: ${res.status}`);
        }

        const data = await res.json();
        setPower(data.totalPowerKw);
        setError(null);
      } catch (err) {
        console.error("Fetch error:", err);
        setError("Unable to connect to energy monitor API");
        setPower(0); // Valeur par défaut
      } finally {
        setIsLoading(false);
      }
    }

    fetchPower();
    const interval = setInterval(fetchPower, 2000);
    return () => clearInterval(interval);
  }, []);

  return (
      <main className="flex flex-col items-center justify-center h-screen bg-gradient-to-br from-gray-50 to-gray-100">
        <div className="text-center mb-8">
          <h1 className="text-5xl font-bold text-gray-800 mb-4">
            🏠 Smart Home Energy Monitor
          </h1>
          <p className="text-gray-600 text-lg">
            Real-time power consumption tracking
          </p>
        </div>

        <div className="bg-white shadow-2xl rounded-2xl p-10 text-center w-full max-w-2xl border border-gray-200">
          <p className="text-gray-500 text-2xl mb-4">Current Power Usage</p>

          {isLoading ? (
              <div className="flex justify-center items-center h-40">
                <div className="animate-spin rounded-full h-16 w-16 border-b-4 border-blue-600"></div>
              </div>
          ) : error ? (
              <div className="text-red-500 p-4 bg-red-50 rounded-lg">
                <p className="text-xl">⚠️ {error}</p>
                <p className="text-sm mt-2">Make sure the backend is running on port 8083</p>
              </div>
          ) : (
              <>
                <div className="flex items-center justify-center mb-6">
                  <div className="text-center">
                    <p className="text-8xl font-black bg-gradient-to-r from-blue-600 to-blue-800 bg-clip-text text-transparent">
                      {power.toFixed(3)}
                    </p>
                    <p className="text-xl text-gray-500 mt-2">kilowatts (kW)</p>
                  </div>
                </div>

                {/* Jauge visuelle */}
                <div className="mt-8">
                  <div className="w-full bg-gray-200 rounded-full h-4">
                    <div
                        className="bg-gradient-to-r from-green-400 via-blue-500 to-purple-600 h-4 rounded-full transition-all duration-500"
                        style={{ width: `${Math.min(power * 10, 100)}%` }}
                    ></div>
                  </div>
                  <div className="flex justify-between text-sm text-gray-500 mt-2">
                    <span>0 kW</span>
                    <span>Low</span>
                    <span>Medium</span>
                    <span>High</span>
                    <span>10 kW</span>
                  </div>
                </div>
              </>
          )}
        </div>

        {/* Information sur la connexion */}
        <div className="mt-6 text-center">
          <div className={`inline-flex items-center px-4 py-2 rounded-full ${error ? 'bg-red-100 text-red-800' : 'bg-green-100 text-green-800'}`}>
            <div className={`w-3 h-3 rounded-full mr-2 ${error ? 'bg-red-500' : 'bg-green-500 animate-pulse'}`}></div>
            {error ? 'Backend disconnected' : 'Connected to smart home API'}
          </div>
        </div>

        <footer className="mt-12 text-gray-500 text-center">
          <p>Data updates every 2 seconds • Connected to Smart Home Load Balancer</p>
        </footer>
      </main>
  );
}