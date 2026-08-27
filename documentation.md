# Documentation technique — Mise en production de l’application ToDoList

## 1. Présentation du projet

L’objectif de ce projet est de mettre en production une application ToDoList composée d’un frontend Angular, d’un backend Node.js/Express et d’une base de données MySQL.

Le projet a été réalisé progressivement afin de valider le fonctionnement de l’application en local, puis sa conteneurisation, son stockage dans un registre d’images, son déploiement sur Microsoft Azure à l’aide de Terraform et Kubernetes, ainsi que la mise en place d’une chaîne CI/CD et d’une solution de supervision.

L’architecture finale repose donc sur plusieurs niveaux :

* **Développement et validation locale**
* **Conteneurisation avec Docker**
* **Stockage des images dans GitHub Container Registry**
* **Provisionnement de l’infrastructure Azure avec Terraform**
* **Orchestration des conteneurs avec Kubernetes sur AKS**
* **Automatisation des tests, builds et déploiements avec GitHub Actions**
* **Supervision avec Prometheus et Grafana**

L’objectif est de disposer d’une architecture reproductible, automatisée et adaptée à une mise en production.

---

# 2. Architecture générale

## 2.1 Architecture applicative

L’application est constituée de trois composants principaux :

1. **Frontend**

   * Framework : Angular
   * Rôle : interface utilisateur de l’application
   * Port utilisé en développement : `4200`

2. **Backend**

   * Runtime : Node.js
   * Framework : Express
   * Accès aux données : Sequelize / mysql2
   * Port utilisé en développement : `3000`

3. **Base de données**

   * SGBD : MySQL
   * Base utilisée par l’application : `todolist_db`
   * Port : `3306`

En production, ces composants sont séparés afin de respecter le principe de séparation des responsabilités. Le frontend communique avec le backend via HTTP et le backend communique avec MySQL.

L’utilisation de conteneurs permet également d’isoler les différents composants et de garantir un environnement d’exécution reproductible.

## 2.2 Architecture locale

Avant toute conteneurisation, l’application a été testée directement sur une VM Ubuntu.

L’environnement utilisé comprenait :

* Ubuntu
* Node.js `22.23.2`
* npm `10.9.8`
* NVM
* MySQL Server
* Angular CLI
* Les dépendances npm du frontend et du backend

L’architecture locale était la suivante :

```text
                         VM Ubuntu
┌─────────────────────────────────────────────────────┐
│                                                     │
│       ┌──────────────────────────────┐              │
│       │          Frontend            │              │
│       │           Angular            │              │
│       │        localhost:4200        │              │
│       └──────────────┬───────────────┘              │
│                      │                              │
│                      │ HTTP                         │
│                      ▼                              │
│       ┌──────────────────────────────┐              │
│       │           Backend            │              │
│       │        Node.js / Express     │              │
│       │        localhost:3000        │              │
│       └──────────────┬───────────────┘              │
│                      │                              │
│                      │ Sequelize / mysql2           │
│                      ▼                              │
│       ┌──────────────────────────────┐              │
│       │           MySQL              │              │
│       │         localhost:3306       │              │
│       │                              │              │
│       │         todolist_db          │              │
│       │              └─ tasks        │              │
│       └──────────────────────────────┘              │
│                                                     │
└─────────────────────────────────────────────────────┘
```

Cette première étape était importante car elle permettait de vérifier que l’application fonctionnait correctement avant d’introduire la complexité liée à Docker, Kubernetes et Azure.

---

# 3. Validation du fonctionnement en local

## 3.1 Installation

Les outils nécessaires ont été installés sur la VM :

* Node.js
* npm
* NVM
* Angular CLI
* MySQL
* Les dépendances du backend
* Les dépendances du frontend

Les dépendances Node.js ont été installées à l’aide de npm.

## 3.2 Initialisation de la base de données

La base de données a été créée à partir du script fourni dans le projet backend.

La configuration de connexion à MySQL est stockée dans les variables d’environnement du backend.

Pour les premiers tests locaux, les identifiants de développement ont été configurés dans le fichier `.env`.

