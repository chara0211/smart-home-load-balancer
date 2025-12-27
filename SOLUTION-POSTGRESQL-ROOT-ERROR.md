# Solution : Erreur PostgreSQL "role root does not exist"

## 🔴 Problème Identifié

PostgreSQL crash constamment avec l'erreur :
```
FATAL: role "root" does not exist
```

## 🔍 Cause

Les probes PostgreSQL utilisent `$(POSTGRES_USER)` qui n'est **pas correctement résolu** par Kubernetes. Kubernetes essaie d'exécuter la commande avec l'utilisateur "root" par défaut au lieu de l'utilisateur PostgreSQL configuré.

## ✅ Solution Appliquée

### Correction des Probes

**Avant (incorrect) :**
```yaml
readinessProbe:
  exec:
    command:
    - pg_isready
    - -U
    - $(POSTGRES_USER)  # ❌ Non résolu correctement
```

**Après (correct) :**
```yaml
readinessProbe:
  exec:
    command:
    - /bin/sh
    - -c
    - pg_isready -U $${POSTGRES_USER}  # ✅ Résolu dans le shell
```

### Pourquoi Ça Fonctionne

1. **Utilisation de `/bin/sh -c`** : Permet d'exécuter la commande dans un shell qui peut résoudre les variables d'environnement
2. **`$${POSTGRES_USER}`** : Le double `$$` est nécessaire dans YAML pour échapper le `$` et permettre au shell de résoudre la variable
3. **Timeouts augmentés** : 15s au lieu de 5-10s pour donner plus de temps

## 📋 Application de la Solution

La configuration a été corrigée. Appliquez-la :

```powershell
# Appliquer la configuration corrigée
kubectl apply -f k8s/databases/postgres-deployment.yaml

# Supprimer le pod PostgreSQL actuel pour qu'il redémarre avec la nouvelle config
kubectl delete pod -n smarthome -l app=postgres --grace-period=0 --force

# Attendre que PostgreSQL soit prêt
kubectl wait --for=condition=ready pod -n smarthome -l app=postgres --timeout=300s
```

## 🔍 Vérification

Après application, vérifiez que PostgreSQL démarre correctement :

```powershell
# Vérifier l'état
kubectl get pods -n smarthome -l app=postgres

# Vérifier les logs (ne devrait plus y avoir d'erreurs "role root")
kubectl logs -n smarthome -l app=postgres --tail=20
```

## ⚠️ Si le Problème Persiste

Si PostgreSQL ne démarre toujours pas, vous pouvez :

1. **Réinitialiser complètement PostgreSQL** :
```powershell
.\scripts\reparer-postgresql.ps1
```

2. **Vérifier le secret** :
```powershell
kubectl get secret postgres-secret -n smarthome -o yaml
```

3. **Utiliser Docker Compose** (solution alternative) :
```powershell
.\scripts\migrer-vers-docker-compose.ps1
```

## 📝 Notes

- Les probes corrigées utilisent maintenant le shell pour résoudre correctement les variables d'environnement
- Les timeouts ont été augmentés pour donner plus de temps à PostgreSQL
- Cette correction devrait résoudre le problème de CrashLoopBackOff

