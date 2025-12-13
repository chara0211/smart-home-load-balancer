// app/api/devices/route.ts
import { NextResponse } from "next/server";

export const dynamic = "force-dynamic";

export async function GET() {
    try {
        const base = process.env.DEVICE_BASE_URL ?? "http://localhost:8082";

        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), 5000); // 5s timeout

        const upstream = await fetch(`${base}/devices`, {
            cache: "no-store",
            signal: controller.signal
        });

        clearTimeout(timeoutId);
        const body = await upstream.text();

        return new NextResponse(body, {
            status: upstream.status,
            headers: {
                "content-type": upstream.headers.get("content-type") ?? "application/json",
            },
        });
    } catch (error: any) {
        console.error("Devices API error:", error);
        return NextResponse.json(
            { error: "Device service unreachable", detail: error.message },
            { status: 503 }
        );
    }
}