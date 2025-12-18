// app/api/optimizer/logs/route.ts
import { NextResponse } from "next/server";

export const dynamic = "force-dynamic";

export async function GET(req: Request) {
    try {
        const { searchParams } = new URL(req.url);
        const limit = searchParams.get("limit") ?? "50";

        const base = process.env.OPTIMIZER_BASE_URL ?? "http://localhost:8085";

        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), 5000);

        const upstream = await fetch(`${base}/optimizer/logs?limit=${limit}`, {
            cache: "no-store",
            signal: controller.signal
        });

        clearTimeout(timeoutId);
        const body = await upstream.text();

        return new NextResponse(body, {
            status: upstream.status,
            headers: { "content-type": upstream.headers.get("content-type") ?? "application/json" },
        });
    } catch (error: any) {
        console.error("Optimizer API error:", error);
        return NextResponse.json(
            { error: "Optimizer service unreachable", detail: error.message },
            { status: 503 }
        );
    }
}