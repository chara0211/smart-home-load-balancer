// app/api/usage/current/route.ts
import { NextResponse } from "next/server";
import { getAuthTokenFromRequest, createAuthHeaders } from "@/lib/auth";

export const dynamic = "force-dynamic";

export async function GET(req: Request) {
    try {
        const base = process.env.USAGE_BASE_URL ?? "http://localhost:8083";
        
        // Récupérer le token d'authentification
        const token = getAuthTokenFromRequest(req);

        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), 5000);

        const upstream = await fetch(`${base}/usage/current`, {
            cache: "no-store",
            signal: controller.signal,
            headers: createAuthHeaders(token)
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
        console.error("Usage API error:", error);
        return NextResponse.json(
            { error: "Usage service unreachable", detail: error.message },
            { status: 503 }
        );
    }
}