Cette méthode permet de séparer la configuration du code source et évite de coder directement les informations de connexion dans l’application.

Les identifiants utilisés pendant les tests locaux ne doivent toutefois pas être réutilisés en production.

## 3.3 Lancement de l’application

Le backend est lancé avec :

```bash
npm run dev
```

Le frontend est lancé avec :

```bash
ng serve
```

Une fois les deux services démarrés :

* Frontend : `http://localhost:4200`
* Backend : `http://localhost:3000`
* MySQL : `localhost:3306`

Le port MySQL n'est pas destiné à être utilisé directement depuis un navigateur.

L’application a été validée comme fonctionnelle avant le passage à l’étape suivante.

---

# 4. Conteneurisation avec Docker

## 4.1 Objectifs

La deuxième étape consiste à transformer les composants de l’application en conteneurs Docker.

La conteneurisation apporte plusieurs avantages :

* environnement reproductible ;
* séparation des composants ;
* déploiement simplifié ;
* indépendance vis-à-vis de l’environnement d’exécution ;
* possibilité de déployer exactement les mêmes images en recette et en production ;
* intégration facilitée dans un pipeline CI/CD.

## 4.2 Dockerfile du frontend

Un `Dockerfile` dédié au frontend permet de définir précisément :

* l’image de base ;
* l’installation des dépendances ;
* la compilation de l’application Angular ;
* le serveur utilisé pour distribuer les fichiers générés.

Le frontend utilise également une configuration Nginx dédiée au routage et à la distribution de l’application.

Le choix de séparer le serveur web du code applicatif permet d'utiliser un conteneur léger et adapté à la distribution de fichiers statiques.

## 4.3 Dockerfile du backend

Le backend possède son propre `Dockerfile`.

Il définit notamment :

* l’image Node.js utilisée ;
* l’installation des dépendances ;
* la copie du code applicatif ;
* l’exposition du port du serveur ;
* la commande de démarrage.

L’objectif est que le backend puisse être exécuté sans dépendre directement de l’environnement présent sur la machine hôte.

## 4.4 `.dockerignore`

Deux fichiers `.dockerignore` ont été ajoutés afin d’éviter d’envoyer inutilement certains fichiers au contexte de build.

Cela permet notamment d’éviter d'inclure :

* `node_modules`
* fichiers temporaires ;
* fichiers de développement ;
* fichiers de configuration sensibles ;
* autres éléments inutiles à l’exécution.

Cette pratique réduit la taille du contexte de build et limite les risques de divulgation de données sensibles.

## 4.5 Docker Compose

Un fichier Docker Compose a été utilisé pour simplifier le lancement de l’environnement conteneurisé.

Il permet de démarrer les différents services avec une configuration commune.

L’architecture devient alors :

```text
                    Docker Compose
┌──────────────────────────────────────────────────┐
│                                                  │
│  ┌─────────────────┐                             │
│  │    Frontend     │                             │
│  │     Angular     │                             │
│  │      Nginx      │                             │
│  └────────┬────────┘                             │
│           │                                      │
│           │ HTTP                                 │
│           ▼                                      │
│  ┌─────────────────┐                             │
│  │     Backend     │                             │
│  │ Node.js/Express │                             │
│  └────────┬────────┘                             │
│           │                                      │
│           │ MySQL                                │
│           ▼                                      │
│  ┌─────────────────┐                             │
│  │      MySQL      │                             │
│  └─────────────────┘                             │
│                                                  │
└──────────────────────────────────────────────────┘
```

Une difficulté rencontrée à ce stade concernait la configuration de la base de données.

Le backend tentait encore de joindre MySQL sur `localhost`.

Dans un environnement Docker, `localhost` désigne le conteneur dans lequel le backend s’exécute et non le conteneur MySQL.

La solution consiste donc à utiliser le nom du service Docker ou Kubernetes comme hôte de connexion à la base de données.

Cette difficulté a permis de mettre en évidence une différence importante entre une architecture exécutée directement sur une machine et une architecture distribuée en conteneurs.

---

