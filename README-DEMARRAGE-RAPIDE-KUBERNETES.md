# 🚀 Démarrage Rapide - Configuration Kubernetes

Guide rapide pour configurer Kubernetes sur votre machine après avoir récupéré le code de votre collègue.

## ⚡ Démarrage Ultra-Rapide (Script Automatique)

Si vous voulez tout configurer automatiquement :

1. **Ouvrir PowerShell en tant qu'administrateur**
   - Clic droit sur PowerShell → "Exécuter en tant qu'administrateur"

2. **Naviguer vers le projet** :
   ```powershell
   cd D:\smart-home-load-balancer
   ```

3. **Exécuter le script de configuration** :
   ```powershell
   .\scripts\setup-kubernetes-complet.ps1
   ```

4. **Configurer le fichier hosts** (manuellement) :
   - Ouvrir `C:\Windows\System32\drivers\etc\hosts` en tant qu'administrateur
   - Ajouter : `<IP_MINIKUBE> smarthome.local`
   - Obtenir l'IP avec : `minikube ip`

5. **Vérifier la configuration** :
   ```powershell
   .\scripts\verifier-configuration.ps1
   ```

## 📋 Guide Complet Étape par Étape

Si vous préférez faire les étapes manuellement ou si le script ne fonctionne pas, consultez le guide complet :

👉 **[GUIDE-INSTALLATION-KUBERNETES-COMPLET.md](GUIDE-INSTALLATION-KUBERNETES-COMPLET.md)**

Ce guide couvre :
- Installation de tous les outils nécessaires
- Configuration de Minikube
- Création des secrets
- Déploiement de tous les services
- Configuration de l'Ingress
- Tests avec Postman

## ✅ Vérification Rapide

Pour vérifier que tout fonctionne :

```powershell
# Vérifier l'état de tous les pods
kubectl get pods -n smarthome

# Vérifier les services
kubectl get svc -n smarthome

# Vérifier l'Ingress
kubectl get ingress -n smarthome
```

## 🧪 Tests avec Postman

Une fois tout configuré, testez avec Postman :

- `GET http://smarthome.local/usage/current`
- `GET http://smarthome.local/optimizer/health`
- `GET http://smarthome.local/devices/devices`
- `POST http://smarthome.local/usage/save`

👉 Voir **[GUIDE-TEST-POSTMAN.md](GUIDE-TEST-POSTMAN.md)** pour plus de détails.

## 🐛 Dépannage

### Minikube ne démarre pas

```powershell
# Essayer avec Docker driver
minikube start --driver=docker

# Ou vérifier les permissions
# Assurez-vous que PowerShell est ouvert en tant qu'administrateur
```

### Les pods ne démarrent pas

```powershell
# Voir les logs d'un pod
kubectl logs -n smarthome <nom-du-pod>

# Voir pourquoi un pod est en erreur
kubectl describe pod <nom-du-pod> -n smarthome
```

### Erreur "ImagePullBackOff"

Les images Docker ne sont pas disponibles. Vous devez soit :
- Construire les images localement
- Configurer le secret `registry-secret` si vous utilisez un registry privé

## 📚 Documentation Complète

- **[GUIDE-INSTALLATION-KUBERNETES-COMPLET.md](GUIDE-INSTALLATION-KUBERNETES-COMPLET.md)** - Guide détaillé étape par étape
- **[GUIDE-TEST-POSTMAN.md](GUIDE-TEST-POSTMAN.md)** - Guide pour tester avec Postman
- **[GUIDE-DEMARRER-MINIKUBE.md](GUIDE-DEMARRER-MINIKUBE.md)** - Guide spécifique pour Minikube
- **[REQUETES-POST-VALIDES.md](REQUETES-POST-VALIDES.md)** - Liste des requêtes POST disponibles

## 🆘 Besoin d'Aide ?

1. Vérifiez que tous les prérequis sont installés
2. Exécutez le script de vérification : `.\scripts\verifier-configuration.ps1`
3. Consultez les guides détaillés ci-dessus
4. Vérifiez les logs des services en erreur

## ✅ Checklist Finale

Avant de considérer que tout est configuré :

- [ ] Minikube est démarré (`minikube status`)
- [ ] Le namespace `smarthome` existe (`kubectl get namespaces`)
- [ ] Tous les secrets sont créés (`kubectl get secrets -n smarthome`)
- [ ] PostgreSQL est en cours d'exécution (`kubectl get pods -n smarthome | findstr postgres`)
- [ ] RabbitMQ est en cours d'exécution (`kubectl get pods -n smarthome | findstr rabbitmq`)
- [ ] Tous les services sont en cours d'exécution (`kubectl get pods -n smarthome`)
- [ ] L'Ingress est configuré (`kubectl get ingress -n smarthome`)
- [ ] Le fichier hosts est configuré
- [ ] Les tests Postman fonctionnent

---

**Bon courage ! 🚀**

