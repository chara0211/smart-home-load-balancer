'use client';

import { useState } from 'react';

interface LoginFormProps {
    onLogin?: () => void;
}

export default function LoginForm({ onLogin }: LoginFormProps) {
    const [username, setUsername] = useState('');
    const [password, setPassword] = useState('');
    const [error, setError] = useState('');
    const [loading, setLoading] = useState(false);

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setError('');
        setLoading(true);

        try {
            // Appeler l'API de login
            const response = await fetch(`/api/auth/login?username=${encodeURIComponent(username)}&password=${encodeURIComponent(password)}`);
            
            if (!response.ok) {
                let errorMessage = 'Authentication failed';
                try {
                    const errorData = await response.json();
                    errorMessage = errorData.error || errorData.detail || errorMessage;
                } catch (e) {
                    errorMessage = `HTTP ${response.status}: ${response.statusText}`;
                }
                setError(errorMessage);
                setLoading(false);
                return;
            }

            const data = await response.json();
            
            // Vérifier que le token existe
            if (!data.access_token) {
                setError('No token received from server');
                setLoading(false);
                return;
            }
            
            // Sauvegarder le token dans localStorage (vérifier que nous sommes côté client)
            if (typeof window !== 'undefined') {
                localStorage.setItem('auth_token', data.access_token);
                
                // Appeler le callback si fourni (utiliser setTimeout pour éviter les problèmes de re-render)
                if (onLogin) {
                    // Utiliser requestAnimationFrame pour s'assurer que le state est mis à jour
                    requestAnimationFrame(() => {
                        onLogin();
                    });
                } else {
                    // Sinon, rediriger
                    window.location.href = '/';
                }
            }
        } catch (err: any) {
            console.error('Login error:', err);
            setError(err.message || 'An error occurred. Please check the console for details.');
            setLoading(false);
        }
    };

    return (
        <div className="min-h-screen flex items-center justify-center bg-[#0b1020]">
            <div className="bg-[#1a1f3a] p-8 rounded-lg shadow-lg w-full max-w-md">
                <h2 className="text-2xl font-bold mb-6 text-center text-white">Smart Home Dashboard</h2>
                <form onSubmit={handleSubmit} className="space-y-4">
                    <div>
                        <label htmlFor="username" className="block text-sm font-medium text-gray-300 mb-2">
                            Username
                        </label>
                        <input
                            id="username"
                            type="text"
                            value={username}
                            onChange={(e) => setUsername(e.target.value)}
                            required
                            className="w-full px-4 py-2 bg-[#0b1020] border border-gray-600 rounded-md text-white focus:outline-none focus:ring-2 focus:ring-purple-500"
                            placeholder="Enter your username"
                        />
                    </div>
                    <div>
                        <label htmlFor="password" className="block text-sm font-medium text-gray-300 mb-2">
                            Password
                        </label>
                        <input
                            id="password"
                            type="password"
                            value={password}
                            onChange={(e) => setPassword(e.target.value)}
                            required
                            className="w-full px-4 py-2 bg-[#0b1020] border border-gray-600 rounded-md text-white focus:outline-none focus:ring-2 focus:ring-purple-500"
                            placeholder="Enter your password"
                        />
                    </div>
                    {error && (
                        <div className="bg-red-500/20 border border-red-500 text-red-300 px-4 py-3 rounded-md">
                            {error}
                        </div>
                    )}
                    <button
                        type="submit"
                        disabled={loading}
                        className="w-full bg-purple-600 hover:bg-purple-700 text-white font-medium py-2 px-4 rounded-md transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                    >
                        {loading ? 'Logging in...' : 'Login'}
                    </button>
                </form>
            </div>
        </div>
    );
}

