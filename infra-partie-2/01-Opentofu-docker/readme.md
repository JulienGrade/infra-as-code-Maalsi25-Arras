<h1>Atelier OpenTofu en local avec Docker</h1>

<h2>Objectif</h2>
<p>
Découvrir l’Infrastructure as Code en utilisant OpenTofu pour créer et détruire automatiquement
une infrastructure Docker locale : une image Nginx et un conteneur exposé sur un port.
</p>

<hr/>

<h2>Sources utilisées</h2>
<p>
Les choix techniques de ce TP (provider, image Docker, ports, publication de ports, vérifications)
sont basés sur les documentations officielles listées ci-dessous.
</p>

<h3>Références</h3>
<ul>
  <li><strong>[S1]</strong> Documentation OpenTofu : installation</li>
  <li><strong>[S2]</strong> Terraform Registry : provider <code>kreuzwerker/docker</code></li>
  <li><strong>[S3]</strong> Docker Hub : image officielle <code>nginx</code> (exemple de mapping <code>8080:80</code>)</li>
  <li><strong>[S4]</strong> Documentation NGINX : exécuter NGINX avec Docker, mapping de port <code>-p</code> (port 80)</li>
  <li><strong>[S5]</strong> Documentation Docker CLI : <code>docker context inspect</code> (endpoint Docker/Host)</li>
  <li><strong>[S6]</strong> Documentation Docker CLI : <code>docker container port</code> (visualiser les ports publiés)</li>
</ul>

<p>Liens (copiables) :</p>
<pre><code>[S1] https://opentofu.org/docs/intro/install/
[S2] https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs
[S3] https://hub.docker.com/_/nginx
[S4] https://docs.nginx.com/nginx/admin-guide/installing-nginx/installing-nginx-docker/
[S5] https://docs.docker.com/reference/cli/docker/context/inspect/
[S6] https://docs.docker.com/reference/cli/docker/container/port/
</code></pre>

<hr/>

<h2>Étape 1 — Prérequis</h2>

<h3>1.1 Docker doit fonctionner</h3>
<p>
Vérification :
</p>
<pre><code>docker ps</code></pre>

<p>
Si la commande répond sans erreur (même avec une liste vide), Docker est opérationnel.
Pour vérifier plus précisément les mappings de ports, la documentation Docker recommande également
l’usage de <code>docker ps</code> et <code>docker container port</code> [S6].
</p>

<h3>1.2 OpenTofu doit être installé</h3>
<p>
Vérification :
</p>
<pre><code>tofu version</code></pre>

<p>
Les méthodes d’installation officielles (Linux, macOS, Windows) sont documentées dans la documentation OpenTofu [S1].
</p>

<hr/>

<h2>Étape 2 — Créer le fichier main.tf</h2>

<p>
Créer un dossier pour le TP puis un fichier <code>main.tf</code>. Cette configuration utilise le provider Docker
maintenu sur le Terraform Registry [S2].
</p>

<h3>2.1 Provider et versions</h3>
<p>
Le bloc <code>terraform</code> déclare le provider et sa contrainte de version. Cela rend le TP reproductible,
car OpenTofu téléchargera une version compatible du provider Docker [S2].
</p>

<h3>2.2 Connexion au daemon Docker (macOS)</h3>
<p>
Le provider Docker communique avec le daemon via un endpoint (souvent un socket Unix).
Sur macOS avec Docker Desktop, l’endpoint peut être obtenu via <code>docker context inspect</code>, qui expose la valeur
du champ <code>Endpoints.docker.Host</code> [S5].
</p>

<p>
Exemple pour afficher l’endpoint actuel :
</p>
<pre><code>docker context inspect --format '{{ .Endpoints.docker.Host }}'</code></pre>

<p>
Dans ce TP, le provider est configuré explicitement avec un socket Docker Desktop :
</p>

<pre><code>provider "docker" {
  host = "unix:///Users/juliengrade/.docker/run/docker.sock"
}</code></pre>

<p>
Cette valeur correspond à l’endpoint retourné par le contexte Docker (selon configuration locale) [S5].
</p>

<hr/>

<h2>Étape 3 — Déclarer les ressources à créer</h2>

<h3>3.1 Tirer l’image Nginx</h3>
<p>
On utilise l’image officielle <code>nginx:latest</code> telle que décrite sur Docker Hub [S3].
</p>

<pre><code>resource "docker_image" "nginx" {
  name = "nginx:latest"
}</code></pre>

