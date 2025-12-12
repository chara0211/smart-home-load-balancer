# Guide : Visualiser votre Cluster Kubernetes

Ce guide explique toutes les façons de visualiser et surveiller votre cluster Kubernetes.

---

## 📊 1. Via kubectl (Ligne de commande)

### Commandes de base

```powershell
# Voir tous les pods, services, deployments dans le namespace
kubectl get all -n smarthome

# Voir uniquement les pods
kubectl get pods -n smarthome

# Voir les services
kubectl get services -n smarthome

# Voir les deployments
kubectl get deployments -n smarthome

# Voir les nodes du cluster
kubectl get nodes

# Voir les informations du cluster
kubectl cluster-info
```

### Vues détaillées

```powershell
# Voir les pods avec plus de détails (wide)
kubectl get pods -n smarthome -o wide

# Voir les pods avec leurs labels
kubectl get pods -n smarthome --show-labels

# Voir les événements récents
kubectl get events -n smarthome --sort-by='.lastTimestamp'

# Voir les ressources utilisées (si metrics-server est installé)
kubectl top pods -n smarthome
kubectl top nodes
```

### Vues en temps réel (watch)

```powershell
# Surveiller les pods en temps réel
kubectl get pods -n smarthome -w

# Surveiller tous les événements
kubectl get events -n smarthome -w
```

---

## 🌐 2. Dashboard Kubernetes (Interface Web)

### Option A : Minikube Dashboard

```powershell
# Démarrer le dashboard (ouvre automatiquement dans le navigateur)
minikube dashboard

# Ou obtenir l'URL seulement
minikube dashboard --url
```

**Note :** Si vous avez une erreur de permissions Hyper-V, exécutez PowerShell en tant qu'administrateur.

### Option B : Déployer le Dashboard manuellement

```powershell
# Installer le dashboard
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml

# Créer un service account pour accéder
kubectl create serviceaccount dashboard-admin-sa -n kubernetes-dashboard
kubectl create clusterrolebinding dashboard-admin-sa --clusterrole=cluster-admin --serviceaccount=kubernetes-dashboard:dashboard-admin-sa

# Obtenir le token
kubectl -n kubernetes-dashboard create token dashboard-admin-sa

# Accéder via port-forward
kubectl port-forward -n kubernetes-dashboard service/kubernetes-dashboard-kong-proxy 8443:443
# Puis ouvrir : https://localhost:8443
```

---

## 🖥️ 3. Outils GUI (Interfaces Graphiques)

### Lens (Recommandé - Gratuit)

**Lens** est un IDE Kubernetes gratuit et populaire :

1. **Télécharger** : https://k8slens.dev/
2. **Installer** et lancer
3. **Ajouter votre cluster** : Lens détecte automatiquement Minikube ou vous pouvez ajouter manuellement

**Avantages :**
- Interface graphique moderne
- Visualisation des ressources en temps réel
- Gestion des pods, services, deployments
- Visualisation des logs
- Terminal intégré

### k9s (Terminal UI)

**k9s** est une interface en terminal très populaire :

```powershell
# Installer via Chocolatey
choco install k9s

# Ou télécharger depuis : https://k9scli.io/
# Lancer
k9s
```

**Utilisation :**
- Appuyez sur `:` pour les commandes
- Utilisez les flèches pour naviguer
- `d` pour décrire une ressource
- `l` pour les logs
- `e` pour éditer

### Octant (Déprécié mais fonctionnel)

Interface web locale développée par VMware.

---

## 📈 4. Monitoring (Si déployé)

### Grafana

Si vous avez déployé Grafana dans votre cluster :

```powershell
# Port-forward vers Grafana
kubectl port-forward service/grafana-service 3000:3000 -n smarthome

# Ouvrir dans le navigateur
# http://localhost:3000
# Username: admin
# Password: (voir les secrets)
```

### Prometheus

Si vous avez déployé Prometheus :

