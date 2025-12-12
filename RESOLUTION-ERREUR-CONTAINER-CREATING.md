# Résolution : Erreur "ContainerCreating" - PostgreSQL

Ce document explique l'erreur que vous rencontrez et comment la résoudre.

---

## 🔍 Analyse de l'Erreur

### Message d'Erreur

```
Error from server (BadRequest): container "postgres" in pod "postgres-59656f786c-l2lcg" is waiting to start: ContainerCreating
```

### Signification

**Ce n'est pas vraiment une erreur** ! Cela signifie que :
- ✅ Le pod PostgreSQL est en cours de création
- ⏳ Kubernetes est en train de télécharger l'image ou de créer le conteneur
- ⏳ Le conteneur n'est pas encore démarré, donc pas de logs disponibles

**C'est normal** au démarrage, mais si ça dure trop longtemps (> 2-3 minutes), il y a un problème.

---

## 🔧 Solutions et Diagnostic

### Étape 1 : Vérifier l'État du Pod

```bash
# Voir l'état détaillé du pod
kubectl get pods -n smarthome

# Voir plus de détails
kubectl describe pod postgres-59656f786c-l2lcg -n smarthome
```

**États possibles** :
- `ContainerCreating` → En cours de création (normal au début)
- `ImagePullBackOff` → Problème de téléchargement d'image
- `ErrImagePull` → Erreur de pull d'image
- `Pending` → Pod ne peut pas être planifié
- `Running` → ✅ Tout va bien

### Étape 2 : Voir les Événements

```bash
# Voir les événements récents
kubectl get events -n smarthome --sort-by='.lastTimestamp' | grep postgres

# Ou voir tous les événements
kubectl describe pod postgres-59656f786c-l2lcg -n smarthome | grep -A 20 Events
```

**Événements à chercher** :
- `Pulling image "postgres:16"` → Téléchargement en cours (normal)
- `Successfully pulled image` → Image téléchargée (bon signe)
- `Created container` → Conteneur créé (bon signe)
- `Started container` → Conteneur démarré (✅ prêt)
- `Failed to pull image` → ❌ Problème d'image
- `Failed to create volume` → ❌ Problème de volume

---

## 🐛 Problèmes Courants et Solutions

### Problème 1 : Image en Cours de Téléchargement

**Symptôme** : `ContainerCreating` depuis moins de 2-3 minutes

**Cause** : L'image `postgres:16` est en train d'être téléchargée (première fois)

