"use client";

import React, { useEffect, useMemo, useRef, useState } from "react";
import {
  Bell,
  Home,
  LayoutGrid,
  Search,
  Wifi,
  Lightbulb,
  Refrigerator,
  Activity,
  Zap,
  AlertTriangle,
  Flame,
  RefreshCw,
  CheckCircle2,
  XCircle,
  Loader2,
  TrendingUp,
  TrendingDown,
  DollarSign,
  Clock,
  Target,
  Calendar,
  Power,
  Sparkles,
  BarChart3,
  Tv,
  Wind,
} from "lucide-react";
import {
  ResponsiveContainer,
  AreaChart,
  Area,
  XAxis,
  YAxis,
  Tooltip,
  LineChart,
  Line,
  BarChart,
  Bar,
  PieChart as RechartsPieChart,
  Pie,
  Cell,
} from "recharts";

/* ======================
   TYPES
====================== */

type HealthPayload = {
  partial: boolean;
  services: {
    usage: { ok: boolean; status: "UP" | "DOWN"; detail?: string };
    devices: { ok: boolean; status: "UP" | "DOWN"; detail?: string };
    peaks: { ok: boolean; status: "UP" | "DOWN"; detail?: string };
    optimizer: { ok: boolean; status: "UP" | "DOWN"; detail?: string };
    billing?: { ok: boolean; status: "UP" | "DOWN"; detail?: string };
  };
};

type UsageCurrent = {
  totalPowerKw: number;
  deviceCount?: number;
  devices?: Record<string, number>;
};

type ApiDevice = {
  id: string;
  type: string;
  priority: string;
  state: "ON" | "OFF" | "STANDBY" | string;
  basePowerKw?: number;
  currentPowerKw?: number;
};

type Device = {
  id: string;
  name: string;
  type?: string;
  room?: string;
  isOn: boolean;
  powerKw?: number;
  priority?: string;
};

type PeakEvent = {
  id: string;
  level: "WARNING" | "CRITICAL" | string;
  totalPowerKw: number;
  timestamp: string;
};

type ParsedCmd = { ts?: string; deviceId: string; action: string; raw: string };

type ViewMode = "overview" | "devices" | "analytics" | "automation" | "savings";

type PowerHistory = {
  timestamp: string;
  power: number;
  cost: number;
};

type Recommendation = {
  id: string;
  type: "cost" | "efficiency" | "peak" | "automation";
  priority: "high" | "medium" | "low";
  title: string;
  description: string;
  potentialSavings?: number;
  action?: string;
};

type SavingsApi = {
  totalSavingsMad: number;
  monthlySavingsMad: number;
  dailySavingsMad: number;
  totalPeaksPrevented: number;
  totalAutomationActions: number;
};

/* ======================
   CONFIG - MOROCCO
====================== */

const MOROCCO_CONFIG = {
  currency: "MAD",
  currencySymbol: "DH",
  costPerKwh: 1.22,
  taxRate: 0.14,
  monthlySubscription: 10.0,
  tiers: {
    tier1: { max: 100, rate: 1.06 },
    tier2: { max: 200, rate: 1.22 },
    tier3: { max: 500, rate: 1.35 },
    tier4: { max: Infinity, rate: 1.61 },
  },
};

const COST_PER_KWH = MOROCCO_CONFIG.costPerKwh;
const PEAK_THRESHOLD = 8;
const WARNING_THRESHOLD = 6;

const CHART_COLORS = {
  primary: "rgba(99,102,241,0.95)",
  secondary: "rgba(56,189,248,0.85)",
};

const DEVICE_COLORS = [
  "#6366f1",
  "#8b5cf6",
  "#06b6d4",
  "#10b981",
  "#f59e0b",
  "#ef4444",
  "#64748b",
];

/* ======================
   UTILS
====================== */

async function safeJson<T>(
    url: string
): Promise<{ ok: boolean; data?: T; error?: string }> {
  try {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 8000);

    const res = await fetch(url, { cache: "no-store", signal: controller.signal });
    clearTimeout(timeoutId);

    if (!res.ok) {
      const errorText = await res.text().catch(() => "");
      return { ok: false, error: `HTTP ${res.status}${errorText ? `: ${errorText}` : ""}` };
    }

    const data = (await res.json()) as T;
    return { ok: true, data };
  } catch (e: any) {
    if (e?.name === "AbortError") return { ok: false, error: "Request timeout (8s)" };
    return { ok: false, error: e?.message || "fetch failed" };
  }
}

function clamp(n: number, min: number, max: number) {
  return Math.max(min, Math.min(max, n));
}

function fmtTime(ts: string) {
  const d = new Date(ts);
  if (Number.isNaN(d.getTime())) return ts;
  return d.toLocaleTimeString();
}

function fmtKw(n: number | undefined) {
  if (typeof n !== "number" || Number.isNaN(n)) return "n/a";
  return `${n.toFixed(3)} kW`;
}

function fmtCurrencyMad(n: number | undefined) {
  const x = typeof n === "number" && !Number.isNaN(n) ? n : 0;
  return `${x.toFixed(2)} ${MOROCCO_CONFIG.currencySymbol}`;
}

function normalizeLevel(level: string) {
  const l = (level || "").toUpperCase();
  return l === "CRITICAL" ? "CRITICAL" : l === "WARNING" ? "WARNING" : level;
}

function parseOptimizerCommands(lines: string[]): ParsedCmd[] {
  const out: ParsedCmd[] = [];
  for (const raw of lines) {
    if (!raw.includes("📤")) continue;

    const firstSpace = raw.indexOf(" ");
    const ts = firstSpace > 0 ? raw.slice(0, firstSpace) : undefined;

    const arrow = raw.includes("→") ? "→" : "->";
    const pipeIdx = raw.indexOf("|");

    if (pipeIdx !== -1) {
      const afterPipe = raw.slice(pipeIdx + 1).trim();
      const parts = afterPipe.split(arrow).map((s) => s.trim());
      if (parts.length >= 2) {
        out.push({ ts, deviceId: parts[0], action: parts[1], raw });
        continue;
      }
    }

    const m = raw.match(/([a-z0-9-]+)\s*[→-]+\s*([A-Z_]+)/i);
    if (m) out.push({ ts, deviceId: m[1], action: m[2], raw });
  }
  return out;
}

function inferRoomFromId(id: string) {
  const s = id.toLowerCase();
  if (s.includes("living")) return "Living room";
  if (s.includes("bedroom")) return "Bedroom";
  if (s.includes("kitchen") || s.includes("oven") || s.includes("microwave") || s.includes("fridge")) return "Kitchen";
  if (s.includes("washing") || s.includes("dryer")) return "Laundry";
  if (s.includes("aircon") || s.includes("heater") || s.includes("hvac")) return "HVAC";
  if (s.includes("bathroom")) return "Bathroom";
  if (s.includes("garage")) return "Garage";
  if (s.includes("office")) return "Office";
  return "Home";
}

function inferNameFromId(id: string) {
  return id.replace(/-/g, " ").replace(/\b\w/g, (c) => c.toUpperCase());
}

function mapToUiDevice(d: ApiDevice, usageMap?: Record<string, number>): Device {
  const isOn = String(d.state).toUpperCase() === "ON";
  const powerFromUsage = usageMap?.[d.id];
  const powerFallback = typeof d.currentPowerKw === "number" ? d.currentPowerKw : 0;

  return {
    id: d.id,
    name: inferNameFromId(d.id),
    type: d.type,
    room: inferRoomFromId(d.id),
    isOn,
    powerKw: typeof powerFromUsage === "number" ? powerFromUsage : powerFallback,
    priority: d.priority,
  };
}

