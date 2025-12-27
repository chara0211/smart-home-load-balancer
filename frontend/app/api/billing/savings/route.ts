import { NextResponse } from "next/server";
import { getAuthTokenFromRequest, createAuthHeaders } from "@/lib/auth";

export const dynamic = "force-dynamic";

export async function GET(req: Request) {
    try {
        const base = process.env.BILLING_BASE_URL ?? "http://localhost:8086";
        
        // Récupérer le token d'authentification
        const token = getAuthTokenFromRequest(req);

        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), 5000);

        const upstream = await fetch(`${base}/billing/savings`, {
            cache: "no-store",
            signal: controller.signal,
            headers: createAuthHeaders(token)
        });

        clearTimeout(timeoutId);

        if (!upstream.ok) {
            console.error(`Billing service returned ${upstream.status}`);
            return NextResponse.json(
                {
                    totalSavingsMad: 0,
                    monthlySavingsMad: 0,
                    dailySavingsMad: 0,
                    totalPeaksPrevented: 0,
                    totalAutomationActions: 0
                },
                { status: 200 }
            );
        }

        const data = await upstream.json();
        return NextResponse.json(data);
    } catch (error: any) {
        console.error("Billing savings API error:", error);
        return NextResponse.json(
            {
                totalSavingsMad: 0,
                monthlySavingsMad: 0,
                dailySavingsMad: 0,
                totalPeaksPrevented: 0,
                totalAutomationActions: 0
            },
            { status: 200 }
        );
    }
}
