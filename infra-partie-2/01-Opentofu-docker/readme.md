<h1>Atelier OpenTofu en local avec Docker</h1>

<h2>Objectif</h2>
<p>
Découvrir l’Infrastructure as Code en utilisant OpenTofu pour créer et détruire automatiquement
une infrastructure Docker locale : une image Nginx + un conteneur exposé sur un port.
</p>

<h2>Étape 1 — Prérequis</h2>

<h3>1.1 Docker doit fonctionner</h3>
<code>docker ps</code>
<p>
Si tu vois une liste (même vide), c’est bon.<br/>
</p>

<h4>Linux : correction “permission denied” (si nécessaire)</h4>
<code>
sudo usermod -aG docker $USER<br/>
newgrp docker<br/>
docker ps
</code>

<h4>Mac / Windows</h4>
<p>
Assure-toi que <strong>Docker Desktop</strong> est démarré (icône active) puis relance :
</p>
<code>docker ps</code>

<h3>1.2 OpenTofu doit être installé</h3>
<p>Vérification :</p>
<code>tofu version</code>

<h3>Installation (Linux / Ubuntu)</h3>
<p>Méthode recommandée : installation via le gestionnaire de paquets.</p>
<code>
sudo apt update<br/>
sudo apt install -y opentofu
</code>

<h3>Installation (Mac)</h3>
<p>Si Homebrew est installé :</p>
<code>brew install opentofu</code>

<h3>Installation (Windows)</h3>
<p>Deux options simples :</p>
<ul>
  <li>Via <strong>Chocolatey</strong> (si installé) : <code>choco install opentofu</code></li>
  <li>Via binaire : télécharger OpenTofu (GitHub Releases) et ajouter <code>tofu.exe</code> au PATH</li>
</ul>

<p>Validation attendue :</p>
<ul>
  <li><code>docker ps</code> fonctionne</li>
  <li><code>tofu version</code> affiche une version</li>
</ul>

<hr/>

<h2>Étape 2 — Créer le fichier principal main.tf (portable Mac / Windows / Linux)</h2>
<p>
Créer un dossier pour le TP puis un fichier <code>main.tf</code> contenant la configuration suivante.
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

<p>Pourquoi ce choix ?</p>
<ul>
  <li><code>kreuzwerker/docker</code> : provider Docker le plus utilisé</li>
  <li>Version fixée (<code>~&gt; 3.0</code>) : reproductible</li>
  <li><code>provider "docker" {}</code> : laisse Docker décider de la connexion selon l’OS (Mac/Windows/Linux)</li>
</ul>

<h3>Note (utile en cas de souci Docker Desktop)</h3>
<p>
Sur certaines configurations Mac/Windows, OpenTofu peut échouer à se connecter à Docker si l’hôte Docker n’est pas détecté automatiquement.
Dans ce cas, définis un <strong>DOCKER_HOST</strong> avant de lancer <code>tofu plan</code>/<code>tofu apply</code>.
</p>

<h4>Mac (Docker Desktop)</h4>
<code>
export DOCKER_HOST="$(docker context inspect --format '{{.Endpoints.docker.Host}}')" <br/>
</code>

<h4>Windows PowerShell (Docker Desktop)</h4>
<code>
$env:DOCKER_HOST = (docker context inspect --format '{{.Endpoints.docker.Host}}')<br/>
</code>

<h4>Windows CMD (Docker Desktop)</h4>
<code>
for /f "delims=" %i in ('docker context inspect --format "{{.Endpoints.docker.Host}}"') do set DOCKER_HOST=%i
</code>

<p>
Ensuite relance <code>tofu plan</code> ou <code>tofu apply</code>.
</p>

<hr/>

<h2>Étape 3 — Initialiser le projet</h2>
<p>Dans le dossier où se trouve <code>main.tf</code> :</p>
<code>tofu init</code>

<p>Ce que fait cette commande :</p>
<ul>
  <li>Lit ton <code>main.tf</code></li>
  <li>Télécharge le provider Docker</li>
  <li>Prépare l’environnement OpenTofu</li>
</ul>

<p>Validation attendue : la sortie contient quelque chose comme :</p>
<code>
Initializing the backend...<br/>
Initializing provider plugins...<br/>
- Finding kreuzwerker/docker versions matching "~&gt; 3.0"...<br/>
- Installing kreuzwerker/docker v3.x.x...<br/>
OpenTofu has been successfully initialized!
</code>

<p>Vérification :</p>
<code>
ls -a
</code>
<p>
Tu dois voir un dossier <code>.terraform/</code> ou <code>.tofu/</code>.
</p>

<hr/>