# 5. Gestion des images Docker et registre

Une fois les images Docker validées localement, elles sont construites puis publiées dans **GitHub Container Registry (GHCR)**.

Le registre permet de centraliser les images et de rendre celles-ci accessibles aux environnements de déploiement.

Le fonctionnement est le suivant :

```text
Code source
    │
    ▼
Docker build
    │
    ├── Image frontend
    │
    └── Image backend
    │
    ▼
GitHub Container Registry
    │
    ▼
Cluster Kubernetes / AKS
```

Cette approche évite de reconstruire localement les images directement sur les nœuds Kubernetes.

Les images sont construites une fois dans la chaîne CI/CD puis récupérées depuis le registre lors du déploiement.

Une attention particulière doit être portée à la gestion des credentials du registre. Ceux-ci ne doivent jamais être écrits en clair dans le dépôt Git.

Le token GitHub ayant été utilisé lors des premiers tests doit être considéré comme secret et doit être stocké uniquement dans un mécanisme sécurisé tel que les **GitHub Secrets**.

---

# 6. Provisionnement de l’infrastructure Azure avec Terraform

## 6.1 Objectif

L'infrastructure Azure est provisionnée à l'aide de **Terraform**.

L’intérêt principal est de pouvoir décrire l’infrastructure sous forme de code et de rendre son déploiement reproductible.

L’infrastructure est organisée dans le dossier :

```text
iac/
```

Cette organisation permet de séparer le code d’infrastructure du code applicatif.

## 6.2 Azure CLI et Terraform

Les outils nécessaires ont été installés :

* Azure CLI
* Terraform

Azure CLI permet notamment d’interagir avec l’environnement Azure et de s’authentifier.

Terraform est ensuite utilisé pour déclarer les ressources nécessaires.

## 6.3 Cluster AKS

Le fichier principal Terraform `main.tf` permet de déclarer les ressources Azure nécessaires, notamment le cluster Kubernetes **Azure Kubernetes Service (AKS)**.

AKS a été retenu comme solution d’orchestration afin de bénéficier d’un cluster Kubernetes managé par Azure.

Cela évite notamment de gérer soi-même une grande partie de l’infrastructure nécessaire au fonctionnement du cluster.

Le principe est :

```text
Terraform
   │
   ▼
Azure
   │
   └── AKS
        │
        ├── Frontend
        ├── Backend
        ├── Services
        ├── Ingress
        └── Monitoring
```

## 6.4 Base de données

Le projet utilise également un service de base de données Azure / une base MySQL selon l’architecture retenue.

Le choix d’un service de base de données managé présente plusieurs avantages par rapport à l'exécution de MySQL directement dans Kubernetes :

* réduction de la complexité d'exploitation ;
* maintenance simplifiée ;
* séparation de l’application et de la base ;
* meilleure résilience ;
* gestion simplifiée de certains aspects d’infrastructure.

Lorsque la base est exécutée dans Kubernetes, un volume persistant doit obligatoirement être associé au déploiement MySQL afin d’éviter de perdre les données lors du redémarrage ou du remplacement du pod.

## 6.5 Bonnes pratiques Terraform

L’utilisation de Terraform permet de mettre en œuvre une approche Infrastructure as Code.

Le cycle d'utilisation est :

```bash
terraform init
terraform plan
terraform apply
```

`terraform init` initialise le projet et télécharge les providers nécessaires.

`terraform plan` permet de visualiser les modifications qui seraient appliquées.

`terraform apply` applique les changements sur Azure.

Cette séparation est importante car elle permet de détecter les erreurs avant modification réelle de l’infrastructure.

Les fichiers Terraform doivent être versionnés avec le projet, à l’exception des fichiers susceptibles de contenir des secrets ou des données locales.

---

# 7. Déploiement Kubernetes sur AKS

## 7.1 Objectif

Une fois le cluster AKS créé, l’application est déployée avec Kubernetes.

Les ressources Kubernetes sont décrites dans des fichiers YAML versionnés dans le dépôt.

L’objectif est de décrire de manière déclarative l’état souhaité de l’application.