function calculateCost(powerKw: number, hours: number = 1): number {
  return powerKw * hours * COST_PER_KWH;
}

function generateHistoricalData(currentPower: number): PowerHistory[] {
  const data: PowerHistory[] = [];
  const now = new Date();

  for (let i = 23; i >= 0; i--) {
    const timestamp = new Date(now.getTime() - i * 60 * 60 * 1000);
    const variation = Math.random() * 2 - 1;
    const power = Math.max(0.5, currentPower + variation);

    data.push({
      timestamp: timestamp.toISOString(),
      power: Number(power.toFixed(3)),
      cost: calculateCost(power, 1),
    });
  }
  return data;
}

function generateRecommendations(power: number, devices: Device[], peaks: PeakEvent[]): Recommendation[] {
  const recs: Recommendation[] = [];

  if (power > PEAK_THRESHOLD) {
    recs.push({
      id: "peak-1",
      type: "peak",
      priority: "high",
      title: "High Power Consumption",
      description: `Current usage (${power.toFixed(2)} kW) exceeds peak threshold. Turn off non-essential devices.`,
      potentialSavings: calculateCost(Math.max(0, power - PEAK_THRESHOLD), 1),
      action: "Optimize Now",
    });
  }

  const highPowerDevices = devices.filter((d) => d.isOn && (d.powerKw ?? 0) > 1);
  if (highPowerDevices.length > 0) {
    recs.push({
      id: "efficiency-1",
      type: "efficiency",
      priority: "medium",
      title: "High-Power Devices Active",
      description: `${highPowerDevices.length} high-power device(s) are running. Consider scheduling off-peak.`,
      potentialSavings: highPowerDevices.reduce((sum, d) => sum + calculateCost(d.powerKw ?? 0, 0.5), 0),
      action: "Review Devices",
    });
  }

  if (peaks.length > 5) {
    recs.push({
      id: "automation-1",
      type: "automation",
      priority: "high",
      title: "Enable Smart Automation",
      description: `${peaks.length} peak events detected. Automation can reduce peaks and cost.`,
      potentialSavings: calculateCost(2, 24 * 30),
      action: "Enable Auto-Balancing",
    });
  }

  const totalDailyCost = calculateCost(power, 24);
  if (totalDailyCost > 20) {
    recs.push({
      id: "cost-1",
      type: "cost",
      priority: "medium",
      title: "Projected Monthly Cost",
      description: `At this rate, projected monthly cost ≈ ${fmtCurrencyMad(totalDailyCost * 30)}.`,
      potentialSavings: totalDailyCost * 30 * 0.15,
      action: "View Report",
    });
  }

  return recs;
}

/* ======================
   MAIN COMPONENT
====================== */

