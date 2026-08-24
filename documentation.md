Documentation Projet : 

Première étape test du projet en local sur le poste : 

Installation : 
Node 
Mysql 
Angular CLI 
Les dépendances des projets Backend et Frontend

Création de la base de donnée à l'aide du script fourni dans le Backend

Changement du .env pour mettre le compte souhaité pour le test root / root 

Lancement du Backend : npm run dev 
Lancement du Frontend : ng serve

┌──────────────────────────────────────────────┐
│                 VM Ubuntu                    │
│                                              │
│  Node.js 22.23.2                             │
│  npm 10.9.8                                  │
│  NVM                                         │
│  MySQL Server                                │
│                                              │
│  ┌─────────────────┐                         │
│  │    Frontend     │                         │
│  │     Angular     │                         │
│  │  localhost:4200 │                         │
│  └────────┬────────┘                         │
│           │                                  │
│           │ HTTP                             │
│           ▼                                  │
│  ┌─────────────────┐                         │
│  │     Backend     │                         │
│  │ Node.js/Express │                         │
│  │  localhost:3000 │                         │
│  └────────┬────────┘                         │
│           │                                  │
│           │ Sequelize / mysql2               │
│           ▼                                  │
│  ┌─────────────────┐                         │
│  │      MySQL      │                         │
│  │  localhost:3306 │                         │
│  │                 │                         │
│  │   todolist_db   │                         │
│  │      └─ tasks   │                         │
│  └─────────────────┘                         │
└──────────────────────────────────────────────┘



Port utilisé par le Backend : http://localhost:3000
Port utilisé par le Frontend : http://localhost:4200
Port utilisé par MySql : http://localhost:3306 (Pas accesible depuis le navigateur)

L'application est fonctionnelle



Deuxième étape : Mise en place du Docker

Installation: 

Docker

- Création de deux Dockerfile [Frontend et Backend]
- Création d'un DockerCompose
- Création d'un nginx.conf
- Création de deux dockerignore [Frontend et Backend]