<h2>Étape 4 — Déclarer ce qu’on veut créer</h2>
<p>Dans ce TP, on veut :</p>
<ol>
  <li>Tirer l’image Docker <code>nginx:latest</code></li>
  <li>Lancer un conteneur depuis cette image</li>
  <li>Publier le port 80 du conteneur sur le port 8080 de la machine</li>
</ol>

<p>Ajoute dans <code>main.tf</code> (sous les blocs existants) :</p>

<code>
resource "docker_image" "nginx" {<br/>
&nbsp;&nbsp;name = "nginx:latest"<br/>
}<br/><br/>

resource "docker_container" "nginx" {<br/>
&nbsp;&nbsp;name  = "tp-nginx"<br/>
&nbsp;&nbsp;image = docker_image.nginx.image_id<br/><br/>

&nbsp;&nbsp;rm = true<br/><br/>

&nbsp;&nbsp;ports {<br/>
&nbsp;&nbsp;&nbsp;&nbsp;internal = 80<br/>
&nbsp;&nbsp;&nbsp;&nbsp;external = 8080<br/>
&nbsp;&nbsp;}<br/>
}
</code>

<p>Ce que ça veut dire :</p>
<ul>
  <li><code>docker_image</code> : “assure-toi que j’ai cette image en local”</li>
  <li><code>docker_container</code> : “lance un conteneur avec cette image”</li>
  <li><code>ports</code> : “rends-le accessible sur <code>http://localhost:8080</code>”</li>
  <li><code>rm = true</code> : “au moment du <code>tofu destroy</code>, supprime complètement le conteneur”</li>
</ul>

<hr/>

<h2>Étape 5 — Voir le plan</h2>
<code>tofu plan</code>

<p>Résultat attendu :</p>
<code>
Plan: 2 to add, 0 to change, 0 to destroy.
</code>

<p>Erreurs courantes et solutions :</p>
<ul>
  <li>
    <strong>Cannot connect to the Docker daemon</strong> :
    Docker n’est pas démarré (ou Docker Desktop pas lancé). Vérifie avec <code>docker info</code>.
  </li>
  <li>
    <strong>port is already allocated</strong> :
    le port 8080 est déjà utilisé. Change <code>external = 8080</code> en <code>8081</code> puis relance <code>tofu plan</code>.
  </li>
  <li>
    <strong>Problème de connexion Docker Desktop</strong> :
    définis <code>DOCKER_HOST</code> (voir la note dans l’étape 2) puis relance <code>tofu plan</code>.
  </li>
</ul>

<hr/>

<h2>Étape 6 — Appliquer le plan (créer vraiment le conteneur)</h2>
<code>tofu apply</code>

<p>OpenTofu te demande confirmation :</p>
<code>Enter a value:</code>
<p>Tu tapes :</p>
<code>yes</code>

<p>Validation attendue :</p>
<code>Apply complete! Resources: 2 added, 0 changed, 0 destroyed.</code>

<p>Vérifie côté Docker :</p>
<code>docker ps</code>
<p>
Tu dois voir un conteneur <code>tp-nginx</code> exposé sur <code>0.0.0.0:8080-&gt;80/tcp</code>.
</p>

<hr/>

<h2>Étape 7 — Tester</h2>
<p>Dans ton navigateur :</p>
<a href="http://localhost:8080">http://localhost:8080</a>
<p>Tu dois voir la page d’accueil Nginx (Welcome to nginx!).</p>

<p>Test terminal (optionnel mais pratique) :</p>
<code>curl -I http://localhost:8080</code>

<hr/>

<h2>Étape 8 — Détruire ce qu’on vient de créer</h2>
<p>
L’intérêt de l’IaC : on détruit aussi facilement qu’on crée.
</p>
<code>tofu destroy</code>

<p>OpenTofu te demande confirmation :</p>
<code>
Do you really want to destroy all resources?<br/>
There is no undo. Only 'yes' will be accepted to confirm.<br/><br/>
Enter a value:
</code>

<p>Tu saisis :</p>
<code>yes</code>

<p>Validation attendue :</p>
<code>Destroy complete! Resources: 2 destroyed.</code>

<p>Vérifie :</p>
<code>docker ps</code>
<p>Le conteneur <code>tp-nginx</code> ne doit plus être présent.</p>

<hr/>

<h2>Conclusion</h2>
<p>
Ce TP démontre l’intérêt d’OpenTofu :
</p>
<ul>
  <li>Créer une infra en une commande (<code>tofu apply</code>)</li>
  <li>La détruire en une commande (<code>tofu destroy</code>)</li>
  <li>Reproduire la même infra à l’identique à chaque fois</li>
</ul>
<p>
Tu peux refaire <code>tofu apply</code> puis <code>tofu destroy</code> plusieurs fois pour valider la reproductibilité.
</p>