export default function AdvancedDashboard() {
  const [health, setHealth] = useState<HealthPayload | null>(null);
  const [power, setPower] = useState<number>(0);
  const [devices, setDevices] = useState<Device[]>([]);
  const [peaks, setPeaks] = useState<PeakEvent[]>([]);
  const [optimizerLogs, setOptimizerLogs] = useState<string[]>([]);

  const [savings, setSavings] = useState<SavingsApi>({
    totalSavingsMad: 0,
    monthlySavingsMad: 0,
    dailySavingsMad: 0,
    totalPeaksPrevented: 0,
    totalAutomationActions: 0,
  });

  const [errors, setErrors] = useState<Record<string, string | null>>({
    usage: null,
    devices: null,
    peaks: null,
    optimizer: null,
    savings: null,
  });

  const [isLoading, setIsLoading] = useState(true);
  const [lastUpdate, setLastUpdate] = useState<Date | null>(null);
  const [search, setSearch] = useState("");
  const [showOnlyOn, setShowOnlyOn] = useState(false);
  const [viewMode, setViewMode] = useState<ViewMode>("overview");
  const [selectedRoom, setSelectedRoom] = useState<string>("all");
  const [timeRange, setTimeRange] = useState<"24h" | "7d" | "30d">("24h");

  const logsRef = useRef<HTMLDivElement | null>(null);

  useEffect(() => {
    let alive = true;

    async function tick() {
      const [h, u, d, p, o, s] = await Promise.all([
        safeJson<HealthPayload>("/api/health"),
        safeJson<UsageCurrent>("/api/usage/current"),
        safeJson<ApiDevice[]>("/api/devices"),
        safeJson<PeakEvent[]>("/api/peaks/recent?limit=30"),
        safeJson<string[]>("/api/optimizer/logs?limit=120"),
        safeJson<SavingsApi>("/api/billing/savings"),
      ]);

      if (!alive) return;

      if (h.ok && h.data) setHealth(h.data);

      let usageMap: Record<string, number> | undefined = undefined;

      if (u.ok && u.data) {
        setPower(Number(u.data.totalPowerKw ?? 0));
        usageMap = u.data.devices ?? undefined;
        setErrors((e) => ({ ...e, usage: null }));
      } else {
        setErrors((e) => ({ ...e, usage: u.error || "Usage API down" }));
      }

      if (d.ok && d.data) {
        setDevices(d.data.map((dev) => mapToUiDevice(dev, usageMap)));
        setErrors((e) => ({ ...e, devices: null }));
      } else {
        setDevices([]);
        setErrors((e) => ({ ...e, devices: d.error || "Devices API down" }));
      }

      if (p.ok && p.data) {
        setPeaks([...p.data].sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime()));
        setErrors((e) => ({ ...e, peaks: null }));
      } else {
        setPeaks([]);
        setErrors((e) => ({ ...e, peaks: p.error || "Peaks API down" }));
      }

      if (o.ok && o.data) {
        setOptimizerLogs(o.data);
        setErrors((e) => ({ ...e, optimizer: null }));
      } else {
        setOptimizerLogs([]);
        setErrors((e) => ({ ...e, optimizer: o.error || "Optimizer API down" }));
      }

      if (s.ok && s.data) {
        setSavings(s.data);
        setErrors((e) => ({ ...e, savings: null }));
      } else {
        setSavings({
          totalSavingsMad: 0,
          monthlySavingsMad: 0,
          dailySavingsMad: 0,
          totalPeaksPrevented: 0,
          totalAutomationActions: 0,
        });
        setErrors((e) => ({ ...e, savings: s.error || "Savings API down" }));
      }

      setIsLoading(false);
      setLastUpdate(new Date());
    }

    tick();
    const id = setInterval(tick, 2000);
    return () => {
      alive = false;
      clearInterval(id);
    };
  }, []);

  useEffect(() => {
    const el = logsRef.current;
    if (!el) return;
    el.scrollTop = 0;
  }, [optimizerLogs]);

  const historicalData = useMemo(() => generateHistoricalData(power), [power]);
  const recommendations = useMemo(() => generateRecommendations(power, devices, peaks), [power, devices, peaks]);

  const roomStats = useMemo(() => {
    const stats = new Map<string, { count: number; power: number; on: number }>();
    devices.forEach((d) => {
      const room = d.room || "Other";
      const cur = stats.get(room) || { count: 0, power: 0, on: 0 };
      stats.set(room, {
        count: cur.count + 1,
        power: cur.power + (d.isOn ? (d.powerKw || 0) : 0),
        on: cur.on + (d.isOn ? 1 : 0),
      });
    });
    return Array.from(stats.entries()).map(([room, data]) => ({ room, ...data }));
  }, [devices]);

  const deviceTypeStats = useMemo(() => {
    const stats = new Map<string, { count: number; power: number }>();
    devices.filter((d) => d.isOn).forEach((d) => {
      const type = d.type || "Unknown";
      const cur = stats.get(type) || { count: 0, power: 0 };
      stats.set(type, { count: cur.count + 1, power: cur.power + (d.powerKw || 0) });
    });
    return Array.from(stats.entries()).map(([name, data]) => ({ name, value: data.power, count: data.count }));
  }, [devices]);

  const filteredDevices = useMemo(() => {
    const q = search.trim().toLowerCase();
    return devices
        .filter((d) => (showOnlyOn ? d.isOn : true))
        .filter((d) => (selectedRoom === "all" ? true : d.room === selectedRoom))
        .filter((d) => {
          if (!q) return true;
          const hay = `${d.id} ${d.name} ${d.type ?? ""} ${d.room ?? ""}`.toLowerCase();
          return hay.includes(q);
        })
        .sort((a, b) => {
          if (a.isOn !== b.isOn) return a.isOn ? -1 : 1;
          return (b.powerKw ?? 0) - (a.powerKw ?? 0);
        });
  }, [devices, search, showOnlyOn, selectedRoom]);

  const peakStats = useMemo(() => {
    const critical = peaks.filter((p) => normalizeLevel(p.level) === "CRITICAL").length;
    const warning = peaks.filter((p) => normalizeLevel(p.level) === "WARNING").length;
    const last = peaks[0];
    return { critical, warning, last };
  }, [peaks]);

  const parsedCommands = useMemo(() => parseOptimizerCommands(optimizerLogs), [optimizerLogs]);

  const totalOn = devices.filter((d) => d.isOn).length;
  const totalOff = devices.length - totalOn;

  const currentCost = calculateCost(power, 1);
  const dailyCost = calculateCost(power, 24);
  const monthlyCost = dailyCost * 30;

  const hasAnyError = Object.values(errors).some((err) => err !== null);

  const gaugePercent = clamp((power / 10) * 100, 0, 100);

  // ✅ REAL savings from backend
  const realMonthlySavings = Number(savings.monthlySavingsMad ?? 0);

  return (
      <div className="min-h-screen w-full bg-gradient-to-b from-[#070A12] via-[#0B1020] to-[#070A12] text-white">
        <div className="mx-auto flex max-w-[1600px] gap-6 p-6">
          {/* Sidebar */}
          <aside className="hidden lg:flex w-[260px] flex-col gap-6 rounded-3xl bg-white/[0.04] p-6 border border-white/10 shadow-[0_20px_60px_-35px_rgba(0,0,0,0.8)]">
            <div className="flex items-center gap-3">
              <div className="h-12 w-12 rounded-2xl bg-gradient-to-br from-indigo-500 to-sky-500 flex items-center justify-center shadow-lg">
                <Home className="h-6 w-6 text-white" />
              </div>
              <div>
                <div className="font-bold text-white leading-tight">SmartHome</div>
                <div className="text-xs text-white/50">Load Balancer</div>
              </div>
            </div>

            <nav className="mt-2 flex flex-col gap-2">
              <NavButton icon={<LayoutGrid className="h-5 w-5" />} label="Overview" active={viewMode === "overview"} onClick={() => setViewMode("overview")} />
              <NavButton icon={<Zap className="h-5 w-5" />} label="Devices" active={viewMode === "devices"} onClick={() => setViewMode("devices")} badge={totalOn} />
              <NavButton icon={<BarChart3 className="h-5 w-5" />} label="Analytics" active={viewMode === "analytics"} onClick={() => setViewMode("analytics")} />
              <NavButton icon={<Sparkles className="h-5 w-5" />} label="Automation" active={viewMode === "automation"} onClick={() => setViewMode("automation")} />
              <NavButton icon={<DollarSign className="h-5 w-5" />} label="Savings" active={viewMode === "savings"} onClick={() => setViewMode("savings")} badge={recommendations.length} />
            </nav>

            <div className="mt-auto space-y-4">
              <ConnectionStatus hasErrors={hasAnyError} isLoading={isLoading} />

              <div className="rounded-2xl bg-white/[0.04] p-4 border border-white/10">
                <div className="text-xs text-white/60 mb-1">Real Monthly Savings</div>
                <div className="text-2xl font-black text-emerald-300">{fmtCurrencyMad(realMonthlySavings)}</div>
                <div className="text-xs text-white/50 mt-1">
                  Daily: {fmtCurrencyMad(Number(savings.dailySavingsMad || 0))} • Total: {fmtCurrencyMad(Number(savings.totalSavingsMad || 0))}
                </div>
              </div>

              {errors.savings && (
                  <div className="rounded-2xl bg-amber-500/10 border border-amber-500/30 p-3 text-xs text-amber-200">
                    Savings warning: {errors.savings}
                  </div>
              )}
            </div>
          </aside>

          {/* Main */}
          <main className="flex-1 space-y-6 min-w-0">
            {/* Topbar */}
            <div className="flex items-center gap-4">
              <div className="flex flex-1 items-center gap-3 rounded-2xl bg-white/[0.04] px-4 py-3 border border-white/10">
                <Search className="h-5 w-5 text-white/60" />
                <input
                    value={search}
                    onChange={(e) => setSearch(e.target.value)}
                    className="w-full bg-transparent text-sm text-white outline-none placeholder:text-white/40"
                    placeholder="Search devices, rooms, types..."
                />
              </div>

              <button className="rounded-2xl bg-white/[0.04] p-3 border border-white/10 hover:bg-white/[0.07] transition relative">
                <Bell className="h-5 w-5 text-white/70" />
                {recommendations.length > 0 && (
                    <span className="absolute -top-1 -right-1 h-5 w-5 rounded-full bg-rose-500 text-xs font-bold flex items-center justify-center">
                  {recommendations.length}
                </span>
                )}
              </button>

              <div className="flex items-center gap-3 rounded-2xl bg-white/[0.04] px-4 py-3 border border-white/10">
                <div className="h-9 w-9 rounded-full bg-gradient-to-br from-fuchsia-500 to-indigo-500" />
                <div className="leading-tight hidden md:block">
                  <div className="text-sm font-semibold text-white">Admin</div>
                  <div className="text-xs text-white/50">Smart Home</div>
                </div>
              </div>
            </div>

            {/* Loading */}
            {isLoading && (
                <div className="flex items-center justify-center py-20 rounded-3xl bg-white/[0.04] border border-white/10">
                  <div className="flex flex-col items-center gap-4">
                    <Loader2 className="h-8 w-8 text-sky-300 animate-spin" />
                    <span className="text-white/60">Initializing smart home system...</span>
                  </div>
                </div>
            )}

            {/* Alerts */}
            {!isLoading && hasAnyError && <SystemAlert errors={errors} />}

            {/* Views */}
            {!isLoading && (
                <>
                  {viewMode === "overview" && (
                      <OverviewView
                          power={power}
                          devices={devices}
                          peaks={peaks}
                          peakStats={peakStats}
                          totalOn={totalOn}
                          totalOff={totalOff}
                          currentCost={currentCost}
                          dailyCost={dailyCost}
                          monthlyCost={monthlyCost}
                          historicalData={historicalData}
                          recommendations={recommendations}
                          parsedCommands={parsedCommands}
                          optimizerLogs={optimizerLogs}
                          logsRef={logsRef}
                          roomStats={roomStats}
                          gaugePercent={gaugePercent}
                          lastUpdate={lastUpdate}
                      />
                  )}

                  {viewMode === "devices" && (
                      <DevicesView
                          devices={filteredDevices}
                          allDevices={devices}
                          showOnlyOn={showOnlyOn}
                          setShowOnlyOn={setShowOnlyOn}
                          selectedRoom={selectedRoom}
                          setSelectedRoom={setSelectedRoom}
                          roomStats={roomStats}
                          errors={errors}
                      />
                  )}

                  {viewMode === "analytics" && (
                      <AnalyticsView
                          power={power}
                          historicalData={historicalData}
                          deviceTypeStats={deviceTypeStats}
                          roomStats={roomStats}
                          peaks={peaks}
                          timeRange={timeRange}
                          setTimeRange={setTimeRange}
                          currentCost={currentCost}
                          dailyCost={dailyCost}
                          monthlyCost={monthlyCost}
                      />
                  )}

                  {viewMode === "automation" && (
                      <AutomationView
                          parsedCommands={parsedCommands}
                          optimizerLogs={optimizerLogs}
                          peaks={peaks}
                          errors={errors}
                          logsRef={logsRef}
                          savings={savings}
                      />
                  )}

                  {viewMode === "savings" && (
                      <SavingsView
                          recommendations={recommendations}
                          currentCost={currentCost}
                          dailyCost={dailyCost}
                          monthlyCost={monthlyCost}
                          savings={savings}
                      />
                  )}
                </>
            )}
          </main>
        </div>
      </div>
  );
}

