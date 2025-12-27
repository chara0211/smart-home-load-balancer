// Utilitaires pour l'authentification
import { cookies } from 'next/headers';

// Récupérer le token depuis les cookies (server-side)
export async function getAuthToken(): Promise<string | null> {
    const cookieStore = await cookies();
    const token = cookieStore.get('auth_token')?.value;
    return token || null;
}

// Récupérer le token depuis les headers de la requête
export function getAuthTokenFromRequest(req: Request): string | null {
    const authHeader = req.headers.get('authorization');
    if (authHeader && authHeader.startsWith('Bearer ')) {
        return authHeader.substring(7);
    }
    return null;
}

// Créer les headers avec authentification
export function createAuthHeaders(token: string | null): HeadersInit {
    const headers: HeadersInit = {
        'Content-Type': 'application/json',
    };
    
    if (token) {
        headers['Authorization'] = `Bearer ${token}`;
    }
    
    return headers;
}

