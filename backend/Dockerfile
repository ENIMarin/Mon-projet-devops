
# Utilisatation d'une image légère alpine 
FROM node:22-alpine

# On se place dans le dossier /app du conteneur
WORKDIR /app

# On copie uniquement les fichiers de gestion des dépendances
COPY package*.json ./

# Installation propre des dépendances
RUN npm ci

# On copie tout le reste du code source
COPY . .

# On expose le port sur lequel ton backend écoute
EXPOSE 3000

# On démarre notre application
CMD ["npm", "start"]