/* ======================
   VIEWS
====================== */

function OverviewView({
                        power,
                        devices,
                        peaks,
                        peakStats,
                        totalOn,
                        totalOff,
                        currentCost,
                        dailyCost,
                        monthlyCost,
                        historicalData,
                        recommendations,
                        roomStats,
                        gaugePercent,
                        lastUpdate,
                      }: any) {
  const topDevices = devices
      .filter((d: Device) => d.isOn)
      .sort((a: Device, b: Device) => (b.powerKw ?? 0) - (a.powerKw ?? 0))
      .slice(0, 4);

  return (
      <div className="space-y-6">
        {/* Hero cards */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          <MetricCard
              icon={<Zap className="h-5 w-5" />}
              label="Current Power"
              value={power.toFixed(2)}
              unit="kW"
              trend={power > WARNING_THRESHOLD ? "up" : "down"}
              trendValue={`${((power / 10) * 100).toFixed(0)}% capacity`}
          />
          <MetricCard
              icon={<DollarSign className="h-5 w-5" />}
              label="Current Cost"
              value={fmtCurrencyMad(currentCost)}
              unit="/hour"
              trend="neutral"
              trendValue={`${fmtCurrencyMad(monthlyCost)}/month projected`}
          />
          <MetricCard
              icon={<Activity className="h-5 w-5" />}
              label="Active Devices"
              value={String(totalOn)}
              unit={`of ${devices.length}`}
              trend={totalOn > devices.length / 2 ? "up" : "down"}
              trendValue={`${totalOff} inactive`}
          />
          <MetricCard
              icon={<AlertTriangle className="h-5 w-5" />}
              label="Peak Events"
              value={String(peakStats.critical + peakStats.warning)}
              unit="today"
              trend={peakStats.critical > 0 ? "up" : "down"}
              trendValue={`${peakStats.critical} critical`}
          />
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Monitor */}
          <section className="lg:col-span-2 rounded-3xl bg-white/[0.04] border border-white/10 p-6">
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-xl font-bold text-white">Live Energy Monitor</h2>
              {lastUpdate && (
                  <div className="text-xs text-white/50 flex items-center gap-1.5">
                    <RefreshCw className="h-3 w-3" />
                    {lastUpdate.toLocaleTimeString()}
                  </div>
              )}
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div className="flex items-center justify-center">
                <PowerGauge power={power} percent={gaugePercent} />
              </div>
              <div className="space-y-3">
                <QuickStat label="Hourly Cost" value={fmtCurrencyMad(currentCost)} />
                <QuickStat label="Daily Est." value={fmtCurrencyMad(dailyCost)} />
                <QuickStat label="Monthly Est." value={fmtCurrencyMad(monthlyCost)} />
                <QuickStat label="Peak Today" value={peakStats.last ? fmtKw(peakStats.last.totalPowerKw) : "None"} />
              </div>
            </div>

            <div className="mt-6">
              <div className="text-sm font-semibold text-white/80 mb-3">24-Hour Power Trend</div>
              <div className="h-[180px]">
                <ResponsiveContainer width="100%" height="100%">
                  <AreaChart data={historicalData}>
                    <defs>
                      <linearGradient id="powerFill" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="0%" stopColor="rgba(99,102,241,0.55)" />
                        <stop offset="100%" stopColor="rgba(99,102,241,0.0)" />
                      </linearGradient>
                    </defs>
                    <XAxis
                        dataKey="timestamp"
                        tickFormatter={(ts) => new Date(ts).getHours() + "h"}
                        tick={{ fill: "rgba(255,255,255,0.45)", fontSize: 11 }}
                        axisLine={false}
                        tickLine={false}
                    />
                    <YAxis
                        tick={{ fill: "rgba(255,255,255,0.45)", fontSize: 11 }}
                        axisLine={false}
                        tickLine={false}
                    />
                    <Tooltip
                        contentStyle={{
                          background: "rgba(8,12,22,0.95)",
                          border: "1px solid rgba(255,255,255,0.10)",
                          borderRadius: 12,
                          color: "white",
                        }}
                        labelFormatter={(ts) => fmtTime(ts)}
                        formatter={(value: any) => [fmtKw(value), "Power"]}
                    />
                    <Area type="monotone" dataKey="power" stroke={CHART_COLORS.primary} fill="url(#powerFill)" strokeWidth={2} />
                  </AreaChart>
                </ResponsiveContainer>
              </div>
            </div>
          </section>

          {/* Top consumers */}
          <section className="rounded-3xl bg-white/[0.04] border border-white/10 p-6">
            <h2 className="text-xl font-bold text-white mb-4">Top Consumers</h2>
            <div className="space-y-3">
              {topDevices.map((device: Device, idx: number) => (
                  <TopDeviceCard key={device.id} device={device} rank={idx + 1} />
              ))}
              {topDevices.length === 0 && <div className="text-sm text-white/50 text-center py-8">No active devices</div>}
            </div>
          </section>
        </div>

        {/* Recommendations */}
        {recommendations.length > 0 && (
            <section className="rounded-3xl bg-white/[0.04] border border-white/10 p-6">
              <div className="flex items-center justify-between mb-4">
                <h2 className="text-xl font-bold text-white">Smart Recommendations</h2>
                <span className="text-xs text-white/50">{recommendations.length} suggestions</span>
              </div>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {recommendations.slice(0, 4).map((rec: Recommendation) => (
                    <RecommendationCard key={rec.id} recommendation={rec} />
                ))}
              </div>
            </section>
        )}

        {/* Rooms */}
        <section className="rounded-3xl bg-white/[0.04] border border-white/10 p-6">
          <h2 className="text-xl font-bold text-white mb-4">Power by Room</h2>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            {roomStats.map((room: any) => (
                <RoomStatCard key={room.room} room={room} />
            ))}
          </div>
        </section>
      </div>
  );
}

