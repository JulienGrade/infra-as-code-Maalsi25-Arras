<h1>ATELIER 2 – Stack locale “catalogue API” (OpenTofu + Docker)</h1>

<h2>Objectif</h2>
<p>
Déployer en local une stack Docker pilotée par OpenTofu :
</p>
<ul>
  <li>un réseau Docker dédié</li>
  <li>PostgreSQL avec volume persistant</li>
  <li>Redis</li>
  <li>une API Node/Express buildée localement (dossier <code>api/</code>)</li>
</ul>

<h2>Structure attendue</h2>
<p>Crée un nouveau dossier de TP avec cette structure :</p>
<code>
tp-02-catalogue/<br/>
&nbsp;&nbsp;main.tf<br/>
&nbsp;&nbsp;api/<br/>
&nbsp;&nbsp;&nbsp;&nbsp;Dockerfile<br/>
&nbsp;&nbsp;&nbsp;&nbsp;package.json<br/>
&nbsp;&nbsp;&nbsp;&nbsp;index.js<br/>
</code>

<hr/>

<h2>Étape 1 — Prérequis</h2>

<h3>1.1 Docker doit fonctionner</h3>
<code>docker ps</code>
<p>
Si tu vois une liste (même vide), Docker fonctionne.
</p>
<p><strong>Mac / Windows :</strong> vérifie que Docker Desktop est bien démarré.</p>

<h3>1.2 OpenTofu doit être installé</h3>
<code>tofu version</code>

<p>Validation attendue :</p>
<ul>
  <li><code>docker ps</code> fonctionne</li>
  <li><code>tofu version</code> affiche une version</li>
</ul>

<hr/>

<h2>Étape 2 — Créer le main.tf (portable Mac / Windows / Linux)</h2>
<p>
Dans <code>main.tf</code>, utilise le provider Docker sans hardcoder de socket.
Cela rend le TP partageable entre plusieurs développeurs et plusieurs OS.
</p>

<code>
terraform {<br/>
&nbsp;&nbsp;required_providers {<br/>
&nbsp;&nbsp;&nbsp;&nbsp;docker = {<br/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;source  = "kreuzwerker/docker"<br/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;version = "~&gt; 3.0"<br/>
&nbsp;&nbsp;&nbsp;&nbsp;}<br/>
&nbsp;&nbsp;}<br/>
}<br/><br/>
provider "docker" {}<br/>
</code>

<h3>Note de compatibilité (au cas où Docker Desktop n’est pas détecté automatiquement)</h3>
<p>
Si <code>tofu plan</code> ou <code>tofu apply</code> échoue avec un message de connexion Docker,
définis la variable d’environnement <code>DOCKER_HOST</code> puis relance la commande.
</p>

<h4>Mac / Linux (shell)</h4>
<code>
export DOCKER_HOST="$(docker context inspect --format '{{.Endpoints.docker.Host}}')" <br/>
</code>

<h4>Windows PowerShell</h4>
<code>
$env:DOCKER_HOST = (docker context inspect --format '{{.Endpoints.docker.Host}}')<br/>
</code>

<h4>Windows CMD</h4>
<code>
for /f "delims=" %i in ('docker context inspect --format "{{.Endpoints.docker.Host}}"') do set DOCKER_HOST=%i
</code>

<hr/>

<h2>Étape 3 — Déclarer le réseau Docker</h2>
<p>
PostgreSQL, Redis et l’API doivent être sur le même réseau Docker dédié.
</p>

<code>
resource "docker_network" "catalogue_net" {<br/>
&nbsp;&nbsp;name = "catalogue-net"<br/>
}<br/>
</code>

<hr/>

<h2>Étape 4 — Initialiser OpenTofu</h2>
<p>Dans le dossier du TP :</p>
<code>tofu init</code>

<p>Validation attendue : installation du provider <code>kreuzwerker/docker</code> et message de succès.</p>

<hr/>

<h2>Étape 5 — Ajouter PostgreSQL (volume + conteneur)</h2>
<p>Objectifs :</p>
<ol>
  <li>Créer un volume persistant pour les données</li>
  <li>Lancer PostgreSQL sur le réseau <code>catalogue-net</code></li>
  <li>Exposer le port <code>5432</code> en local</li>
