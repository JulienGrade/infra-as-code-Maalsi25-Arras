<h1>ATELIER 3 — PUPPET : AUTOMATISATION DE LA CONFIGURATION (SANS VM, AVEC DOCKER)</h1>

<h2>Objectif</h2>
<p>
Découvrir Puppet en appliquant un module localement (sans Puppet Server) afin de gérer un état cible :
</p>
<ul>
  <li><strong>Dans un environnement Linux reproductible via Docker</strong> : installation de Nginx, démarrage du service, déploiement d’une page d’accueil personnalisée</li>
  <li><strong>Sur macOS / Windows</strong> : démonstration via la gestion d’un fichier (pas d’installation de paquets)</li>
</ul>
<p>
Dans ce TP, l’exécution recommandée se fait <strong>dans un conteneur Ubuntu</strong> afin de ne pas dépendre de l’installation de Puppet sur macOS/Windows.
</p>

<hr/>

<h2>Étape 1 — Prérequis</h2>

<h3>1.1 Docker doit fonctionner</h3>
<code>docker ps</code>
<p>Si tu vois une liste (même vide), Docker fonctionne.</p>

<h3>1.2 Le module Puppet doit être présent</h3>
<p>Structure attendue :</p>
<code>
tp-03-puppet/<br/>
&nbsp;&nbsp;modules/<br/>
&nbsp;&nbsp;&nbsp;&nbsp;nginx/<br/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;manifests/<br/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;init.pp<br/>
</code>

<p>Vérification :</p>
<code>
ls modules/nginx/manifests<br/>
</code>
<p>Tu dois voir <code>init.pp</code>.</p>

<hr/>

<h2>Étape 2 — Contenu du manifeste Puppet</h2>
<p>
Dans <code>modules/nginx/manifests/init.pp</code>, mets ce contenu :
</p>

<code>
class nginx {<br/><br/>

&nbsp;&nbsp;if $facts['os']['family'] == 'windows' {<br/>
&nbsp;&nbsp;&nbsp;&nbsp;file { 'C:/puppet-demo-nginx.html':<br/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;ensure  =&gt; file,<br/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;content =&gt; "&lt;h1&gt;Démo Puppet sur Windows (fichier géré)&lt;/h1&gt;\n",<br/>
&nbsp;&nbsp;&nbsp;&nbsp;}<br/><br/>

&nbsp;&nbsp;} elsif $facts['os']['family'] == 'Darwin' {<br/>
&nbsp;&nbsp;&nbsp;&nbsp;file { '/tmp/nginx-puppet.html':<br/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;ensure  =&gt; file,<br/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;content =&gt; "&lt;h1&gt;Démo Puppet macOS (fichier géré)&lt;/h1&gt;\n",<br/>
&nbsp;&nbsp;&nbsp;&nbsp;}<br/><br/>

&nbsp;&nbsp;} else {<br/>
&nbsp;&nbsp;&nbsp;&nbsp;package { 'nginx':<br/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;ensure =&gt; installed,<br/>
&nbsp;&nbsp;&nbsp;&nbsp;}<br/><br/>

&nbsp;&nbsp;&nbsp;&nbsp;service { 'nginx':<br/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;ensure  =&gt; running,<br/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;enable  =&gt; true,<br/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;require =&gt; Package['nginx'],<br/>
&nbsp;&nbsp;&nbsp;&nbsp;}<br/><br/>

&nbsp;&nbsp;&nbsp;&nbsp;file { '/var/www/html/index.html':<br/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;ensure  =&gt; file,<br/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;content =&gt; "&lt;h1&gt;Bienvenue sur le serveur Puppet Nginx !&lt;/h1&gt;\n",<br/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;require =&gt; Package['nginx'],<br/>
&nbsp;&nbsp;&nbsp;&nbsp;}<br/>
&nbsp;&nbsp;}<br/>
}<br/>
</code>

<hr/>

<h2>Étape 3 — Lancer un environnement Linux via Docker</h2>
<p>
Depuis la racine du TP (là où se trouve <code>modules/</code>), lance un conteneur Ubuntu et monte ton dossier de modules à l’intérieur.
</p>

<code>
docker run -it --rm \<br/>
&nbsp;&nbsp;-v "$PWD/modules:/modules" \<br/>
&nbsp;&nbsp;ubuntu:22.04 bash<br/>
</code>

<p>
Tu es maintenant dans un shell Linux (Ubuntu) où l’on va installer Puppet et exécuter le module.
</p>

<hr/>

<h2>Étape 4 — Installer Puppet + Nginx + curl dans le conteneur</h2>
<p>Dans le conteneur Ubuntu :</p>

<code>
apt update<br/>
apt install -y puppet nginx curl<br/>
</code>

<p>Vérifie Puppet :</p>
<code>puppet --version</code>

<hr/>

<h2>Étape 5 — Valider la syntaxe du manifeste</h2>
<code>puppet parser validate /modules/nginx/manifests/init.pp</code>
<p>
Si aucune sortie ne s’affiche, la syntaxe est correcte.
</p>

<hr/>

<h2>Étape 6 — Appliquer le module Puppet (première exécution)</h2>
<code>puppet apply --modulepath=/modules -e "include nginx"</code>

<p>Attendu (première fois) :</p>
<ul>
  <li>Nginx est installé (si nécessaire)</li>
  <li>Le service Nginx passe à <code>running</code></li>
  <li>Le fichier <code>/var/www/html/index.html</code> est géré avec le contenu attendu</li>
</ul>

<hr/>

<h2>Étape 7 — Vérifier le résultat</h2>
<p>Dans le conteneur :</p>
<code>curl http://localhost</code>

<p>Résultat attendu :</p>
<code>&lt;h1&gt;Bienvenue sur le serveur Puppet Nginx !&lt;/h1&gt;</code>

<hr/>

<h2>Étape 8 — Vérifier l’idempotence</h2>
<p>
Relance exactement la même commande : si l’état est déjà correct, Puppet ne doit rien modifier.
</p>

<code>puppet apply --modulepath=/modules -e "include nginx"</code>

<p>Résultat attendu :</p>
<ul>
  <li>Aucun “changed” sur les ressources</li>
  <li>Seulement un message de fin du type : <code>Notice: Applied catalog in X.XX seconds</code></li>
</ul>

<hr/>

<h2>Étape 9 — Quitter (nettoyage automatique)</h2>
<p>Pour sortir du conteneur :</p>
<code>exit</code>
<p>
Le conteneur est supprimé automatiquement grâce à l’option <code>--rm</code>.
</p>

<hr/>

<h2>Validation attendue (preuves)</h2>
<ul>
  <li>La première exécution Puppet met le service Nginx en <code>running</code> et gère la page <code>index.html</code></li>
  <li><code>curl http://localhost</code> affiche bien le H1 personnalisé</li>
  <li>La seconde exécution Puppet ne fait aucun changement (idempotence)</li>
</ul>