**Solution** : **Attendre** (c'est normal)

```bash
# Surveiller la progression
kubectl get pods -n smarthome -w

# Ou voir les événements
kubectl get events -n smarthome -w
```

**Temps normal** : 1-3 minutes selon votre connexion internet

---

### Problème 2 : ImagePullBackOff ou ErrImagePull

**Symptôme** : 
```
STATUS: ImagePullBackOff
ou
STATUS: ErrImagePull
```

**Cause** : Kubernetes ne peut pas télécharger l'image

**Solutions** :

#### Solution A : Vérifier la connexion internet

```bash
# Tester le pull manuellement
docker pull postgres:16

# Si ça fonctionne, le problème vient d'ailleurs
```

#### Solution B : Vérifier les événements

```bash
kubectl describe pod postgres-59656f786c-l2lcg -n smarthome | grep -A 10 Events
```

**Erreurs possibles** :
- `network is unreachable` → Problème réseau
- `unauthorized` → Problème d'authentification (si registry privé)
- `not found` → Image n'existe pas

---

### Problème 3 : Problème de Volume (PVC)

**Symptôme** : `ContainerCreating` depuis longtemps, événements montrent des erreurs de volume

**Cause** : Le PersistentVolumeClaim (PVC) ne peut pas être créé

**Vérification** :

```bash
# Voir les PVC
kubectl get pvc -n smarthome

# Voir les détails
kubectl describe pvc postgres-pvc -n smarthome
```

**Erreurs possibles** :
- `Pending` → Pas de stockage disponible
- `Bound` → ✅ OK

**Solutions** :

#### Solution A : Vérifier le stockage disponible (Minikube)

```bash
# Si vous utilisez Minikube
minikube status

# Vérifier l'espace disque
minikube ssh -- df -h
```

#### Solution B : Supprimer et recréer le PVC

```bash
# Supprimer le deployment et le PVC
kubectl delete deployment postgres -n smarthome
kubectl delete pvc postgres-pvc -n smarthome

# Recréer
kubectl apply -f k8s/databases/postgres-deployment.yaml
```

---

### Problème 4 : Secrets Manquants

**Symptôme** : `ContainerCreating`, événements montrent des erreurs de secrets

**Cause** : Les secrets PostgreSQL ne sont pas créés

**Vérification** :

```bash
# Voir les secrets
kubectl get secrets -n smarthome

# Vérifier que postgres-secret existe
kubectl get secret postgres-secret -n smarthome
```

**Solution** : Créer les secrets

```bash
kubectl create secret generic postgres-secret \
  --from-literal=username=smarthome \
  --from-literal=password=smarthome \
  --from-literal=database=smarthome \
  -n smarthome
```

---

### Problème 5 : Ressources Insuffisantes

**Symptôme** : `Pending` au lieu de `ContainerCreating`

**Cause** : Pas assez de ressources (CPU/mémoire) dans le cluster

**Vérification** :

```bash
# Voir les ressources disponibles
kubectl top nodes

# Voir les détails du pod
kubectl describe pod postgres-59656f786c-l2lcg -n smarthome | grep -A 10 "Resource\|Limits"
```

**Solution** : Réduire les ressources demandées dans le deployment ou ajouter plus de ressources au cluster

---

## 🔍 Diagnostic Complet

### Commande de Diagnostic Rapide

```bash
# 1. État du pod
kubectl get pods -n smarthome | grep postgres

# 2. Détails du pod
kubectl describe pod postgres-59656f786c-l2lcg -n smarthome

# 3. Événements récents
kubectl get events -n smarthome --sort-by='.lastTimestamp' | grep postgres

# 4. Logs (si le conteneur a démarré)
kubectl logs postgres-59656f786c-l2lcg -n smarthome

# 5. Vérifier les PVC
kubectl get pvc -n smarthome

# 6. Vérifier les secrets
kubectl get secrets -n smarthome
```

---

## ⏱️ Temps d'Attente Normaux

| Étape | Temps Normal |
|-------|-------------|
| **Téléchargement image** | 1-3 minutes (première fois) |
| **Création conteneur** | 10-30 secondes |
| **Démarrage PostgreSQL** | 30-60 secondes |
| **Total** | **2-5 minutes** (première fois) |

**Si ça dépasse 5 minutes** → Il y a probablement un problème.

---

## ✅ Solution Rapide : Attendre et Vérifier

### Étape 1 : Attendre 2-3 minutes

C'est normal que `ContainerCreating` prenne du temps au début.

### Étape 2 : Vérifier la Progression

```bash
# Surveiller en temps réel
kubectl get pods -n smarthome -w
```

**Vous devriez voir** :
```
postgres-xxx   0/1   ContainerCreating   0   30s
postgres-xxx   0/1   Running             0   2m
postgres-xxx   1/1   Running             0   3m  ✅
```

### Étape 3 : Si ça Bloque, Diagnostiquer

```bash
# Voir les événements
kubectl describe pod postgres-59656f786c-l2lcg -n smarthome
```

Cherchez dans la section "Events" les erreurs.

---

## 🚀 Commandes Utiles

### Voir les Logs (Quand le Pod est Running)

```bash
# Attendre que le pod soit Running
kubectl wait --for=condition=ready pod -l app=postgres -n smarthome --timeout=300s

# Puis voir les logs
kubectl logs -f deployment/postgres -n smarthome
```

### Redémarrer le Pod

```bash
# Supprimer le pod (Kubernetes le recréera automatiquement)
kubectl delete pod postgres-59656f786c-l2lcg -n smarthome

# Ou redémarrer le deployment
kubectl rollout restart deployment/postgres -n smarthome
```

### Voir Tous les Pods

```bash
# Voir tous les pods avec leurs états
kubectl get pods -n smarthome

# Avec plus de détails
kubectl get pods -n smarthome -o wide
```

---

## 📋 Checklist de Diagnostic

Si `ContainerCreating` dure plus de 5 minutes, vérifiez :

- [ ] **Image en cours de téléchargement ?**
  ```bash
  kubectl describe pod postgres-xxx -n smarthome | grep -i image
  ```

- [ ] **PVC créé et bound ?**
  ```bash
  kubectl get pvc -n smarthome
  ```

- [ ] **Secrets existent ?**
  ```bash
  kubectl get secrets -n smarthome | grep postgres
  ```

- [ ] **Ressources disponibles ?**
  ```bash
  kubectl top nodes
  ```

- [ ] **Événements montrent des erreurs ?**
  ```bash
  kubectl get events -n smarthome --sort-by='.lastTimestamp' | grep postgres
  ```

---

## 🎯 Solution Immédiate

### Pour Votre Cas Actuel

1. **Attendre 2-3 minutes** (normal au démarrage)

2. **Vérifier l'état** :
   ```bash
   kubectl get pods -n smarthome
   ```

3. **Si toujours `ContainerCreating` après 5 minutes** :
   ```bash
   # Voir les détails
   kubectl describe pod postgres-59656f786c-l2lcg -n smarthome
   
   # Voir les événements
   kubectl get events -n smarthome --sort-by='.lastTimestamp' | grep postgres
   ```

4. **Une fois Running, voir les logs** :
   ```bash
   kubectl logs -f deployment/postgres -n smarthome
   ```

---

## ✅ Conclusion

**L'erreur que vous voyez est normale** au démarrage. Le pod est en train de se créer.

**Action immédiate** :
1. ⏳ **Attendre 2-3 minutes**
2. 🔍 **Vérifier avec** `kubectl get pods -n smarthome`
3. 📊 **Si ça bloque, diagnostiquer avec** `kubectl describe pod`

**Une fois le pod en état `Running`**, vous pourrez voir les logs normalement ! 🚀