</ol>

<code>
resource "docker_volume" "pg_data" {<br/>
&nbsp;&nbsp;name = "catalogue-pg-data"<br/>
}<br/><br/>

resource "docker_container" "postgres" {<br/>
&nbsp;&nbsp;name  = "catalogue-postgres"<br/>
&nbsp;&nbsp;image = "postgres:15-alpine"<br/><br/>

&nbsp;&nbsp;env = [<br/>
&nbsp;&nbsp;&nbsp;&nbsp;"POSTGRES_USER=catalogue",<br/>
&nbsp;&nbsp;&nbsp;&nbsp;"POSTGRES_PASSWORD=catalogue",<br/>
&nbsp;&nbsp;&nbsp;&nbsp;"POSTGRES_DB=catalogue",<br/>
&nbsp;&nbsp;]<br/><br/>

&nbsp;&nbsp;networks_advanced {<br/>
&nbsp;&nbsp;&nbsp;&nbsp;name = docker_network.catalogue_net.name<br/>
&nbsp;&nbsp;}<br/><br/>

&nbsp;&nbsp;mounts {<br/>
&nbsp;&nbsp;&nbsp;&nbsp;target = "/var/lib/postgresql/data"<br/>
&nbsp;&nbsp;&nbsp;&nbsp;source = docker_volume.pg_data.name<br/>
&nbsp;&nbsp;&nbsp;&nbsp;type   = "volume"<br/>
&nbsp;&nbsp;}<br/><br/>

&nbsp;&nbsp;ports {<br/>
&nbsp;&nbsp;&nbsp;&nbsp;internal = 5432<br/>
&nbsp;&nbsp;&nbsp;&nbsp;external = 5432<br/>
&nbsp;&nbsp;}<br/>
}<br/>
</code>

<hr/>

<h2>Étape 6 — Vérifier le plan</h2>
<code>tofu plan</code>

<p>À ce stade, tu dois avoir 3 ressources à créer :</p>
<ul>
  <li>1 réseau</li>
  <li>1 volume</li>
  <li>1 conteneur PostgreSQL</li>
</ul>

<p>Sortie attendue :</p>
<code>Plan: 3 to add, 0 to change, 0 to destroy.</code>

<h2>Étape 7 — Appliquer</h2>
<code>tofu apply</code>
<p>Répondre <code>yes</code> à la confirmation.</p>

<h2>Étape 8 — Vérifier côté Docker</h2>
<code>docker ps</code>
<p>Tu dois voir <code>catalogue-postgres</code> exposé sur <code>0.0.0.0:5432-&gt;5432/tcp</code>.</p>

<hr/>

<h2>Étape 9 — Ajouter Redis</h2>
<p>Ajoute après PostgreSQL :</p>

<code>
resource "docker_container" "redis" {<br/>
&nbsp;&nbsp;name  = "catalogue-redis"<br/>
&nbsp;&nbsp;image = "redis:7-alpine"<br/><br/>

&nbsp;&nbsp;networks_advanced {<br/>
&nbsp;&nbsp;&nbsp;&nbsp;name = docker_network.catalogue_net.name<br/>
&nbsp;&nbsp;}<br/><br/>

&nbsp;&nbsp;ports {<br/>
&nbsp;&nbsp;&nbsp;&nbsp;internal = 6379<br/>
&nbsp;&nbsp;&nbsp;&nbsp;external = 6379<br/>
&nbsp;&nbsp;}<br/>
}<br/>
</code>

<h2>Étape 10 — Replanifier</h2>
<code>tofu plan</code>

<p>Sortie attendue :</p>
<code>Plan: 4 to add, 0 to change, 0 to destroy.</code>

<h2>Étape 11 — Appliquer</h2>
<code>tofu apply</code>
<p>Puis <code>yes</code>.</p>

<h2>Étape 12 — Vérifier côté Docker</h2>
<code>docker ps</code>
<p>Tu dois voir :</p>
<ul>
  <li><code>catalogue-postgres</code> (5432 → 5432)</li>
  <li><code>catalogue-redis</code> (6379 → 6379)</li>
</ul>

<hr/>

<h2>Étape 13 — Préparer le code de l’API</h2>