## 7.2 Déploiements

Les composants frontend et backend sont déployés sous forme de `Deployment`.

Le `Deployment` permet notamment :

* de gérer le nombre de réplicas ;
* de remplacer automatiquement les pods défaillants ;
* d'effectuer des mises à jour progressives ;
* de maintenir l’état attendu de l’application.

Pour le backend, plusieurs réplicas peuvent être utilisés afin d’améliorer la disponibilité du service.

Une stratégie `RollingUpdate` peut être utilisée afin de remplacer progressivement les anciennes versions par la nouvelle version sans interrompre totalement le service.

## 7.3 Services Kubernetes

Des ressources `Service` permettent d'exposer les applications dans le cluster.

Le frontend et le backend sont donc séparés des mécanismes de routage externes.

Le service backend permet notamment au frontend ou aux composants autorisés de contacter le backend à travers le réseau Kubernetes sans dépendre d'une adresse IP de pod.

Cela apporte une abstraction importante puisque les pods peuvent être supprimés puis recréés avec de nouvelles adresses IP.

## 7.4 Ingress

Un Ingress est utilisé afin de gérer l’accès HTTP entrant vers les différents composants.

L’Ingress constitue le point d’entrée de l’application depuis l’extérieur du cluster.

Il permet notamment d’organiser le routage HTTP vers les services Kubernetes appropriés.

Architecture simplifiée :

```text
                    Internet
                       │
                       ▼
                    Ingress
                 ┌─────┴─────┐
                 │           │
                 ▼           ▼
             Frontend      Backend
              Service       Service
                 │           │
                 ▼           ▼
              Frontend     Backend
                Pods         Pods
```

## 7.5 ConfigMaps

Les `ConfigMap` permettent de stocker les configurations non sensibles séparément du code.

Cette séparation permet par exemple de modifier certains paramètres de fonctionnement sans modifier directement l’image Docker.

## 7.6 Secrets

Les informations sensibles ne doivent pas être stockées en clair dans les fichiers YAML.

Les credentials nécessaires à l’application ou au registre doivent être transmis via des `Secrets` Kubernetes ou via le mécanisme secret approprié utilisé par la chaîne CI/CD.

Cela constitue une amélioration importante par rapport à l’utilisation d’un identifiant directement écrit dans les sources.

## 7.7 Persistance MySQL

Lorsque MySQL est hébergé dans Kubernetes, les données doivent être associées à un stockage persistant.

Un pod étant éphémère, un stockage uniquement présent dans le système de fichiers du conteneur entraînerait une perte des données lors de la suppression du pod.

L’utilisation d’un `PersistentVolume` / `PersistentVolumeClaim` permet donc de découpler les données du cycle de vie du pod MySQL.

Cette approche garantit que les données peuvent survivre au redémarrage ou au remplacement du conteneur.

---

# 8. Pipeline CI/CD GitHub Actions

## 8.1 Objectif

Un pipeline CI/CD a été mis en place avec **GitHub Actions**.

Les workflows sont stockés dans :

```text
.github/workflows/
```

Le pipeline automatise le processus allant de la validation du code jusqu’au déploiement dans AKS.

L’objectif principal est qu’une version ne soit déployée en production que si les tests automatisés sont réussis.

## 8.2 Étapes du pipeline

Le pipeline suit globalement le processus suivant :

```text
Push / Pull Request
        │
        ▼
Tests unitaires
        │
        ├── Échec → arrêt du pipeline
        │
        ▼
Build Docker
        │
        ▼
Push des images
        │
        ▼
Connexion à Azure
        │
        ▼
Déploiement Kubernetes
        │
        ▼
AKS
```

## 8.3 Tests

La première étape importante est l’exécution des tests unitaires du frontend et du backend.

Ces tests permettent de vérifier automatiquement que les fonctionnalités attendues continuent de fonctionner.

Le pipeline ne doit pas effectuer le déploiement si l’un des tests échoue.

Cela permet d’éviter qu’une modification introduisant une régression soit directement publiée dans l’environnement AKS.

## 8.4 Build des images

