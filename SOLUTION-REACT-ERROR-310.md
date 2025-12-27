# Solution : Erreur React #310

## 🔴 Problème

Erreur React #310 après le login : "Minified React error #310"

Cette erreur indique généralement :
- Une boucle infinie de re-renders
- Un état mis à jour pendant le rendu
- Un useEffect qui cause des re-renders infinis

## ✅ Corrections Appliquées

### 1. Amélioration du useEffect d'Authentification

- ✅ Vérification de `window` avant d'utiliser localStorage
- ✅ Fonction `checkAuth` encapsulée pour éviter les problèmes de closure
- ✅ Tableau de dépendances vide `[]` pour s'exécuter une seule fois

### 2. Amélioration du useEffect de Chargement des Données

- ✅ Vérification que `isAuthenticated === true` avant de charger
- ✅ Mise à jour de `isLoading` même si non authentifié
- ✅ Dépendance sur `isAuthenticated` pour se réexécuter après le login

### 3. Amélioration du LoginForm

- ✅ Utilisation de `setTimeout` pour éviter les problèmes de re-render
- ✅ Sauvegarde du token avant d'appeler le callback

## 🔄 Rebuild Requis

**IMPORTANT** : Vous devez rebuild le frontend pour que les corrections prennent effet :

```powershell
cd frontend
docker build -t salmaidoufkir/frontend:latest .
docker push salmaidoufkir/frontend:latest
kubectl rollout restart deployment/frontend -n smarthome
```

## 🧪 Test Après Rebuild

1. **Vider le cache du navigateur** (Ctrl+Shift+Delete) ou utiliser une fenêtre privée
2. **Accéder au frontend** : `http://192.168.49.2:30000`
3. **Se connecter** avec les credentials Keycloak
4. **Vérifier la console** (F12) - il ne devrait plus y avoir d'erreur React #310

## 🐛 Si l'Erreur Persiste

### Option 1 : Mode Développement (pour voir l'erreur complète)

Modifiez `next.config.ts` pour désactiver la minification :

```typescript
const nextConfig: NextConfig = {
  productionBrowserSourceMaps: true,
  // ...
};
```

### Option 2 : Vérifier les Logs

```powershell
kubectl logs -n smarthome -l app=frontend --tail=100
```

### Option 3 : Utiliser Port-Forward pour Tester Localement

```powershell
kubectl port-forward -n smarthome deployment/frontend 3000:3000
```

Puis accéder à `http://localhost:3000` et vérifier les erreurs dans la console.

## 📝 Notes

- L'erreur React #310 est souvent causée par des mises à jour d'état pendant le rendu
- Utiliser `setTimeout` avec 0ms peut aider à éviter les problèmes de re-render
- S'assurer que les tableaux de dépendances des useEffect sont corrects

