// Route API pour récupérer le token depuis le client
import { NextResponse } from "next/server";
import { cookies } from "next/headers";

export const dynamic = "force-dynamic";

export async function GET() {
    try {
        const cookieStore = await cookies();
        const token = cookieStore.get('auth_token')?.value;
        
        if (!token) {
            return NextResponse.json(
                { error: "No token found" },
                { status: 401 }
            );
        }
        
        return NextResponse.json({ token });
    } catch (error: any) {
        return NextResponse.json(
            { error: "Failed to get token", detail: error.message },
            { status: 500 }
        );
    }
}

