export async function getCurrentUsage() {
    try {
        const res = await fetch("http://localhost:8083/usage/current", {
            cache: "no-store",
        });

        if (!res.ok) {
            return { totalPowerKw: 0 };
        }

        return res.json();
    } catch (err) {
        console.error("API Error:", err);
        return { totalPowerKw: 0 };
    }
}