<h3>Dockerfile (dans <code>api/Dockerfile</code>)</h3>
<code>
FROM node:22-alpine<br/>
WORKDIR /app<br/>
COPY package*.json ./<br/>
RUN npm install --omit=dev<br/>
COPY . .<br/>
EXPOSE 3000<br/>
CMD ["npm", "start"]<br/>
</code>

<h3>package.json (dans <code>api/package.json</code>)</h3>
<code>
{<br/>
&nbsp;&nbsp;"name": "catalogue-api",<br/>
&nbsp;&nbsp;"version": "1.0.0",<br/>
&nbsp;&nbsp;"main": "index.js",<br/>
&nbsp;&nbsp;"type": "module",<br/>
&nbsp;&nbsp;"scripts": {<br/>
&nbsp;&nbsp;&nbsp;&nbsp;"start": "node index.js"<br/>
&nbsp;&nbsp;},<br/>
&nbsp;&nbsp;"dependencies": {<br/>
&nbsp;&nbsp;&nbsp;&nbsp;"express": "^4.19.2",<br/>
&nbsp;&nbsp;&nbsp;&nbsp;"pg": "^8.12.0",<br/>
&nbsp;&nbsp;&nbsp;&nbsp;"ioredis": "^5.4.1"<br/>
&nbsp;&nbsp;}<br/>
}<br/>
</code>

<h3>index.js (dans <code>api/index.js</code>)</h3>
<code>
import express from "express";<br/><br/>

const app = express();<br/>
const port = process.env.PORT || 3000;<br/><br/>

app.get("/", (req, res) =&gt; {<br/>
&nbsp;&nbsp;res.json({<br/>
&nbsp;&nbsp;&nbsp;&nbsp;status: "ok",<br/>
&nbsp;&nbsp;&nbsp;&nbsp;message: "Catalogue API",<br/>
&nbsp;&nbsp;&nbsp;&nbsp;postgres: {<br/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;host: process.env.PGHOST,<br/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;db: process.env.PGDATABASE,<br/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;user: process.env.PGUSER<br/>
&nbsp;&nbsp;&nbsp;&nbsp;},<br/>
&nbsp;&nbsp;&nbsp;&nbsp;redis: {<br/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;host: process.env.REDIS_HOST<br/>
&nbsp;&nbsp;&nbsp;&nbsp;}<br/>
&nbsp;&nbsp;});<br/>
});<br/><br/>

app.listen(port, () =&gt; {<br/>
&nbsp;&nbsp;console.log(`API catalogue démarrée sur le port ${port}`);<br/>
});<br/>
</code>

<hr/>

<h2>Étape 14 — Dire à OpenTofu de builder l’image API</h2>
<p>Ajoute après Redis :</p>

<code>
resource "docker_image" "catalogue_api" {<br/>
&nbsp;&nbsp;name = "catalogue-api:latest"<br/><br/>

&nbsp;&nbsp;build {<br/>
&nbsp;&nbsp;&nbsp;&nbsp;context = "${path.module}/api"<br/>
&nbsp;&nbsp;}<br/>
}<br/>
</code>

<hr/>

<h2>Étape 15 — Lancer le conteneur API</h2>
<p>Ajoute après l’image :</p>

<code>
resource "docker_container" "catalogue_api" {<br/>
&nbsp;&nbsp;name  = "catalogue-api"<br/>
&nbsp;&nbsp;image = docker_image.catalogue_api.image_id<br/><br/>

&nbsp;&nbsp;networks_advanced {<br/>
&nbsp;&nbsp;&nbsp;&nbsp;name = docker_network.catalogue_net.name<br/>
&nbsp;&nbsp;}<br/><br/>

&nbsp;&nbsp;ports {<br/>
&nbsp;&nbsp;&nbsp;&nbsp;internal = 3000<br/>
&nbsp;&nbsp;&nbsp;&nbsp;external = 3000<br/>
&nbsp;&nbsp;}<br/><br/>

&nbsp;&nbsp;env = [<br/>
&nbsp;&nbsp;&nbsp;&nbsp;"PORT=3000",<br/>
&nbsp;&nbsp;&nbsp;&nbsp;"PGHOST=catalogue-postgres",<br/>
&nbsp;&nbsp;&nbsp;&nbsp;"PGUSER=catalogue",<br/>
&nbsp;&nbsp;&nbsp;&nbsp;"PGPASSWORD=catalogue",<br/>
&nbsp;&nbsp;&nbsp;&nbsp;"PGDATABASE=catalogue",<br/>
&nbsp;&nbsp;&nbsp;&nbsp;"REDIS_HOST=catalogue-redis",<br/>
&nbsp;&nbsp;&nbsp;&nbsp;"REDIS_PORT=6379"<br/>
&nbsp;&nbsp;]<br/><br/>

&nbsp;&nbsp;depends_on = [<br/>
&nbsp;&nbsp;&nbsp;&nbsp;docker_container.postgres,<br/>
&nbsp;&nbsp;&nbsp;&nbsp;docker_container.redis<br/>
&nbsp;&nbsp;]<br/>
}<br/>
</code>