<h3>3.2 Lancer un conteneur Nginx</h3>
<p>
Le conteneur est créé à partir de l’image Nginx. Le port interne <code>80</code> correspond au port HTTP
utilisé par Nginx dans les exemples officiels. La documentation Nginx montre un mapping
<code>-p 8080:80</code> (host:container) pour rendre l’application accessible sur <code>http://localhost:8080</code> [S4].
La page Docker Hub de l’image officielle reprend également l’exemple <code>-p 8080:80</code> [S3].
</p>

<pre><code>resource "docker_container" "nginx" {
  name  = "nginx"
  image = docker_image.nginx.image_id

  ports {
    internal = 80
    external = 8080
  }
}</code></pre>

<p>
Le bloc <code>ports</code> reproduit exactement l’équivalent de la commande Docker suivante, documentée dans les exemples :
</p>

<pre><code>docker run -p 8080:80 nginx</code></pre>

<p>
Le principe du mapping <code>host:container</code> est décrit explicitement dans la documentation Nginx pour Docker [S4],
et illustré dans la documentation Docker Hub de l’image officielle [S3].
</p>

<hr/>

<h2>Étape 4 — Initialiser le projet</h2>
<p>
Dans le dossier où se trouve <code>main.tf</code> :
</p>

<pre><code>tofu init</code></pre>

<p>
Cette commande télécharge le provider Docker défini dans <code>required_providers</code> [S2].
</p>

<hr/>

<h2>Étape 5 — Voir le plan</h2>
<pre><code>tofu plan</code></pre>

<p>
Résultat attendu :
</p>
<pre><code>Plan: 2 to add, 0 to change, 0 to destroy.</code></pre>

<h3>Erreurs courantes</h3>
<ul>
  <li>
    <strong>Cannot connect to the Docker daemon</strong> : vérifier le contexte Docker et l’endpoint retourné par
    <code>docker context inspect</code> [S5], puis adapter la valeur <code>host</code> du provider si nécessaire [S2].
  </li>
  <li>
    <strong>port is already allocated</strong> : changer <code>external = 8080</code> (par exemple <code>8081</code>), car le port hôte est déjà utilisé.
    Le principe du mapping de ports est documenté via les exemples Nginx Docker [S4] et Docker Hub [S3].
  </li>
</ul>

<hr/>

<h2>Étape 6 — Appliquer le plan</h2>
<pre><code>tofu apply</code></pre>

<p>
OpenTofu demande confirmation. Saisir :
</p>
<pre><code>yes</code></pre>

<p>
Validation attendue :
</p>
<pre><code>Apply complete! Resources: 2 added, 0 changed, 0 destroyed.</code></pre>

<p>
Vérification côté Docker :
</p>
<pre><code>docker ps</code></pre>

<p>
La documentation Docker permet aussi de visualiser précisément le mapping via :
</p>
<pre><code>docker container port nginx</code></pre>

<p>
Cette commande est documentée dans la référence officielle du CLI Docker [S6].
</p>

<hr/>

<h2>Étape 7 — Tester l’accès à Nginx</h2>

<p>
Dans un navigateur :
</p>
<pre><code>http://localhost:8080</code></pre>

<p>
Tu dois voir la page d’accueil Nginx. Le même résultat est attendu dans les exemples officiels
avec <code>-p 8080:80</code> [S3][S4].
</p>

<p>
Test terminal (optionnel) :
</p>
<pre><code>curl -I http://localhost:8080</code></pre>

<hr/>

<h2>Étape 8 — Détruire l’infrastructure</h2>

<p>
L’intérêt de l’IaC : supprimer proprement tout ce qui a été créé.
</p>

<pre><code>tofu destroy</code></pre>

<p>
Confirmer avec :
</p>
<pre><code>yes</code></pre>

<p>
Validation attendue :
</p>
<pre><code>Destroy complete! Resources: 2 destroyed.</code></pre>

<p>
Vérification :
</p>
<pre><code>docker ps</code></pre>

<p>
Le conteneur <code>nginx</code> ne doit plus être présent.
</p>

<hr/>

<h2>Conclusion</h2>
<p>
Ce TP démontre comment OpenTofu pilote Docker via le provider <code>kreuzwerker/docker</code> [S2]
et comment un mapping de ports standard (<code>8080:80</code>) rend un service web accessible localement,
comme illustré dans les documentations Nginx et Docker Hub [S3][S4].
</p>