Après validation des tests, les images Docker sont construites.

Le frontend et le backend disposent de leurs propres images.

Cette étape garantit que les images utilisées en déploiement correspondent au code ayant passé les tests.

## 8.5 Publication dans GHCR

Une fois construites, les images sont publiées dans GitHub Container Registry.

Les informations d’authentification nécessaires sont stockées sous forme de secrets GitHub et ne doivent pas apparaître dans les fichiers du dépôt.

Le cluster peut ensuite récupérer les images depuis le registre.

## 8.6 Connexion GitHub / Azure

La communication entre GitHub Actions et Azure est configurée à l’aide de **OIDC (OpenID Connect)**.

Cette approche permet à GitHub Actions de s’authentifier auprès d’Azure sans stocker nécessairement un secret permanent contenant directement des credentials Azure dans le dépôt.

Le principe est :

```text
GitHub Actions
      │
      │ OIDC
      ▼
   Azure AD /
 Entra ID
      │
      ▼
    AKS
```

Cette solution améliore la sécurité de la chaîne CI/CD en limitant l’utilisation de secrets statiques.

## 8.7 Déploiement automatique

Le déploiement Kubernetes est effectué après les tests et la construction des images.

Le principe recherché est :

```text
Tests OK
   │
   ▼
Build OK
   │
   ▼
Push registry OK
   │
   ▼
Deploy AKS
```

En cas d’échec d’une étape critique, les étapes suivantes ne doivent pas être exécutées.

Ce fonctionnement garantit une condition essentielle du CI/CD : **pas de déploiement automatique si la validation du code échoue**.

---

# 9. Monitoring avec Prometheus et Grafana

## 9.1 Objectif

Une solution de supervision a été mise en place à l’aide de :

* **Prometheus**
* **Grafana**

L’objectif est de pouvoir observer l’état du cluster et de l’application une fois celle-ci déployée.

La supervision permet notamment de détecter :

* une surcharge CPU ;
* une consommation excessive de mémoire ;
* un nombre important de redémarrages de pods ;
* des problèmes de disponibilité ;
* une dégradation des performances.

## 9.2 Installation

Prometheus et Grafana ont été installés dans le cluster Kubernetes à l’aide de **Helm**.

Helm permet de déployer et gérer plus facilement des applications complexes composées de plusieurs ressources Kubernetes.

Cette solution évite d’avoir à créer manuellement l’ensemble des ressources nécessaires au monitoring.

## 9.3 Prometheus

Prometheus collecte et stocke les métriques exposées par les composants supervisés.

Il constitue donc la couche de collecte et de stockage des métriques.

Les données peuvent ensuite être interrogées afin d’analyser l’état du système.

## 9.4 Grafana

Grafana est utilisé pour visualiser les métriques fournies par Prometheus.

Un dashboard de base a été mis en place afin de surveiller l’environnement Kubernetes.

Exemples de données pertinentes :

* CPU ;
* mémoire ;
* nombre de pods ;
* disponibilité des composants ;
* redémarrages ;
* état des workloads.

Le dashboard permet ainsi d’avoir une vision synthétique de la santé de la plateforme.

## 9.5 Évolution possible : métriques personnalisées

Une amélioration possible consiste à exposer des métriques spécifiques à l’application backend.

Par exemple :

* nombre de requêtes HTTP ;
* temps moyen de réponse ;
* nombre d’erreurs HTTP ;
* nombre de tâches créées ;
* nombre de tâches supprimées.

Cela permettrait de compléter la supervision infrastructure par une supervision réellement orientée métier et applicative.

---

# 10. Sécurité

La sécurité a été prise en compte à plusieurs niveaux.

## 10.1 Gestion des secrets

Les mots de passe, tokens et informations d’authentification ne doivent pas être versionnés dans Git.

Les informations sensibles doivent être stockées dans :

* GitHub Secrets pour les workflows ;
* Kubernetes Secrets pour les applications ;
* ou un service de gestion des secrets adapté à Azure.

## 10.2 Comptes de développement et production

