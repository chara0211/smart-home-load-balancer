// Route API pour l'authentification Keycloak
import { NextResponse } from "next/server";

export const dynamic = "force-dynamic";

export async function GET(req: Request) {
    try {
        const { searchParams } = new URL(req.url);
        const username = searchParams.get("username");
        const password = searchParams.get("password");

        if (!username || !password) {
            return NextResponse.json(
                { error: "Username and password are required" },
                { status: 400 }
            );
        }

        const keycloakUrl = process.env.KEYCLOAK_URL || "http://keycloak-service:8080";
        const realm = process.env.KEYCLOAK_REALM || "smarthome";
        const clientId = process.env.KEYCLOAK_CLIENT_ID || "frontend-client";
        const clientSecret = process.env.KEYCLOAK_CLIENT_SECRET || "";

        // Obtenir le token depuis Keycloak
        const tokenUrl = `${keycloakUrl}/realms/${realm}/protocol/openid-connect/token`;
        
        const formData = new URLSearchParams();
        formData.append("grant_type", "password");
        formData.append("client_id", clientId);
        if (clientSecret) {
            formData.append("client_secret", clientSecret);
        }
        formData.append("username", username);
        formData.append("password", password);

        const response = await fetch(tokenUrl, {
            method: "POST",
            headers: {
                "Content-Type": "application/x-www-form-urlencoded",
            },
            body: formData,
        });

        if (!response.ok) {
            const error = await response.text();
            return NextResponse.json(
                { error: "Authentication failed", detail: error },
                { status: response.status }
            );
        }

        const data = await response.json();
        
        return NextResponse.json({
            access_token: data.access_token,
            refresh_token: data.refresh_token,
            expires_in: data.expires_in,
        });
    } catch (error: any) {
        console.error("Keycloak authentication error:", error);
        return NextResponse.json(
            { error: "Authentication service unreachable", detail: error.message },
            { status: 503 }
        );
    }
}