```powershell
# Port-forward vers Prometheus
kubectl port-forward service/prometheus-service 9090:9090 -n smarthome

# Ouvrir dans le navigateur
# http://localhost:9090
```

---

## 🔍 5. Commandes de Visualisation Avancées

### Arbre des ressources

```powershell
# Voir la hiérarchie des ressources
kubectl tree deployment usage-collector-service -n smarthome

# Si kubectl-tree n'est pas installé :
# kubectl krew install tree
```

### Vue en YAML/JSON

```powershell
# Voir la configuration complète d'un pod
kubectl get pod <pod-name> -n smarthome -o yaml

# Voir la configuration d'un service
kubectl get service <service-name> -n smarthome -o yaml

# Voir en JSON
kubectl get pod <pod-name> -n smarthome -o json
```

### Logs en temps réel

```powershell
# Logs d'un pod
kubectl logs -f <pod-name> -n smarthome

# Logs d'un deployment
kubectl logs -f deployment/usage-collector-service -n smarthome

# Logs de tous les pods d'un label
kubectl logs -f -l app=usage-collector-service -n smarthome
```

---

## 📋 6. Script de Visualisation Rapide

Créez un script PowerShell pour voir l'état complet :

```powershell
# Sauvegarder dans view-cluster.ps1
Write-Host "=== CLUSTER KUBERNETES - VUE D'ENSEMBLE ===" -ForegroundColor Cyan
Write-Host "`n--- NODES ---" -ForegroundColor Yellow
kubectl get nodes

Write-Host "`n--- PODS ---" -ForegroundColor Yellow
kubectl get pods -n smarthome -o wide

Write-Host "`n--- SERVICES ---" -ForegroundColor Yellow
kubectl get services -n smarthome

Write-Host "`n--- DEPLOYMENTS ---" -ForegroundColor Yellow
kubectl get deployments -n smarthome

Write-Host "`n--- RESSOURCES UTILISEES ---" -ForegroundColor Yellow
kubectl top pods -n smarthome 2>$null || Write-Host "Metrics-server non disponible"
```

---

## 🎯 Recommandations

### Pour un usage quotidien :
1. **Lens** - Interface graphique complète et moderne
2. **kubectl get all** - Vue rapide en ligne de commande
3. **k9s** - Si vous préférez le terminal

### Pour le monitoring :
1. **Grafana** - Dashboards personnalisés
2. **Prometheus** - Métriques détaillées
3. **kubectl top** - Vue rapide des ressources

### Pour le débogage :
1. **kubectl logs -f** - Logs en temps réel
2. **kubectl describe** - Détails d'une ressource
3. **kubectl get events** - Événements récents

---

## 🚀 Démarrage Rapide

### Option la plus simple (Minikube) :

```powershell
# Ouvrir le dashboard
minikube dashboard
```

### Option recommandée (Lens) :

1. Télécharger Lens : https://k8slens.dev/
2. Installer et lancer
3. Votre cluster Minikube sera détecté automatiquement

---

## 📝 Commandes Utiles pour Visualiser

```powershell
# Vue d'ensemble complète
kubectl get all -n smarthome

# Vue avec plus de détails
kubectl get all -n smarthome -o wide

# Voir les ressources par type
kubectl api-resources

# Voir les namespaces
kubectl get namespaces

# Voir les secrets (noms seulement)
kubectl get secrets -n smarthome

# Voir les configmaps
kubectl get configmaps -n smarthome
```

---

## ✅ Checklist de Visualisation

- [ ] Pouvoir voir tous les pods avec `kubectl get pods`
- [ ] Pouvoir voir tous les services avec `kubectl get services`
- [ ] Avoir accès au dashboard (Minikube ou Lens)
- [ ] Pouvoir voir les logs avec `kubectl logs`
- [ ] Pouvoir voir les événements avec `kubectl get events`

---

**Note :** Pour Minikube, le dashboard est la méthode la plus simple. Pour une expérience plus riche, installez Lens.

