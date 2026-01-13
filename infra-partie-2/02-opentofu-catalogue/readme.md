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

<hr/>

<h2>Sources utilisées</h2>
<p>
Les choix techniques (ports, variables d’environnement, images, build d’image via OpenTofu, réseau Docker, DOCKER_HOST)
sont basés sur les documentations officielles ci-dessous.
</p>

<h3>Références</h3>
<ul>
  <li><strong>[S1]</strong> Installation OpenTofu (documentation officielle)</li>
  <li><strong>[S2]</strong> Provider Docker (<code>kreuzwerker/docker</code>) – documentation (Terraform Registry)</li>
  <li><strong>[S3]</strong> Ressource <code>docker_container</code> – documentation (Terraform Registry)</li>
  <li><strong>[S4]</strong> Ressource <code>docker_image</code> (pull et build) – documentation (Terraform Registry)</li>
  <li><strong>[S5]</strong> PostgreSQL Docker Official Image – variables <code>POSTGRES_*</code> (Docker Hub)</li>
  <li><strong>[S6]</strong> Redis Open Source sur Docker – port par défaut 6379 / mapping <code>-p 6379:6379</code> (redis.io)</li>
  <li><strong>[S7]</strong> Node.js Docker Official Image (Docker Hub)</li>
  <li><strong>[S8]</strong> Docker contexts (documentation Docker)</li>
  <li><strong>[S9]</strong> DOCKER_HOST et context (documentation Docker)</li>
</ul>

<p>Liens (copiables) :</p>
<pre><code>[S1] https://opentofu.org/docs/intro/install/
[S2] https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs
[S3] https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs/resources/container
[S4] https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs/resources/image
[S5] https://hub.docker.com/_/postgres
[S6] https://redis.io/docs/latest/operate/oss_and_stack/install/install-stack/docker/
[S7] https://hub.docker.com/_/node
[S8] https://docs.docker.com/engine/manage-resources/contexts/
[S9] https://docs.docker.com/engine/security/protect-access/
</code></pre>

<hr/>

<h2>Structure attendue</h2>
<p>Créer un nouveau dossier de TP avec cette structure :</p>
<pre><code>tp-02-catalogue/
  main.tf
  api/
    Dockerfile
    package.json
    index.js
</code></pre>

<hr/>

<h2>Étape 1 — Prérequis</h2>

<h3>1.1 Docker doit fonctionner</h3>
<pre><code>docker ps</code></pre>
<p>
Si la commande répond sans erreur (même avec une liste vide), Docker fonctionne.
</p>
<p>
Sur macOS/Windows, vérifier que Docker Desktop est démarré.
</p>

<h3>1.2 OpenTofu doit être installé</h3>
<pre><code>tofu version</code></pre>
<p>
Les méthodes d’installation officielles sont documentées par OpenTofu [S1].
</p>

<p>Validation attendue :</p>
<ul>
  <li><code>docker ps</code> fonctionne</li>
  <li><code>tofu version</code> affiche une version</li>
</ul>

<hr/>

<h2>Étape 2 — Créer le main.tf (portable Mac / Windows / Linux)</h2>
<p>
Dans <code>main.tf</code>, on déclare le provider Docker via <code>required_providers</code>.
Le provider <code>kreuzwerker/docker</code> est documenté sur le registry officiel [S2].
</p>

<pre><code>terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~&gt; 3.0"
    }
  }
}

provider "docker" {}
</code></pre>

<p>
Pourquoi ne pas “hardcoder” un socket ? Pour rester portable : la configuration par défaut du provider
s’appuie sur la configuration Docker locale (context/endpoint) [S2][S8].
</p>

<h3>Note de compatibilité (si Docker Desktop n’est pas détecté automatiquement)</h3>
<p>
Si <code>tofu plan</code> ou <code>tofu apply</code> échoue avec une erreur de connexion au daemon Docker, on peut forcer
temporairement la cible du client Docker via <code>DOCKER_HOST</code>. Docker documente le lien entre contexts et
DOCKER_HOST (DOCKER_HOST peut surcharger le context actif) [S8][S9].
</p>