Les credentials utilisés pendant les tests locaux peuvent être simples pour faciliter le développement, mais ils ne doivent pas être conservés en production.

L’utilisation d’un compte MySQL `root` avec un mot de passe simple est donc acceptable uniquement pour un environnement de test isolé et constitue une mauvaise pratique en production.

En production, l’application devrait utiliser un compte MySQL dédié avec uniquement les droits nécessaires.

## 10.3 Principe du moindre privilège

Les différents composants doivent disposer uniquement des permissions nécessaires à leur fonctionnement.

Ce principe s’applique notamment :

* aux comptes Azure ;
* à GitHub Actions ;
* aux accès au registre ;
* aux comptes de base de données ;
* aux services Kubernetes.

---

# 11. Difficultés rencontrées et solutions apportées

## 11.1 Problème de connexion à MySQL avec Docker

### Problème

Lors de la conteneurisation, le backend tentait encore de se connecter à MySQL via `localhost`.

### Cause

Dans Docker, `localhost` désigne le conteneur courant et non l’autre conteneur.

### Solution

La configuration a été adaptée afin d'utiliser le nom réseau du service MySQL.

Cette correction est importante car elle permet au backend de communiquer avec un service externe à son propre conteneur.

### Analyse

Ce problème montre que la migration d’une architecture monolithique exécutée sur une même machine vers une architecture distribuée nécessite d’adapter les mécanismes de communication entre services.

---

# 12. Difficultés liées au déploiement

Le passage d’une application fonctionnelle en local vers Kubernetes ajoute plusieurs niveaux de complexité :

```text
Local
  │
  ▼
Docker
  │
  ▼
Registry
  │
  ▼
Azure
  │
  ▼
Kubernetes
  │
  ▼
Ingress / Services / Secrets / Volumes
```

Chaque étape introduit de nouveaux éléments à configurer.

Une erreur de configuration réseau, de variable d’environnement, d’image Docker ou de credential peut empêcher le déploiement alors que l’application fonctionne correctement localement.

Le projet a donc permis de comprendre qu’un problème de production ne vient pas forcément du code applicatif lui-même : il peut également provenir de l’infrastructure, du réseau, de la configuration ou de la chaîne de déploiement.

---

# 13. Organisation du projet

L’organisation générale du projet repose sur une séparation entre :

```text
/
├── frontend/
│   ├── Dockerfile
│   └── .dockerignore
│
├── backend/
│   ├── Dockerfile
│   └── .dockerignore
│
├── iac/
│   └── Terraform
│
├── k8s/
│   └── Fichiers YAML Kubernetes
│
├── .github/
│   └── workflows/
│       └── Workflows CI/CD
│
├── docker-compose.yml
└── nginx.conf
```

Cette organisation permet de séparer clairement :

* le code applicatif ;
* l’infrastructure ;
* les manifests Kubernetes ;
* le pipeline CI/CD ;
* les fichiers liés à Docker.

Elle facilite également la maintenance et la compréhension du projet.

---

# 14. Choix techniques

## Docker

Docker a été choisi pour standardiser l’environnement d’exécution et faciliter le déploiement.

Chaque composant dispose de son propre conteneur, ce qui permet de limiter le couplage entre les services.

## GitHub Container Registry

GHCR a été choisi pour stocker les images Docker car il est directement intégré à l’écosystème GitHub utilisé par le projet.

Cela facilite l'intégration entre :

* dépôt Git ;
* GitHub Actions ;
* registre d’images ;
* pipeline CI/CD.

## Kubernetes / AKS

Kubernetes a été choisi pour l’orchestration des conteneurs.

AKS permet de bénéficier d’un cluster Kubernetes managé sur Azure et réduit la charge d’administration de l’infrastructure.

## Terraform

Terraform apporte une approche Infrastructure as Code.

L’infrastructure peut ainsi être reconstruite à partir du code plutôt qu’être créée manuellement depuis l’interface Azure.

## GitHub Actions

GitHub Actions permet d’automatiser directement le cycle de livraison depuis le dépôt Git.

La chaîne peut ainsi appliquer automatiquement les tests, construire les images, les publier puis déployer l’application.

