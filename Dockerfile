# Étape 1 : Utiliser une image de base NGINX officielle
FROM nginx:alpine

# Étape 2 : Copier les fichiers de l'application dans le dossier de contenu web de NGINX
COPY . /usr/share/nginx/html




# Étape 3 : Exposer le port 80 pour accéder au serveur NGINX
EXPOSE 80

# Étape 4 : Commande par défaut pour démarrer NGINX
CMD ["nginx", "-g", "daemon off;"]
