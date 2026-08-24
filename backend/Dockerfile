
# Utilisation d'une image Node.js légère (la même version que ton front pour être cohérent)
FROM node:22-alpine

# On se place dans le dossier /app du conteneur
WORKDIR /app

# On copie uniquement les fichiers de gestion des dépendances
COPY package*.json ./

# Installation propre des dépendances
RUN npm ci

# On copie tout le reste du code source
COPY . .

# ATTENTION : Si ton projet utilise Babel pour compiler le code avant de le lancer,
# décommente la ligne suivante (si tu as un script "build" dans ton package.json)
# RUN npm run build

# On expose le port sur lequel ton backend écoute (souvent 3000 en Node.js)
EXPOSE 3000

# Commande pour démarrer l'application (vérifie que "start" est bien défini dans ton package.json)
CMD ["npm", "start"]