<hr/>

<h2>Étape 16 — Plan final</h2>
<code>tofu plan</code>

<p>À ce stade, on a 6 ressources :</p>
<ul>
  <li>1 réseau</li>
  <li>1 volume</li>
  <li>3 conteneurs (postgres, redis, api)</li>
  <li>1 image buildée (catalogue-api)</li>
</ul>

<p>Sortie attendue :</p>
<code>Plan: 6 to add, 0 to change, 0 to destroy.</code>

<h2>Étape 17 — Appliquer</h2>
<code>tofu apply</code>
<p>Puis <code>yes</code>.</p>

<h2>Étape 18 — Vérifier</h2>
<code>docker ps</code>
<p>Tu dois voir :</p>
<ul>
  <li><code>catalogue-postgres</code></li>
  <li><code>catalogue-redis</code></li>
  <li><code>catalogue-api</code> (3000 → 3000)</li>
</ul>

<p>Test navigateur :</p>
<a href="http://localhost:3000">http://localhost:3000</a>

<p>JSON attendu :</p>
<code>
{<br/>
&nbsp;&nbsp;"status": "ok",<br/>
&nbsp;&nbsp;"message": "Catalogue API",<br/>
&nbsp;&nbsp;"postgres": {<br/>
&nbsp;&nbsp;&nbsp;&nbsp;"host": "catalogue-postgres",<br/>
&nbsp;&nbsp;&nbsp;&nbsp;"db": "catalogue",<br/>
&nbsp;&nbsp;&nbsp;&nbsp;"user": "catalogue"<br/>
&nbsp;&nbsp;},<br/>
&nbsp;&nbsp;"redis": {<br/>
&nbsp;&nbsp;&nbsp;&nbsp;"host": "catalogue-redis"<br/>
&nbsp;&nbsp;}<br/>
}<br/>
</code>

<hr/>

<h2>Étape 19 — Nettoyage</h2>
<code>tofu destroy</code>
<p>Puis <code>yes</code>.</p>

<p>Validation attendue :</p>
<code>Destroy complete! Resources: 6 destroyed.</code>

<p>Vérifie :</p>
<code>docker ps</code>
<p>Tu ne dois plus voir de conteneurs <code>catalogue-*</code>.</p>

<hr/>

<h2>Dépannage</h2>

<ul>
  <li>
    <strong>port is already allocated</strong> (5432 / 6379 / 3000) :
    change <code>external</code> (ex: 5433, 6380, 3001) puis relance <code>tofu apply</code>.
  </li>
  <li>
    <strong>Cannot connect to the Docker daemon</strong> :
    lance Docker Desktop, vérifie <code>docker info</code>, puis relance <code>tofu plan</code>.
  </li>
  <li>
    <strong>Docker Desktop détecté mais OpenTofu n’arrive pas à se connecter</strong> :
    définis <code>DOCKER_HOST</code> (voir l’étape 2) puis relance <code>tofu plan</code>/<code>tofu apply</code>.
  </li>
  <li>
    <strong>L’image API ne build pas</strong> :
    vérifie que <code>api/</code> est au même niveau que <code>main.tf</code>, que le fichier s’appelle <code>Dockerfile</code>, puis relance <code>tofu apply</code>.
  </li>
</ul>