function DevicesView({ devices, allDevices, showOnlyOn, setShowOnlyOn, selectedRoom, setSelectedRoom, errors }: any) {
  const rooms = ["all", ...new Set(allDevices.map((d: Device) => d.room))];

  return (
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <h1 className="text-2xl font-bold text-white">Device Management</h1>
          <div className="flex items-center gap-3">
            <select
                value={selectedRoom}
                onChange={(e) => setSelectedRoom(e.target.value)}
                className="rounded-xl bg-white/[0.04] px-4 py-2 text-sm text-white border border-white/10 outline-none"
            >
              {rooms.map((room: any) => (
                  <option key={room} value={room} className="bg-slate-900">
                    {room === "all" ? "All Rooms" : room}
                  </option>
              ))}
            </select>

            <button
                onClick={() => setShowOnlyOn(!showOnlyOn)}
                className={`rounded-xl px-4 py-2 text-sm transition border ${
                    showOnlyOn
                        ? "bg-emerald-500/15 text-emerald-200 border-emerald-500/30"
                        : "bg-white/[0.04] text-white/70 border-white/10 hover:bg-white/[0.07]"
                }`}
            >
              {showOnlyOn ? "Active Only" : "All Devices"}
            </button>
          </div>
        </div>

        {errors.devices ? (
            <ErrorBox message={`Devices unreachable: ${errors.devices}`} />
        ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {devices.map((device: Device) => (
                  <DeviceCard key={device.id} device={device} />
              ))}
              {devices.length === 0 && <div className="col-span-full text-center py-12 text-white/50">No devices match your filters</div>}
            </div>
        )}
      </div>
  );
}