<h4>Mac / Linux (shell)</h4>
<pre><code>export DOCKER_HOST="$(docker context inspect --format '{{.Endpoints.docker.Host}}')"</code></pre>

<h4>Windows PowerShell</h4>
<pre><code>$env:DOCKER_HOST = (docker context inspect --format '{{.Endpoints.docker.Host}}')</code></pre>

<h4>Windows CMD</h4>
<pre><code>for /f "delims=" %i in ('docker context inspect --format "{{.Endpoints.docker.Host}}"') do set DOCKER_HOST=%i</code></pre>

<hr/>

<h2>Étape 3 — Déclarer le réseau Docker</h2>
<p>
PostgreSQL, Redis et l’API doivent être sur le même réseau Docker dédié.
La ressource réseau du provider Docker est décrite dans la documentation du provider [S2].
</p>

<pre><code>resource "docker_network" "catalogue_net" {
  name = "catalogue-net"
}
</code></pre>

<hr/>

<h2>Étape 4 — Initialiser OpenTofu</h2>
<p>Dans le dossier du TP :</p>
<pre><code>tofu init</code></pre>

<p>
Cette commande télécharge le provider Docker défini dans <code>required_providers</code> [S2].
</p>

<hr/>

<h2>Étape 5 — Ajouter PostgreSQL (volume + conteneur)</h2>
<p>Objectifs :</p>
<ol>
  <li>Créer un volume persistant pour les données</li>
  <li>Lancer PostgreSQL sur le réseau <code>catalogue-net</code></li>
  <li>Exposer le port <code>5432</code> en local</li>
</ol>

<p>
Les variables <code>POSTGRES_USER</code>, <code>POSTGRES_PASSWORD</code> et <code>POSTGRES_DB</code> sont celles
documentées par l’image officielle PostgreSQL [S5]. Le port <code>5432</code> est le port standard PostgreSQL.
</p>

<pre><code>resource "docker_volume" "pg_data" {
  name = "catalogue-pg-data"
}

resource "docker_container" "postgres" {
  name  = "catalogue-postgres"
  image = "postgres:15-alpine"

  env = [
    "POSTGRES_USER=catalogue",
    "POSTGRES_PASSWORD=catalogue",
    "POSTGRES_DB=catalogue",
  ]

  networks_advanced {
    name = docker_network.catalogue_net.name
  }

  mounts {
    target = "/var/lib/postgresql/data"
    source = docker_volume.pg_data.name
    type   = "volume"
  }

  ports {
    internal = 5432
    external = 5432
  }
}
</code></pre>

<p>
Les blocs <code>networks_advanced</code>, <code>mounts</code> et <code>ports</code> sont ceux fournis par la ressource
<code>docker_container</code> du provider [S3].
</p>

<hr/>

<h2>Étape 6 — Vérifier le plan</h2>
<pre><code>tofu plan</code></pre>

<p>À ce stade, on doit créer :</p>
<ul>
  <li>1 réseau</li>
  <li>1 volume</li>
  <li>1 conteneur PostgreSQL</li>
</ul>

<p>Sortie attendue :</p>
<pre><code>Plan: 3 to add, 0 to change, 0 to destroy.</code></pre>

<hr/>

<h2>Étape 7 — Appliquer</h2>
<pre><code>tofu apply</code></pre>
<p>Répondre <code>yes</code> à la confirmation.</p>

<hr/>

<h2>Étape 8 — Vérifier côté Docker</h2>
<pre><code>docker ps</code></pre>
<p>
Tu dois voir <code>catalogue-postgres</code> exposé sur <code>0.0.0.0:5432-&gt;5432/tcp</code>.
La publication de port correspond au principe “host:container” du mapping Docker, reflété ici via le bloc <code>ports</code> [S3].
</p>

<hr/>

<h2>Étape 9 — Ajouter Redis</h2>

<p>
Redis utilise classiquement le port <code>6379</code>. La documentation Redis pour Docker donne l’exemple
de lancement avec <code>-p 6379:6379</code> [S6]. On reproduit ce mapping via le bloc <code>ports</code> [S3].
</p>

