# Guide : Accès Direct aux Services sans Processus en Arrière-Plan

Ce guide explique comment rendre tous vos services accessibles directement via l'IP de Minikube **sans avoir à démarrer quoi que ce soit en arrière-plan**.

## 🔴 Problème Actuel

Avec le driver **Docker** de Minikube, les services NodePort ne sont **pas accessibles directement** via l'IP du node. C'est une limitation du driver Docker.

## ✅ Solution 1 : Changer le Driver Minikube vers Hyper-V (Recommandé)

Hyper-V supporte l'accès direct via NodePort sans avoir besoin de `minikube tunnel`.

### Prérequis

- Windows 10/11 Pro, Enterprise ou Education
- Hyper-V activé
- WSL2 activé (optionnel mais recommandé)

### Étape 1 : Vérifier que Hyper-V est disponible

```powershell
# Vérifier que Hyper-V est disponible
Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All
```

Si Hyper-V n'est pas activé, activez-le :
```powershell
# En tant qu'administrateur
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All
```

### Étape 2 : Arrêter et supprimer Minikube actuel

```powershell
# Arrêter Minikube
minikube stop

# Supprimer le cluster actuel
minikube delete
```

### Étape 3 : Créer un nouveau cluster avec Hyper-V

```powershell
# Créer Minikube avec le driver Hyper-V
minikube start --driver=hyperv

# Vérifier que le driver est bien Hyper-V
minikube profile list
```

### Étape 4 : Redéployer tous les services

Une fois Minikube redémarré avec Hyper-V, redéployez tous vos services :

```powershell
# Créer le namespace
kubectl apply -f k8s/namespaces/smarthome-namespace.yaml

# Créer les secrets
kubectl create secret generic postgres-secret --from-literal=username=smarthome --from-literal=password=smarthome --from-literal=database=smarthome -n smarthome
kubectl create secret generic rabbitmq-secret --from-literal=username=guest --from-literal=password=guest -n smarthome

# Déployer PostgreSQL
kubectl apply -f k8s/databases/postgres-deployment.yaml
kubectl apply -f k8s/databases/postgres-service.yaml

# Déployer RabbitMQ
kubectl apply -f k8s/message-broker/rabbitmq-deployment.yaml
kubectl apply -f k8s/message-broker/rabbitmq-service.yaml

# Déployer tous les services backend
kubectl apply -f k8s/services/usage-collector/
kubectl apply -f k8s/services/device-simulator/
kubectl apply -f k8s/services/peak-detector/
kubectl apply -f k8s/services/optimizer/
kubectl apply -f k8s/services/billing/

# Déployer le frontend
kubectl apply -f k8s/services/frontend/

# Déployer tous les services NodePort
kubectl apply -f k8s/services/frontend/service-nodeport.yaml
kubectl apply -f k8s/services/usage-collector/service-nodeport.yaml
kubectl apply -f k8s/services/device-simulator/service-nodeport.yaml
kubectl apply -f k8s/services/peak-detector/service-nodeport.yaml
kubectl apply -f k8s/services/optimizer/service-nodeport.yaml
kubectl apply -f k8s/services/billing/service-nodeport.yaml
```

### Étape 5 : Accéder aux services

Une fois déployé, obtenez l'IP de Minikube :

```powershell
minikube ip
```

Puis accédez directement aux services via :

- **Frontend** : `http://<IP>:30000`
- **Usage Collector** : `http://<IP>:30083`
- **Device Simulator** : `http://<IP>:30082`
- **Peak Detector** : `http://<IP>:30084`
- **Optimizer** : `http://<IP>:30085`
- **Billing** : `http://<IP>:30086`

**Aucun processus en arrière-plan nécessaire !** ✅

---

## ✅ Solution 2 : Service Windows pour Minikube Tunnel (Alternative)

Si vous ne pouvez pas utiliser Hyper-V, vous pouvez créer un service Windows qui démarre `minikube tunnel` automatiquement au démarrage de Windows.

### Étape 1 : Créer le script de tunnel

