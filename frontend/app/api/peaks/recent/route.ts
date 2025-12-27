// app/api/peaks/recent/route.ts
import { NextResponse } from "next/server";
import { getAuthTokenFromRequest, createAuthHeaders } from "@/lib/auth";

export const dynamic = "force-dynamic";

export async function GET(req: Request) {
    try {
        const { searchParams } = new URL(req.url);
        const limit = searchParams.get("limit") ?? "20";

        const base = process.env.PEAK_BASE_URL ?? "http://localhost:8084";
        
        // Récupérer le token d'authentification
        const token = getAuthTokenFromRequest(req);

        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), 5000);

        const upstream = await fetch(`${base}/peaks/recent?limit=${limit}`, {
            cache: "no-store",
            signal: controller.signal,
            headers: createAuthHeaders(token)
        });

        clearTimeout(timeoutId);
        const body = await upstream.text();

        return new NextResponse(body, {
            status: upstream.status,
            headers: { "content-type": upstream.headers.get("content-type") ?? "application/json" },
        });
    } catch (error: any) {
        console.error("Peaks API error:", error);
        return NextResponse.json(
            { error: "Peak service unreachable", detail: error.message },
            { status: 503 }
        );
    }
}