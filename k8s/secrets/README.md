# Configuration des Secrets Kubernetes

Ce dossier contient les templates pour créer les secrets Kubernetes nécessaires au déploiement.

## 🔐 Secrets requis

Avant de déployer l'application, vous devez créer les secrets suivants dans le namespace `smarthome` :

### 1. PostgreSQL Secret

```bash
kubectl create secret generic postgres-secret \
  --from-literal=username=smarthome \
  --from-literal=password=VOTRE_MOT_DE_PASSE_POSTGRES \
  --from-literal=database=smarthome \
  -n smarthome
```

### 2. RabbitMQ Secret

```bash
kubectl create secret generic rabbitmq-secret \
  --from-literal=username=guest \
  --from-literal=password=VOTRE_MOT_DE_PASSE_RABBITMQ \
  -n smarthome
```

### 3. MongoDB Secret

```bash
kubectl create secret generic mongodb-secret \
  --from-literal=username=admin \
  --from-literal=password=VOTRE_MOT_DE_PASSE_MONGODB \
  -n smarthome
```

### 4. Keycloak Secret

```bash
kubectl create secret generic keycloak-secret \
  --from-literal=username=admin \
  --from-literal=password=VOTRE_MOT_DE_PASSE_KEYCLOAK \
  -n smarthome
```

### 5. Grafana Secret

```bash
kubectl create secret generic grafana-secret \
  --from-literal=password=VOTRE_MOT_DE_PASSE_GRAFANA \
  -n smarthome
```

### 6. Docker Registry Secret (pour les images privées)

Si vous utilisez un registry Docker privé :

```bash
kubectl create secret docker-registry registry-secret \
  --docker-server=salmaidoufkir.com \
  --docker-username=your-username \
  --docker-password=your-password \
  --docker-email=your-email@example.com \
  -n smarthome
```

## 📝 Script de création automatique

Vous pouvez créer un script `create-secrets.sh` avec vos mots de passe :

```bash
#!/bin/bash
# ⚠️  Ne commitez JAMAIS ce fichier avec des mots de passe réels !

NAMESPACE="smarthome"

kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic postgres-secret \
  --from-literal=username=smarthome \
  --from-literal=password=CHANGEZ_MOI \
  --from-literal=database=smarthome \
  -n $NAMESPACE

kubectl create secret generic rabbitmq-secret \
  --from-literal=username=guest \
  --from-literal=password=CHANGEZ_MOI \
  -n $NAMESPACE

kubectl create secret generic mongodb-secret \
  --from-literal=username=admin \
  --from-literal=password=CHANGEZ_MOI \
  -n $NAMESPACE

kubectl create secret generic keycloak-secret \
  --from-literal=username=admin \
  --from-literal=password=CHANGEZ_MOI \
  -n $NAMESPACE

kubectl create secret generic grafana-secret \
  --from-literal=password=CHANGEZ_MOI \
  -n $NAMESPACE

echo "✅ Secrets créés dans le namespace $NAMESPACE"
```

## 🔄 Mise à jour des secrets

Pour mettre à jour un secret existant :

```bash
kubectl delete secret postgres-secret -n smarthome
kubectl create secret generic postgres-secret \
  --from-literal=username=smarthome \
  --from-literal=password=NOUVEAU_MOT_DE_PASSE \
  --from-literal=database=smarthome \
  -n smarthome

# Redémarrer les pods qui utilisent ce secret
kubectl rollout restart deployment/postgres -n smarthome
```

## 🔍 Vérification

Pour vérifier qu'un secret a été créé :

```bash
kubectl get secrets -n smarthome
kubectl describe secret postgres-secret -n smarthome
```

## ⚠️ Sécurité

- **Ne commitez JAMAIS** les secrets avec des valeurs réelles dans Git
- Utilisez des outils comme Sealed Secrets, External Secrets Operator, ou Vault pour la production
- Changez tous les mots de passe par défaut
- Utilisez des mots de passe forts et uniques pour chaque service

