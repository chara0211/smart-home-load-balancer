# Guide : Voir votre Cluster dans le Dashboard Minikube

## 🔍 Problème

Quand vous lancez `minikube dashboard`, le dashboard s'ouvre sur le namespace **`default`**, mais vos ressources sont dans le namespace **`smarthome`**.

## ✅ Solution : Changer de Namespace

### Méthode 1 : Via le Menu du Dashboard

1. **Ouvrez le dashboard** :
   ```powershell
   minikube dashboard
   ```

2. **Dans le dashboard, regardez en haut à droite** :
   - Vous verrez un menu déroulant avec "default" ou "All namespaces"
   - Cliquez sur ce menu déroulant

3. **Sélectionnez "smarthome"** :
   - Dans la liste, choisissez `smarthome`
   - Le dashboard se mettra à jour automatiquement

4. **Vous verrez maintenant** :
   - Tous vos pods (postgres, rabbitmq, usage-collector, etc.)
   - Tous vos services
   - Tous vos deployments

### Méthode 2 : URL Directe

Vous pouvez ouvrir directement le namespace dans l'URL :

1. **Obtenez l'URL du dashboard** :
   ```powershell
   minikube dashboard --url
   ```
   Vous obtiendrez quelque chose comme : `http://127.0.0.1:xxxxx`

2. **Ajoutez le namespace à l'URL** :
   ```
   http://127.0.0.1:xxxxx/#/workloads?namespace=smarthome
   ```

3. **Ouvrez cette URL dans votre navigateur**

### Méthode 3 : Script PowerShell Automatique

Créez un fichier `open-dashboard-smarthome.ps1` :

```powershell
# Obtenir l'URL du dashboard
$dashboardUrl = minikube dashboard --url 2>&1 | Select-String -Pattern "http" | ForEach-Object { $_.Line }

if ($dashboardUrl) {
    # Extraire l'URL de base
    $baseUrl = $dashboardUrl -replace '\s+', ''
    $namespaceUrl = "$baseUrl/#/workloads?namespace=smarthome"
    
    Write-Host "Ouverture du dashboard pour le namespace 'smarthome'..." -ForegroundColor Green
    Write-Host "URL: $namespaceUrl" -ForegroundColor Cyan
    
    # Ouvrir dans le navigateur
    Start-Process $namespaceUrl
} else {
    Write-Host "Erreur : Impossible d'obtenir l'URL du dashboard" -ForegroundColor Red
    Write-Host "Essayez : minikube dashboard" -ForegroundColor Yellow
}
```

Puis exécutez :
```powershell
.\open-dashboard-smarthome.ps1
```

## 📋 Vérification Rapide

Avant d'ouvrir le dashboard, vérifiez que vos ressources existent :

```powershell
# Voir tous les pods dans smarthome
kubectl get pods -n smarthome

# Voir tous les services
kubectl get services -n smarthome

# Voir tous les deployments
kubectl get deployments -n smarthome
```

Si vous voyez des ressources avec ces commandes, elles apparaîtront dans le dashboard une fois le bon namespace sélectionné.

## 🎯 Navigation dans le Dashboard

Une fois dans le namespace `smarthome`, vous pouvez :

1. **Voir les Workloads** (Pods, Deployments, etc.) :
   - Menu de gauche → "Workloads"
   - Vous verrez tous vos pods et deployments

2. **Voir les Services** :
   - Menu de gauche → "Service"
   - Vous verrez postgres-service, rabbitmq-service, etc.

3. **Voir les Config & Storage** :
   - Menu de gauche → "Config & Storage"
   - Secrets, ConfigMaps, etc.

4. **Voir les détails d'un pod** :
   - Cliquez sur un pod
   - Vous verrez les logs, les événements, la configuration

## 🔧 Dépannage

### Le dashboard ne s'ouvre pas

```powershell
# Vérifier que Minikube est en cours d'exécution
minikube status

# Redémarrer le dashboard
minikube dashboard
```

### Erreur de permissions Hyper-V

Exécutez PowerShell **en tant qu'administrateur** :
1. Clic droit sur PowerShell
2. "Exécuter en tant qu'administrateur"
3. Relancez `minikube dashboard`

### Le namespace "smarthome" n'apparaît pas dans la liste

Vérifiez que le namespace existe :
```powershell
kubectl get namespaces
```

Si `smarthome` n'existe pas, créez-le :
```powershell
kubectl create namespace smarthome
```

## 📊 Ce que vous devriez voir

Dans le namespace `smarthome`, vous devriez voir :

**Pods :**
- postgres-xxx
- rabbitmq-xxx
- usage-collector-service-xxx
- peak-detector-service-xxx
- optimizer-service-xxx
- device-simulator-service-xxx

**Services :**
- postgres-service
- rabbitmq-service
- usage-collector-service
- peak-detector-service
- optimizer-service
- device-simulator-service

**Deployments :**
- postgres
- rabbitmq
- usage-collector-service
- peak-detector-service
- optimizer-service
- device-simulator-service

## ✅ Checklist

- [ ] Dashboard ouvert avec `minikube dashboard`
- [ ] Namespace changé vers "smarthome" (menu déroulant en haut)
- [ ] Pods visibles dans la section "Workloads"
- [ ] Services visibles dans la section "Service"
- [ ] Possibilité de cliquer sur un pod pour voir les détails

---

**Astuce :** Le dashboard se souvient de votre dernier namespace sélectionné, donc la prochaine fois que vous l'ouvrirez, il devrait s'ouvrir directement sur "smarthome".

