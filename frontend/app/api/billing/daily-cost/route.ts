import { NextResponse } from "next/server";

export const dynamic = "force-dynamic";

export async function GET() {
    try {
        const base = process.env.BILLING_BASE_URL ?? "http://localhost:8086";

        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), 5000);

        const upstream = await fetch(`${base}/billing/daily-cost`, {
            cache: "no-store",
            signal: controller.signal
        });

        clearTimeout(timeoutId);

        if (!upstream.ok) {
            return NextResponse.json(
                {
                    todayCostMad: 0,
                    todayKwh: 0,
                    projectedDailyCostMad: 0
                },
                { status: 200 }
            );
        }

        const data = await upstream.json();
        return NextResponse.json(data);
    } catch (error: any) {
        return NextResponse.json(
            {
                todayCostMad: 0,
                todayKwh: 0,
                projectedDailyCostMad: 0
            },
            { status: 200 }
        );
    }
}
