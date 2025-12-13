import { NextResponse } from "next/server";

type Health = { ok: boolean; status: "UP" | "DOWN"; detail?: string };

async function check(url: string): Promise<Health> {
    try {
        const res = await fetch(url, { cache: "no-store" });
        if (!res.ok) return { ok: false, status: "DOWN", detail: `HTTP ${res.status}` };
        const data = await res.json().catch(() => ({}));

        // Spring Actuator health often: { status: "UP" }
        const status = (data?.status as string) || "UP";
        const ok = status.toUpperCase() === "UP";
        return { ok, status: ok ? "UP" : "DOWN" };
    } catch (e: any) {
        return { ok: false, status: "DOWN", detail: e?.message || "unreachable" };
    }
}

export async function GET() {
    const usage = process.env.USAGE_BASE_URL!;
    const device = process.env.DEVICE_BASE_URL!;
    const peak = process.env.PEAK_BASE_URL!;
    const opt = process.env.OPTIMIZER_BASE_URL!;

    const [usageH, deviceH, peakH, optH] = await Promise.all([
        check(`${usage}/actuator/health`),
        check(`${device}/actuator/health`),
        check(`${peak}/actuator/health`),
        check(`${opt}/actuator/health`),
    ]);

    const partial = [usageH, deviceH, peakH, optH].some((x) => !x.ok);

    return NextResponse.json({
        partial,
        services: {
            usage: usageH,
            devices: deviceH,
            peaks: peakH,
            optimizer: optH,
        },
    });
}