<pre><code>resource "docker_container" "redis" {
  name  = "catalogue-redis"
  image = "redis:7-alpine"

  networks_advanced {
    name = docker_network.catalogue_net.name
  }

  ports {
    internal = 6379
    external = 6379
  }
}
</code></pre>

<hr/>

<h2>Étape 10 — Replanifier</h2>
<pre><code>tofu plan</code></pre>

<p>Sortie attendue :</p>
<pre><code>Plan: 4 to add, 0 to change, 0 to destroy.</code></pre>

<hr/>

<h2>Étape 11 — Appliquer</h2>
<pre><code>tofu apply</code></pre>
<p>Puis <code>yes</code>.</p>

<hr/>

<h2>Étape 12 — Vérifier côté Docker</h2>
<pre><code>docker ps</code></pre>
<p>Tu dois voir :</p>
<ul>
  <li><code>catalogue-postgres</code> (5432 → 5432)</li>
  <li><code>catalogue-redis</code> (6379 → 6379)</li>
</ul>

<hr/>

<h2>Étape 13 — Préparer le code de l’API</h2>

<h3>Dockerfile (dans <code>api/Dockerfile</code>)</h3>
<p>
L’image <code>node:22-alpine</code> correspond à l’image officielle Node.js, disponible sur Docker Hub [S7].
Le pattern Dockerfile (WORKDIR, COPY, RUN npm install, EXPOSE, CMD) est cohérent avec les recommandations
générales de l’image officielle (variants, usage) [S7].
</p>

<pre><code>FROM node:22-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install --omit=dev
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
</code></pre>

<h3>package.json (dans <code>api/package.json</code>)</h3>
<p>
Ce fichier définit une API Express minimale, avec un driver PostgreSQL (<code>pg</code>) et un client Redis (<code>ioredis</code>).
</p>

<pre><code>{
  "name": "catalogue-api",
  "version": "1.0.0",
  "main": "index.js",
  "type": "module",
  "scripts": {
    "start": "node index.js"
  },
  "dependencies": {
    "express": "^4.19.2",
    "pg": "^8.12.0",
    "ioredis": "^5.4.1"
  }
}
</code></pre>

<h3>index.js (dans <code>api/index.js</code>)</h3>
<p>
L’API expose un endpoint <code>/</code> renvoyant un JSON de statut et les variables d’environnement attendues.
L’objectif est de vérifier que l’API est correctement configurée dans le conteneur (variables PG/Redis).
</p>

<pre><code>import express from "express";

const app = express();
const port = process.env.PORT || 3000;

app.get("/", (req, res) =&gt; {
  res.json({
    status: "ok",
    message: "Catalogue API",
    postgres: {
      host: process.env.PGHOST,
      db: process.env.PGDATABASE,
      user: process.env.PGUSER
    },
    redis: {
      host: process.env.REDIS_HOST
    }
  });
});

app.listen(port, () =&gt; {
  console.log(`API catalogue démarrée sur le port ${port}`);
});
</code></pre>

<hr/>

<h2>Étape 14 — Dire à OpenTofu de builder l’image API</h2>
<p>
La ressource <code>docker_image</code> permet de construire une image locale via un bloc <code>build</code> (context).
Ce mécanisme est documenté par le provider Docker [S4].
</p>

<pre><code>resource "docker_image" "catalogue_api" {
  name = "catalogue-api:latest"

  build {
    context = "${path.module}/api"
  }
}
</code></pre>

<hr/>

<h2>Étape 15 — Lancer le conteneur API</h2>
<p>
Le conteneur API :
</p>
<ul>
  <li>est attaché au réseau <code>catalogue-net</code> via <code>networks_advanced</code> [S3]</li>
  <li>publie le port <code>3000</code> sur l’hôte pour accéder à l’API [S3]</li>
  <li>reçoit les variables d’environnement nécessaires pour joindre PostgreSQL et Redis</li>
  <li>dépend de PostgreSQL et Redis via <code>depends_on</code> afin de limiter les erreurs de démarrage</li>
</ul>

