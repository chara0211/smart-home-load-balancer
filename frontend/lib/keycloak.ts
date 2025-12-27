// Configuration Keycloak pour le frontend
export const keycloakConfig = {
    url: process.env.NEXT_PUBLIC_KEYCLOAK_URL || 'http://keycloak-service:8080',
    realm: process.env.NEXT_PUBLIC_KEYCLOAK_REALM || 'smarthome',
    clientId: process.env.NEXT_PUBLIC_KEYCLOAK_CLIENT_ID || 'frontend-client',
};

// Fonction pour obtenir le token depuis les cookies ou le localStorage
export function getAuthToken(): string | null {
    if (typeof window === 'undefined') {
        // Server-side: pas de token disponible
        return null;
    }
    
    // Essayer de récupérer le token depuis localStorage
    const token = localStorage.getItem('keycloak_token');
    if (token) {
        // Vérifier si le token est expiré
        try {
            const payload = JSON.parse(atob(token.split('.')[1]));
            const exp = payload.exp * 1000; // Convertir en millisecondes
            if (Date.now() < exp) {
                return token;
            } else {
                // Token expiré, le supprimer
                localStorage.removeItem('keycloak_token');
            }
        } catch (e) {
            // Token invalide
            localStorage.removeItem('keycloak_token');
        }
    }
    
    return null;
}

// Fonction pour sauvegarder le token
export function setAuthToken(token: string): void {
    if (typeof window !== 'undefined') {
        localStorage.setItem('keycloak_token', token);
    }
}

// Fonction pour supprimer le token
export function removeAuthToken(): void {
    if (typeof window !== 'undefined') {
        localStorage.removeItem('keycloak_token');
    }
}