Créez le fichier `scripts/minikube-tunnel-service.ps1` :

```powershell
# Script pour minikube tunnel
while ($true) {
    try {
        minikube tunnel
    } catch {
        Write-Host "Erreur: $_" -ForegroundColor Red
        Start-Sleep -Seconds 10
    }
    Start-Sleep -Seconds 5
}
```

### Étape 2 : Créer un service Windows avec NSSM

1. **Télécharger NSSM** : https://nssm.cc/download
2. **Extraire NSSM** dans un dossier (ex: `C:\nssm`)
3. **Créer le service** :

```powershell
# En tant qu'administrateur
cd C:\nssm\win64
.\nssm.exe install MinikubeTunnel "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" "-File D:\Salma\smart-home-load-balancer\scripts\minikube-tunnel-service.ps1"
.\nssm.exe set MinikubeTunnel AppDirectory "D:\Salma\smart-home-load-balancer"
.\nssm.exe set MinikubeTunnel DisplayName "Minikube Tunnel"
.\nssm.exe set MinikubeTunnel Description "Service pour exposer les services Kubernetes NodePort via minikube tunnel"
.\nssm.exe set MinikubeTunnel Start SERVICE_AUTO_START
.\nssm.exe start MinikubeTunnel
```

### Étape 3 : Vérifier le service

```powershell
# Vérifier que le service est en cours d'exécution
Get-Service MinikubeTunnel

# Voir les logs
Get-EventLog -LogName Application -Source NSSM -Newest 10
```

### Avantages

- ✅ Démarre automatiquement avec Windows
- ✅ Fonctionne en arrière-plan
- ✅ Pas besoin de démarrer manuellement

### Inconvénients

- ❌ Nécessite NSSM
- ❌ Plus complexe à configurer
- ❌ Nécessite les droits administrateur

---

## 🎯 Solution 3 : Utiliser Ingress avec un Domaine Local (Avancé)

Vous pouvez configurer un Ingress Controller avec un domaine local (`smarthome.local`) qui sera accessible directement.

### Étape 1 : Activer l'Ingress dans Minikube

```powershell
minikube addons enable ingress
```

### Étape 2 : Obtenir l'IP de l'Ingress

```powershell
minikube ip
```

### Étape 3 : Configurer le fichier hosts

Ajoutez dans `C:\Windows\System32\drivers\etc\hosts` (en tant qu'administrateur) :

```
<IP> smarthome.local
```

### Étape 4 : Créer l'Ingress

Créez un fichier `k8s/ingress/ingress.yaml` qui route tous les services.

### Avantages

- ✅ URLs propres (`http://smarthome.local/api/usage-collector`)
- ✅ Pas besoin de ports différents
- ✅ Configuration production-like

### Inconvénients

- ❌ Nécessite de modifier le fichier hosts
- ❌ Plus complexe à configurer

---

## 📊 Comparaison des Solutions

| Solution | Accès Direct | Configuration | Complexité | Recommandation |
|----------|--------------|---------------|------------|----------------|
| **Hyper-V Driver** | ✅ Oui | Moyenne | ⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Service Windows** | ✅ Oui | Complexe | ⭐⭐⭐⭐ | ⭐⭐⭐ |
| **Ingress** | ✅ Oui | Complexe | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |

---

## 🎯 Recommandation

**Utilisez la Solution 1 (Hyper-V Driver)** car :
- ✅ Accès direct sans processus en arrière-plan
- ✅ Configuration simple
- ✅ Fonctionne nativement avec Windows
- ✅ Pas besoin de services supplémentaires

---

## 📝 Commandes Rapides

### Vérifier le driver actuel

```powershell
minikube profile list
```

### Changer vers Hyper-V

```powershell
minikube stop
minikube delete
minikube start --driver=hyperv
```

### Obtenir l'IP après changement

```powershell
minikube ip
```

---

**Avec Hyper-V, tous vos services seront accessibles directement via l'IP sans aucun processus en arrière-plan ! 🎉**