function AnalyticsView({ historicalData, deviceTypeStats, roomStats, peaks, timeRange, setTimeRange, currentCost, dailyCost, monthlyCost }: any) {
  return (
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <h1 className="text-2xl font-bold text-white">Analytics</h1>
          <div className="flex gap-2">
            {(["24h", "7d", "30d"] as const).map((range) => (
                <button
                    key={range}
                    onClick={() => setTimeRange(range)}
                    className={`px-4 py-2 rounded-xl text-sm transition border ${
                        timeRange === range
                            ? "bg-indigo-500/15 text-indigo-200 border-indigo-500/30"
                            : "bg-white/[0.04] text-white/70 border-white/10 hover:bg-white/[0.07]"
                    }`}
                >
                  {range === "24h" ? "24 Hours" : range === "7d" ? "7 Days" : "30 Days"}
                </button>
            ))}
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <CostCard label="Current Rate" amount={currentCost} period="/hour" icon={<Clock className="h-5 w-5" />} />
          <CostCard label="Daily Cost" amount={dailyCost} period="/day" icon={<Calendar className="h-5 w-5" />} />
          <CostCard label="Monthly Projection" amount={monthlyCost} period="/month" icon={<TrendingUp className="h-5 w-5" />} />
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <section className="rounded-3xl bg-white/[0.04] border border-white/10 p-6">
            <h3 className="text-lg font-bold text-white mb-4">Power Consumption</h3>
            <div className="h-[280px]">
              <ResponsiveContainer width="100%" height="100%">
                <LineChart data={historicalData}>
                  <XAxis
                      dataKey="timestamp"
                      tickFormatter={(ts) => new Date(ts).getHours() + "h"}
                      tick={{ fill: "rgba(255,255,255,0.45)", fontSize: 11 }}
                      axisLine={false}
                      tickLine={false}
                  />
                  <YAxis tick={{ fill: "rgba(255,255,255,0.45)", fontSize: 11 }} axisLine={false} tickLine={false} />
                  <Tooltip
                      contentStyle={{
                        background: "rgba(8,12,22,0.95)",
                        border: "1px solid rgba(255,255,255,0.10)",
                        borderRadius: 12,
                      }}
                  />
                  <Line type="monotone" dataKey="power" stroke={CHART_COLORS.primary} strokeWidth={3} dot={false} />
                </LineChart>
              </ResponsiveContainer>
            </div>
          </section>

          <section className="rounded-3xl bg-white/[0.04] border border-white/10 p-6">
            <h3 className="text-lg font-bold text-white mb-4">Power by Device Type</h3>
            <div className="h-[280px]">
              <ResponsiveContainer width="100%" height="100%">
                <RechartsPieChart>
                  <Pie
                      data={deviceTypeStats}
                      cx="50%"
                      cy="50%"
                      labelLine={false}
                      label={(entry: any) => `${entry.name}: ${entry.value.toFixed(2)}kW`}
                      outerRadius={80}
                      dataKey="value"
                  >
                    {deviceTypeStats.map((_: any, index: number) => (
                        <Cell key={`cell-${index}`} fill={DEVICE_COLORS[index % DEVICE_COLORS.length]} />
                    ))}
                  </Pie>
                  <Tooltip
                      contentStyle={{
                        background: "rgba(8,12,22,0.95)",
                        border: "1px solid rgba(255,255,255,0.10)",
                        borderRadius: 12,
                      }}
                  />
                </RechartsPieChart>
              </ResponsiveContainer>
            </div>
          </section>

          <section className="rounded-3xl bg-white/[0.04] border border-white/10 p-6">
            <h3 className="text-lg font-bold text-white mb-4">Power by Room</h3>
            <div className="h-[280px]">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={roomStats}>
                  <XAxis dataKey="room" tick={{ fill: "rgba(255,255,255,0.45)", fontSize: 11 }} axisLine={false} tickLine={false} />
                  <YAxis tick={{ fill: "rgba(255,255,255,0.45)", fontSize: 11 }} axisLine={false} tickLine={false} />
                  <Tooltip
                      contentStyle={{
                        background: "rgba(8,12,22,0.95)",
                        border: "1px solid rgba(255,255,255,0.10)",
                        borderRadius: 12,
                      }}
                  />
                  <Bar dataKey="power" fill={CHART_COLORS.secondary} radius={[8, 8, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>
            </div>
          </section>

          <section className="rounded-3xl bg-white/[0.04] border border-white/10 p-6">
            <h3 className="text-lg font-bold text-white mb-4">Peak Events</h3>
            <div className="space-y-3 max-h-[280px] overflow-auto">
              {peaks.slice(0, 6).map((peak: PeakEvent) => (
                  <PeakEventSimple key={peak.id} event={peak} />
              ))}
              {peaks.length === 0 && <div className="text-sm text-white/50 text-center py-8">No peak events</div>}
            </div>
          </section>
        </div>
      </div>
  );
}

function AutomationView({ parsedCommands, optimizerLogs, peaks, errors, logsRef, savings }: any) {
  const automationStats = useMemo(() => {
    const totalCommands = parsedCommands.length;
    const devicesTurnedOff = new Set(
        parsedCommands.filter((c: ParsedCmd) => c.action.toUpperCase().includes("OFF")).map((c: ParsedCmd) => c.deviceId)
    ).size;
    return { totalCommands, devicesTurnedOff };
  }, [parsedCommands]);

  return (
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-white">Automation</h1>
            <p className="text-sm text-white/60 mt-1">AI-powered optimization to prevent peaks and reduce costs</p>
          </div>
          <button className="px-6 py-3 rounded-xl bg-indigo-500/20 border border-indigo-500/30 text-indigo-100 font-semibold hover:bg-indigo-500/25 transition">
            Auto-Mode (Demo)
          </button>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <AutomationStatCard icon={<Sparkles className="h-6 w-6" />} label="Actions Taken" value={automationStats.totalCommands} description="Commands sent by optimizer" />
          <AutomationStatCard
              icon={<Target className="h-6 w-6" />}
              label="Peaks Prevented"
              value={Number(savings?.totalPeaksPrevented || 0)}
              description="From billing-service"
          />
          <AutomationStatCard
              icon={<DollarSign className="h-6 w-6" />}
              label="Savings"
              value={fmtCurrencyMad(Number(savings?.monthlySavingsMad || 0))}
              description="Real monthly savings"
          />
        </div>

        <section className="rounded-3xl bg-white/[0.04] border border-white/10 p-6">
          <h2 className="text-lg font-bold text-white mb-4">Recent Automation Actions</h2>
          {errors.optimizer ? (
              <ErrorBox message={`Optimizer unreachable: ${errors.optimizer}`} />
          ) : (
              <div className="space-y-2">
                {parsedCommands.slice(0, 10).map((cmd: ParsedCmd, idx: number) => (
                    <CommandLogItem key={idx} command={cmd} />
                ))}
                {parsedCommands.length === 0 && <div className="text-sm text-white/50 text-center py-8">No automation actions yet</div>}
              </div>
          )}
        </section>

        <section className="rounded-3xl bg-white/[0.04] border border-white/10 p-6">
          <h2 className="text-lg font-bold text-white mb-4">System Logs</h2>
          <div ref={logsRef} className="max-h-[400px] overflow-auto rounded-xl bg-black/40 p-4 font-mono text-xs space-y-1 border border-white/10">
            {optimizerLogs.map((line: string, idx: number) => (
                <LogLine key={idx} line={line} />
            ))}
            {optimizerLogs.length === 0 && <div className="text-white/50 text-center py-4">No logs available</div>}
          </div>
        </section>
      </div>
  );
}

function SavingsView({ recommendations, currentCost, dailyCost, monthlyCost, savings }: { recommendations: Recommendation[]; currentCost: number; dailyCost: number; monthlyCost: number; savings: SavingsApi }) {
  const baseMonthly = Number(savings?.monthlySavingsMad || 0);

  const breakdown = useMemo(() => {
    return {
      automation: baseMonthly * 0.45,
      peakAvoidance: baseMonthly * 0.35,
      scheduling: baseMonthly * 0.20,
    };
  }, [baseMonthly]);

  return (
      <div className="space-y-6">
        <div>
          <h1 className="text-2xl font-bold text-white">Savings</h1>
          <p className="text-sm text-white/60 mt-1">Real savings computed by billing-service + improvement suggestions</p>
        </div>

        {/* Real Savings Overview */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          <div className="md:col-span-2 rounded-3xl bg-white/[0.04] border border-white/10 p-7">
            <div className="flex items-center gap-3 mb-3">
              <div className="h-12 w-12 rounded-2xl bg-emerald-500/15 border border-emerald-500/25 flex items-center justify-center">
                <DollarSign className="h-6 w-6 text-emerald-300" />
              </div>
              <div>
                <div className="text-xs text-white/60">Real Monthly Savings</div>
                <div className="text-4xl font-black text-emerald-300">{fmtCurrencyMad(baseMonthly)}</div>
              </div>
            </div>

            <div className="grid grid-cols-2 gap-3 mt-4">
              <MiniStat label="Daily Savings" value={fmtCurrencyMad(Number(savings?.dailySavingsMad || 0))} />
              <MiniStat label="Total Savings" value={fmtCurrencyMad(Number(savings?.totalSavingsMad || 0))} />
              <MiniStat label="Peaks Prevented" value={String(Number(savings?.totalPeaksPrevented || 0))} />
              <MiniStat label="Automation Actions" value={String(Number(savings?.totalAutomationActions || 0))} />
            </div>

            <div className="mt-4 text-xs text-white/50">
              Suggestions shown below are “potential improvements”. Your real savings numbers come from the backend.
            </div>
          </div>

          <SavingsCategoryCard label="Automation (est.)" amount={breakdown.automation} icon={<Sparkles className="h-5 w-5" />} />
          <SavingsCategoryCard label="Peak Avoidance (est.)" amount={breakdown.peakAvoidance} icon={<Flame className="h-5 w-5" />} />
        </div>

        {/* Recommendations */}
        <section className="rounded-3xl bg-white/[0.04] border border-white/10 p-6">
          <h2 className="text-lg font-bold text-white mb-4">Recommendations</h2>
          <div className="space-y-4">
            {recommendations.map((rec) => (
                <RecommendationCardDetailed key={rec.id} recommendation={rec} />
            ))}
            {recommendations.length === 0 && (
                <div className="text-center py-12">
                  <CheckCircle2 className="h-12 w-12 text-emerald-300 mx-auto mb-3" />
                  <div className="text-lg font-semibold text-white">All Optimized</div>
                  <div className="text-sm text-white/60 mt-1">No new optimization suggestions right now</div>
                </div>
            )}
          </div>
        </section>

        {/* Cost Breakdown */}
        <section className="rounded-3xl bg-white/[0.04] border border-white/10 p-6">
          <h2 className="text-lg font-bold text-white mb-4">Cost Breakdown</h2>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <CostBreakdownItem label="Current Rate" value={currentCost} unit="/hour" icon={<Clock className="h-5 w-5" />} />
            <CostBreakdownItem label="Daily Projection" value={dailyCost} unit="/day" icon={<Calendar className="h-5 w-5" />} />
            <CostBreakdownItem label="Monthly Projection" value={monthlyCost} unit="/month" icon={<TrendingUp className="h-5 w-5" />} highlight />
          </div>
        </section>
      </div>
  );
}

/* ======================
   UI COMPONENTS
====================== */

function NavButton({ icon, label, active, onClick, badge }: any) {
  return (
      <button
          onClick={onClick}
          className={`flex items-center gap-3 px-4 py-3 rounded-xl transition border ${
              active ? "bg-white/[0.06] text-white border-white/15" : "text-white/70 hover:bg-white/[0.05] hover:text-white border-transparent"
          }`}
      >
        {icon}
        <span className="text-sm font-medium">{label}</span>
        {badge !== undefined && badge > 0 && (
            <span className="ml-auto h-5 min-w-[20px] px-1 rounded-full bg-indigo-500 text-xs font-bold flex items-center justify-center">
          {badge}
        </span>
        )}
      </button>
  );
}

function ConnectionStatus({ hasErrors, isLoading }: { hasErrors: boolean; isLoading: boolean }) {
  return (
      <div className="rounded-2xl bg-white/[0.04] p-4 border border-white/10">
        <div className="text-xs text-white/50 mb-2">System Status</div>
        <div className="flex items-center gap-2">
          <div className={`h-2.5 w-2.5 rounded-full ${isLoading ? "bg-yellow-400 animate-pulse" : hasErrors ? "bg-rose-400 animate-pulse" : "bg-emerald-400"}`} />
          <span className="text-sm font-semibold text-white">{isLoading ? "Connecting..." : hasErrors ? "Partial" : "All Systems OK"}</span>
        </div>
      </div>
  );
}

function SystemAlert({ errors }: { errors: Record<string, string | null> }) {
  const criticalErrors = Object.entries(errors).filter(([_, err]) => err !== null);
  if (criticalErrors.length === 0) return null;

  return (
      <div className="rounded-2xl bg-rose-500/10 border border-rose-500/30 p-5">
        <div className="flex items-center gap-3 mb-3">
          <AlertTriangle className="h-6 w-6 text-rose-300" />
          <h3 className="text-lg font-bold text-white">System Issues Detected</h3>
        </div>
        <div className="space-y-2">
          {criticalErrors.map(([service, error]) => (
              <div key={service} className="flex items-start gap-2 text-sm rounded-lg bg-black/20 p-3 border border-white/10">
                <XCircle className="h-4 w-4 text-rose-300 mt-0.5 flex-shrink-0" />
                <div>
                  <span className="text-rose-200 font-semibold capitalize">{service}</span>
                  <span className="text-white/80">: {error}</span>
                </div>
              </div>
          ))}
        </div>
      </div>
  );
}

function MetricCard({ icon, label, value, unit, trend, trendValue }: any) {
  return (
      <div className="rounded-3xl bg-white/[0.04] border border-white/10 p-6">
        <div className="flex items-center justify-between mb-3">
          <div className="h-10 w-10 rounded-xl bg-white/[0.06] border border-white/10 flex items-center justify-center text-white">{icon}</div>
          {trend === "up" && <TrendingUp className="h-5 w-5 text-rose-300" />}
          {trend === "down" && <TrendingDown className="h-5 w-5 text-emerald-300" />}
        </div>
        <div className="text-sm text-white/70 mb-1">{label}</div>
        <div className="flex items-baseline gap-2">
          <div className="text-3xl font-black text-white">{value}</div>
          <div className="text-sm text-white/60">{unit}</div>
        </div>
        <div className="mt-2 text-xs text-white/50">{trendValue}</div>
      </div>
  );
}

function PowerGauge({ power, percent }: { power: number; percent: number }) {
  return (
      <div className="relative h-[200px] w-[200px]">
        <div className="absolute inset-0 rounded-full bg-[radial-gradient(circle_at_30%_20%,rgba(99,102,241,0.25),transparent_60%)]" />
        <div className="absolute inset-3 rounded-full bg-[#0B1020] shadow-inner border border-white/10" />
        <div className="absolute inset-0 flex items-center justify-center">
          <div className="text-center">
            <div className="text-5xl font-black text-white">{power.toFixed(2)}</div>
            <div className="text-sm text-white/60">kW</div>
          </div>
        </div>
        <svg className="absolute inset-0" viewBox="0 0 100 100">
          <circle cx="50" cy="50" r="44" fill="none" stroke="rgba(255,255,255,0.10)" strokeWidth="5" />
          <circle
              cx="50"
              cy="50"
              r="44"
              fill="none"
              stroke="rgba(99,102,241,0.95)"
              strokeWidth="5"
              strokeLinecap="round"
              strokeDasharray={`${(percent / 100) * 276} 276`}
              transform="rotate(-90 50 50)"
          />
        </svg>
      </div>
  );
}

function QuickStat({ label, value }: { label: string; value: string }) {
  return (
      <div className="rounded-xl bg-white/[0.04] p-3 border border-white/10">
        <div className="text-xs text-white/50">{label}</div>
        <div className="text-lg font-bold text-white mt-1">{value}</div>
      </div>
  );
}

function TopDeviceCard({ device, rank }: { device: Device; rank: number }) {
  return (
      <div className="rounded-2xl bg-white/[0.04] border border-white/10 p-4 flex items-center gap-3 hover:bg-white/[0.06] transition">
        <div className="h-8 w-8 rounded-lg bg-indigo-500/25 border border-indigo-500/30 flex items-center justify-center text-indigo-100 font-bold text-sm">
          {rank}
        </div>
        <div className="flex-1 min-w-0">
          <div className="text-sm font-semibold text-white truncate">{device.name}</div>
          <div className="text-xs text-white/60">{device.room}</div>
        </div>
        <div className="text-right">
          <div className="text-sm font-bold text-white">{fmtKw(device.powerKw)}</div>
          <div className="text-xs text-emerald-300">{fmtCurrencyMad(calculateCost(device.powerKw || 0, 1))}/h</div>
        </div>
      </div>
  );
}

function RecommendationCard({ recommendation }: { recommendation: Recommendation }) {
  const priorityChip =
      recommendation.priority === "high"
          ? "bg-rose-500/15 border-rose-500/30 text-rose-200"
          : recommendation.priority === "medium"
              ? "bg-amber-500/15 border-amber-500/30 text-amber-200"
              : "bg-sky-500/15 border-sky-500/30 text-sky-200";

  const Icon =
      recommendation.type === "cost"
          ? DollarSign
          : recommendation.type === "efficiency"
              ? Zap
              : recommendation.type === "peak"
                  ? Flame
                  : Sparkles;

  return (
      <div className="rounded-2xl bg-white/[0.04] p-5 border border-white/10 hover:bg-white/[0.06] transition">
        <div className="flex items-start gap-3">
          <div className="h-10 w-10 rounded-xl bg-white/[0.06] border border-white/10 flex items-center justify-center flex-shrink-0">
            <Icon className="h-5 w-5 text-white" />
          </div>
          <div className="flex-1 min-w-0">
            <div className={`inline-flex items-center px-2 py-0.5 text-[10px] font-bold uppercase rounded border ${priorityChip}`}>
              {recommendation.priority}
            </div>
            <div className="text-sm font-semibold text-white mt-2 mb-1">{recommendation.title}</div>
            <div className="text-xs text-white/60">{recommendation.description}</div>
            {recommendation.potentialSavings !== undefined && (
                <div className="mt-2 text-xs text-emerald-300 font-semibold">
                  Potential: {fmtCurrencyMad(recommendation.potentialSavings)}/month
                </div>
            )}
          </div>
        </div>
      </div>
  );
}

function RecommendationCardDetailed({ recommendation }: { recommendation: Recommendation }) {
  const priorityStyles =
      recommendation.priority === "high"
          ? "border-rose-500/30 bg-rose-500/10"
          : recommendation.priority === "medium"
              ? "border-amber-500/30 bg-amber-500/10"
              : "border-sky-500/30 bg-sky-500/10";

  return (
      <div className={`rounded-2xl p-6 border ${priorityStyles}`}>
        <div className="flex items-start justify-between gap-4">
          <div className="flex-1">
            <div className="flex items-center gap-2 mb-2">
            <span className="text-[10px] font-bold uppercase px-2 py-1 rounded bg-black/20 border border-white/10 text-white/80">
              {recommendation.priority}
            </span>
            </div>
            <h3 className="text-lg font-bold text-white mb-2">{recommendation.title}</h3>
            <p className="text-sm text-white/70 mb-3">{recommendation.description}</p>
            {recommendation.potentialSavings !== undefined && (
                <div className="flex items-center gap-2">
                  <DollarSign className="h-4 w-4 text-emerald-300" />
                  <span className="text-emerald-200 font-semibold">
                Potential: {fmtCurrencyMad(recommendation.potentialSavings)}/month
              </span>
                </div>
            )}
          </div>
          {recommendation.action && (
              <button className="px-4 py-2 rounded-xl bg-white/[0.06] border border-white/10 hover:bg-white/[0.08] text-white text-sm font-semibold transition whitespace-nowrap">
                {recommendation.action}
              </button>
          )}
        </div>
      </div>
  );
}

function RoomStatCard({ room }: any) {
  return (
      <div className="rounded-2xl bg-white/[0.04] border border-white/10 p-4 hover:bg-white/[0.06] transition">
        <div className="flex items-center justify-between mb-2">
          <div className="text-sm font-semibold text-white">{room.room}</div>
          <Home className="h-4 w-4 text-white/40" />
        </div>
        <div className="text-2xl font-black text-white mb-1">{fmtKw(room.power)}</div>
        <div className="text-xs text-white/60">{room.on} of {room.count} active</div>
      </div>
  );
}

function DeviceCard({ device }: { device: Device }) {
  const icons: Record<string, any> = {
    LIGHTING: Lightbulb,
    APPLIANCE: Refrigerator,
    ENTERTAINMENT: Tv,
    HVAC: Wind,
    NETWORKING: Wifi,
    MISC: Zap,
  };

  const Icon = icons[device.type || ""] || Zap;

  return (
      <div className="rounded-2xl bg-white/[0.04] p-5 border border-white/10 hover:bg-white/[0.06] hover:border-white/15 transition">
        <div className="flex items-center justify-between mb-4">
          <div className="h-12 w-12 rounded-xl bg-white/[0.06] border border-white/10 flex items-center justify-center">
            <Icon className="h-6 w-6 text-white" />
          </div>
          <div className={`h-3 w-3 rounded-full ${device.isOn ? "bg-emerald-400" : "bg-white/20"}`} />
        </div>
        <div className="text-sm font-semibold text-white mb-1">{device.name}</div>
        <div className="text-xs text-white/60 mb-3">
          {device.room} • {device.type}
        </div>
        <div className="flex items-center justify-between">
          <span className="text-xs text-white/50">Power</span>
          <span className="text-sm font-bold text-white">{fmtKw(device.powerKw)}</span>
        </div>
        <div className="flex items-center justify-between mt-1">
          <span className="text-xs text-white/50">Status</span>
          <span className={`text-sm font-semibold ${device.isOn ? "text-emerald-300" : "text-white/60"}`}>
          {device.isOn ? "ON" : "OFF"}
        </span>
        </div>
      </div>
  );
}

function ErrorBox({ message }: { message: string }) {
  return (
      <div className="rounded-2xl bg-rose-500/10 border border-rose-500/30 p-4">
        <div className="flex items-start gap-3">
          <XCircle className="h-5 w-5 text-rose-300 mt-0.5 flex-shrink-0" />
          <div className="text-rose-200 text-sm">{message}</div>
        </div>
      </div>
  );
}

function CostCard({ label, amount, period, icon }: any) {
  return (
      <div className="rounded-2xl bg-white/[0.04] border border-white/10 p-5">
        <div className="flex items-center gap-2 mb-3">
          <div className="h-8 w-8 rounded-lg bg-white/[0.06] border border-white/10 flex items-center justify-center text-white">{icon}</div>
        </div>
        <div className="text-xs text-white/60 mb-1">{label}</div>
        <div className="text-2xl font-black text-white">
          {fmtCurrencyMad(amount)}
          <span className="text-sm text-white/60 font-normal ml-1">{period}</span>
        </div>
      </div>
  );
}

function PeakEventSimple({ event }: { event: PeakEvent }) {
  const lvl = normalizeLevel(event.level);
  const isCritical = lvl === "CRITICAL";

  return (
      <div className={`rounded-xl p-3 border ${isCritical ? "bg-rose-500/10 border-rose-500/30" : "bg-amber-500/10 border-amber-500/30"}`}>
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            {isCritical ? <Flame className="h-4 w-4 text-rose-300" /> : <AlertTriangle className="h-4 w-4 text-amber-300" />}
            <span className={`text-xs font-semibold ${isCritical ? "text-rose-200" : "text-amber-200"}`}>{lvl}</span>
          </div>
          <span className="text-xs text-white/60">{fmtTime(event.timestamp)}</span>
        </div>
        <div className="mt-1 text-xs text-white/70">{fmtKw(event.totalPowerKw)} peak</div>
      </div>
  );
}

function AutomationStatCard({ icon, label, value, description }: any) {
  return (
      <div className="rounded-2xl bg-white/[0.04] border border-white/10 p-6">
        <div className="h-12 w-12 rounded-xl bg-white/[0.06] border border-white/10 flex items-center justify-center text-white mb-4">{icon}</div>
        <div className="text-3xl font-black text-white mb-1">{value}</div>
        <div className="text-sm font-semibold text-white mb-1">{label}</div>
        <div className="text-xs text-white/60">{description}</div>
      </div>
  );
}

function CommandLogItem({ command }: { command: ParsedCmd }) {
  const isOff = command.action.toUpperCase().includes("OFF");
  return (
      <div className="rounded-xl bg-white/[0.04] border border-white/10 p-3 flex items-center justify-between hover:bg-white/[0.06] transition">
        <div className="flex items-center gap-3">
          <div className={`h-8 w-8 rounded-lg border flex items-center justify-center ${isOff ? "bg-rose-500/15 border-rose-500/25" : "bg-emerald-500/15 border-emerald-500/25"}`}>
            <Power className={`h-4 w-4 ${isOff ? "text-rose-300" : "text-emerald-300"}`} />
          </div>
          <div>
            <div className="text-sm font-semibold text-white">{command.deviceId}</div>
            <div className={`text-xs ${isOff ? "text-rose-200" : "text-emerald-200"}`}>{command.action}</div>
          </div>
        </div>
        {command.ts && <div className="text-xs text-white/50">{fmtTime(command.ts)}</div>}
      </div>
  );
}

function LogLine({ line }: { line: string }) {
  const className = line.includes("CRITICAL")
      ? "text-rose-300"
      : line.includes("WARNING")
          ? "text-amber-200"
          : line.includes("📤")
              ? "text-sky-200"
              : line.includes("✅")
                  ? "text-emerald-200"
                  : "text-white/75";
  return <div className={`whitespace-pre-wrap ${className}`}>{line}</div>;
}

function SavingsCategoryCard({ label, amount, icon }: any) {
  return (
      <div className="rounded-3xl bg-white/[0.04] border border-white/10 p-6">
        <div className="h-10 w-10 rounded-xl bg-white/[0.06] border border-white/10 flex items-center justify-center text-white mb-3">{icon}</div>
        <div className="text-sm text-white/70 mb-1">{label}</div>
        <div className="text-2xl font-black text-white">{fmtCurrencyMad(amount)}</div>
      </div>
  );
}

function CostBreakdownItem({ label, value, unit, icon, highlight }: any) {
  return (
      <div className={`rounded-2xl p-5 border ${highlight ? "bg-indigo-500/10 border-indigo-500/30" : "bg-white/[0.04] border-white/10"}`}>
        <div className="flex items-center gap-2 mb-3">
          <div className={`h-8 w-8 rounded-lg border flex items-center justify-center text-white ${highlight ? "bg-indigo-500/15 border-indigo-500/25" : "bg-white/[0.06] border-white/10"}`}>
            {icon}
          </div>
        </div>
        <div className="text-xs text-white/60 mb-1">{label}</div>
        <div className={`text-2xl font-black ${highlight ? "text-indigo-200" : "text-white"}`}>
          {fmtCurrencyMad(value)}
          <span className="text-sm text-white/60 font-normal ml-1">{unit}</span>
        </div>
      </div>
  );
}

function MiniStat({ label, value }: { label: string; value: string }) {
  return (
      <div className="rounded-xl bg-black/20 border border-white/10 p-3">
        <div className="text-[11px] text-white/60">{label}</div>
        <div className="text-sm font-semibold text-white mt-1">{value}</div>
      </div>
  );
}