<pre><code>resource "docker_container" "catalogue_api" {
  name  = "catalogue-api"
  image = docker_image.catalogue_api.image_id

  networks_advanced {
    name = docker_network.catalogue_net.name
  }

  ports {
    internal = 3000
    external = 3000
  }

  env = [
    "PORT=3000",
    "PGHOST=catalogue-postgres",
    "PGUSER=catalogue",
    "PGPASSWORD=catalogue",
    "PGDATABASE=catalogue",
    "REDIS_HOST=catalogue-redis",
    "REDIS_PORT=6379"
  ]

  depends_on = [
    docker_container.postgres,
    docker_container.redis
  ]
}
</code></pre>

<p>
Les noms <code>catalogue-postgres</code> et <code>catalogue-redis</code> servent de DNS Docker sur le réseau dédié.
Ce principe correspond au fonctionnement standard de communication inter-conteneurs au sein d’un même réseau,
utilisé ici via le provider Docker (réseau + attachement) [S2][S3].
</p>

<hr/>

<h2>Étape 16 — Plan final</h2>
<pre><code>tofu plan</code></pre>

<p>À ce stade, on a 6 ressources :</p>
<ul>
  <li>1 réseau</li>
  <li>1 volume</li>
  <li>3 conteneurs (postgres, redis, api)</li>
  <li>1 image buildée (catalogue-api)</li>
</ul>

<p>Sortie attendue :</p>
<pre><code>Plan: 6 to add, 0 to change, 0 to destroy.</code></pre>

<hr/>

<h2>Étape 17 — Appliquer</h2>
<pre><code>tofu apply</code></pre>
<p>Puis <code>yes</code>.</p>

<hr/>

<h2>Étape 18 — Vérifier</h2>

<h3>18.1 Vérifier les conteneurs</h3>
<pre><code>docker ps</code></pre>

<p>Tu dois voir :</p>
<ul>
  <li><code>catalogue-postgres</code></li>
  <li><code>catalogue-redis</code></li>
  <li><code>catalogue-api</code> (3000 → 3000)</li>
</ul>

<h3>18.2 Tester l’API</h3>
<p>Test navigateur :</p>
<pre><code>http://localhost:3000</code></pre>

<p>JSON attendu :</p>
<pre><code>{
  "status": "ok",
  "message": "Catalogue API",
  "postgres": {
    "host": "catalogue-postgres",
    "db": "catalogue",
    "user": "catalogue"
  },
  "redis": {
    "host": "catalogue-redis"
  }
}</code></pre>

<hr/>

<h2>Étape 19 — Nettoyage</h2>
<pre><code>tofu destroy</code></pre>
<p>Puis <code>yes</code>.</p>

<p>Validation attendue :</p>
<pre><code>Destroy complete! Resources: 6 destroyed.</code></pre>

<p>Vérifie :</p>
<pre><code>docker ps</code></pre>

<p>Tu ne dois plus voir de conteneurs <code>catalogue-*</code>.</p>

<hr/>

<h2>Dépannage</h2>

<ul>
  <li>
    <strong>port is already allocated</strong> (5432 / 6379 / 3000) :
    changer <code>external</code> (ex: 5433, 6380, 3001) puis relancer <code>tofu apply</code>.
    Le principe du mapping de ports est celui de Docker, reflété ici via le bloc <code>ports</code> du provider [S3].
  </li>
  <li>
    <strong>Cannot connect to the Docker daemon</strong> :
    démarrer Docker Desktop, vérifier avec <code>docker ps</code>, puis relancer <code>tofu plan</code>/<code>tofu apply</code>.
    Les contexts Docker et l’endpoint actif sont décrits dans la documentation Docker [S8].
  </li>
  <li>
    <strong>Docker Desktop détecté mais OpenTofu n’arrive pas à se connecter</strong> :
    définir <code>DOCKER_HOST</code> via <code>docker context inspect</code> puis relancer la commande.
    Docker documente l’usage de <code>docker context</code> et l’effet de <code>DOCKER_HOST</code> [S8][S9].
  </li>
  <li>
    <strong>L’image API ne build pas</strong> :
    vérifier que <code>api/</code> est au même niveau que <code>main.tf</code>, que le fichier s’appelle <code>Dockerfile</code>,
    puis relancer <code>tofu apply</code>. La configuration <code>docker_image.build.context</code> est documentée [S4].
  </li>
</ul>