## Prometheus / Grafana

Prometheus et Grafana sont complémentaires :

* Prometheus collecte les métriques ;
* Grafana permet de les visualiser et de construire des dashboards.

---

# 15. Processus complet de mise en production

Le processus final peut être résumé ainsi :

```text
                    Développeur
                         │
                         ▼
                    Git push
                         │
                         ▼
                 GitHub Actions
                         │
                         ▼
                ┌────────────────┐
                │ Tests unitaires│
                └───────┬────────┘
                        │
                 Tests réussis
                        │
                        ▼
                 Docker Build
                        │
               ┌────────┴────────┐
               ▼                 ▼
           Frontend            Backend
             Image              Image
               │                 │
               └────────┬────────┘
                        ▼
                 GitHub Container
                     Registry
                        │
                        ▼
                   Auth OIDC
                        │
                        ▼
                     Azure
                        │
                        ▼
                      AKS
                        │
             ┌──────────┼──────────┐
             ▼          ▼          ▼
          Frontend    Backend    MySQL
             │          │          │
             └──────────┴──────────┘
                        │
                        ▼
                  Prometheus
                        │
                        ▼
                    Grafana
```

Ce processus permet de passer du code source au déploiement automatisé tout en conservant plusieurs niveaux de contrôle.

---

# 16. Bilan et analyse critique

Le projet a permis de mettre en œuvre une chaîne DevOps complète allant du développement local à la supervision d’une application déployée dans Kubernetes.

Les principales compétences mises en œuvre sont :

* développement et exécution d’une application Node.js / Angular ;
* administration d’un environnement Linux ;
* conteneurisation Docker ;
* gestion d’images dans un registre ;
* Infrastructure as Code avec Terraform ;
* administration et déploiement Kubernetes ;
* utilisation d’AKS ;
* création de pipelines CI/CD ;
* authentification GitHub/Azure avec OIDC ;
* supervision avec Prometheus et Grafana.

L'un des principaux enseignements du projet est que la mise en production ne consiste pas uniquement à faire fonctionner l’application.

Il faut également garantir :

* la reproductibilité de l’environnement ;
* la disponibilité ;
* la persistance des données ;
* la sécurité des secrets ;
* l’automatisation du déploiement ;
* la capacité à surveiller la plateforme ;
* la possibilité d’identifier et corriger rapidement les incidents.

L’architecture pourrait encore être améliorée sur plusieurs points : utilisation systématique d’images Docker minimales et non exécutées avec des privilèges élevés, gestion avancée des secrets avec Azure Key Vault, ajout de probes Kubernetes (`livenessProbe` et `readinessProbe`), mise en place de métriques applicatives personnalisées, gestion d’un environnement de staging et ajout de contrôles de sécurité automatisés dans le pipeline.

Ces évolutions permettraient de rapprocher davantage le projet d’une architecture utilisée dans un contexte professionnel.

---

# 17. Conclusion

Le projet répond à une démarche DevOps complète.

L’application a d’abord été validée localement, puis conteneurisée avec Docker. Les images sont stockées dans GitHub Container Registry afin de pouvoir être réutilisées par l’environnement de déploiement.

L’infrastructure Azure est décrite avec Terraform, ce qui rend sa création reproductible et versionnable.

L’application est ensuite déployée sur AKS grâce à Kubernetes, avec des ressources permettant de gérer les déploiements, les services, le routage HTTP, la configuration, les secrets et la persistance.

Le pipeline GitHub Actions automatise la validation du code, la construction des images, leur publication et le déploiement sur AKS. L’utilisation d’OIDC renforce la sécurité de la connexion entre GitHub et Azure.

Enfin, Prometheus et Grafana permettent de superviser l’environnement et de suivre son état à l’aide de tableaux de bord.

L’ensemble forme une chaîne cohérente :

**Code → Tests → Docker → Registry → Azure/AKS → Kubernetes → Monitoring**

Cette architecture permet d’obtenir une solution plus reproductible, automatisée, observable et maintenable qu’un déploiement manuel traditionnel.
