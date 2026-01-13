<h1>ATELIER 3 — PUPPET : AUTOMATISATION DE LA CONFIGURATION (SANS VM, AVEC DOCKER)</h1>

<h2>Objectif</h2>
<p>
Découvrir Puppet en appliquant un module localement (sans Puppet Server) afin de gérer un état cible :
</p>
<ul>
  <li>Dans un environnement Linux reproductible via Docker : installation de Nginx, démarrage du service, déploiement d’une page d’accueil personnalisée</li>
  <li>Sur macOS / Windows : démonstration via la gestion d’un fichier (pas d’installation de paquets)</li>
</ul>
<p>
Dans ce TP, l’exécution recommandée se fait dans un conteneur Ubuntu afin de ne pas dépendre d’une installation Puppet sur la machine hôte.
Le principe “Puppet en mode local” est celui de <code>puppet apply</code>, documenté comme l’outil standalone d’exécution de manifests. [S6]
</p>

<hr/>

<h2>Sources utilisées</h2>
<p>
Les choix techniques (image Ubuntu, bind-mount, options <code>docker run</code>, commandes Puppet, resource types, facts)
sont basés sur les documentations officielles listées ci-dessous.
</p>

<h3>Références</h3>
<ul>
  <li><strong>[S1]</strong> Ubuntu Official Image (Docker Hub)</li>
  <li><strong>[S2]</strong> Docker CLI : <code>docker container run</code> (options <code>--rm</code>, <code>-v</code>, etc.)</li>
  <li><strong>[S3]</strong> Puppet : <code>puppet apply</code> (manpage officielle)</li>
  <li><strong>[S4]</strong> Puppet : <code>puppet parser validate</code> (manpage officielle)</li>
  <li><strong>[S5]</strong> Facter : core facts (structured facts <code>os</code>, <code>os.family</code>)</li>
  <li><strong>[S6]</strong> Puppet : resource type <code>package</code></li>
  <li><strong>[S7]</strong> Puppet : resource type <code>service</code></li>
  <li><strong>[S8]</strong> Puppet : resource type <code>file</code></li>
</ul>

<p>Liens (copiables) :</p>
<pre><code>[S1] https://hub.docker.com/_/ubuntu
[S2] https://docs.docker.com/reference/cli/docker/container/run/
[S3] https://help.puppet.com/core/current/Content/PuppetCore/Markdown/apply.htm
[S4] https://manpages.ubuntu.com/manpages/jammy/man8/puppet-parser.8.html
[S5] https://help.puppet.com/core/current/Content/PuppetCore/Markdown/core_facts.htm
[S6] https://help.puppet.com/core/current/Content/PuppetCore/Markdown/package.htm
[S7] https://help.puppet.com/core/current/Content/PuppetCore/Markdown/service.htm
[S8] https://puppet.com/docs/puppet/5.5/types/file.html
</code></pre>

<hr/>

<h2>Étape 1 — Prérequis</h2>

<h3>1.1 Docker doit fonctionner</h3>
<pre><code>docker ps</code></pre>
<p>
Si la commande répond sans erreur (même avec une liste vide), Docker fonctionne.
</p>

<h3>1.2 Le module Puppet doit être présent</h3>
<p>Structure attendue :</p>
<pre><code>tp-03-puppet/
  modules/
    nginx/
      manifests/
        init.pp
</code></pre>

<p>Vérification :</p>
<pre><code>ls modules/nginx/manifests</code></pre>
<p>Tu dois voir <code>init.pp</code>.</p>

<hr/>

<h2>Étape 2 — Contenu du manifeste Puppet</h2>
<p>
Le manifeste utilise les facts (Facter) pour adapter le comportement selon la famille d’OS.
Les facts structurés sont documentés, notamment <code>os</code> et <code>os.family</code>. [S5]
</p>

<p>
Dans <code>modules/nginx/manifests/init.pp</code>, mettre ce contenu :
</p>

<pre><code>class nginx {

  if $facts['os']['family'] == 'windows' {
    file { 'C:/puppet-demo-nginx.html':
      ensure  =&gt; file,
      content =&gt; "&lt;h1&gt;Démo Puppet sur Windows (fichier géré)&lt;/h1&gt;\n",
    }

  } elsif $facts['os']['family'] == 'Darwin' {
    file { '/tmp/nginx-puppet.html':
      ensure  =&gt; file,
      content =&gt; "&lt;h1&gt;Démo Puppet macOS (fichier géré)&lt;/h1&gt;\n",
    }

  } else {
    package { 'nginx':
      ensure =&gt; installed,
    }

    service { 'nginx':
      ensure  =&gt; running,
      enable  =&gt; true,
      require =&gt; Package['nginx'],
    }

    file { '/var/www/html/index.html':
      ensure  =&gt; file,
      content =&gt; "&lt;h1&gt;Bienvenue sur le serveur Puppet Nginx !&lt;/h1&gt;\n",
      require =&gt; Package['nginx'],
    }
  }
}
</code></pre>

<p>
Ressources utilisées (et pourquoi) :
</p>
<ul>
  <li><code>package</code> : demander l’installation d’un paquet (ici Nginx). [S6]</li>
  <li><code>service</code> : garantir qu’un service est démarré et activé. [S7]</li>
  <li><code>file</code> : garantir l’existence et le contenu d’un fichier. [S8]</li>
</ul>

<hr/>

<h2>Étape 3 — Lancer un environnement Linux via Docker</h2>
<p>
On utilise l’image <code>ubuntu:22.04</code> (Ubuntu Official Image). [S1]
</p>

<p>
Depuis la racine du TP (là où se trouve <code>modules/</code>), lancer un conteneur Ubuntu et monter le dossier
<code>modules/</code> dans le conteneur via un bind-mount (option <code>-v</code>). L’option <code>--rm</code> supprime automatiquement
le conteneur à la sortie. Ces options sont documentées dans la référence <code>docker container run</code>. [S2]
</p>

<pre><code>docker run -it --rm \
  -v "$PWD/modules:/modules" \
  ubuntu:22.04 bash
</code></pre>

<p>
Tu es maintenant dans un shell Ubuntu. Le dossier <code>/modules</code> correspond au module Puppet présent sur la machine hôte.
</p>

<hr/>

<h2>Étape 4 — Installer Puppet + Nginx + curl dans le conteneur</h2>
<p>
Dans le conteneur Ubuntu :
</p>

<pre><code>apt update
apt install -y puppet nginx curl
</code></pre>

<p>
Vérifier Puppet :
</p>
<pre><code>puppet --version</code></pre>

<p>
Remarque : ce TP vise une démonstration locale via <code>puppet apply</code> (mode standalone) plutôt qu’une architecture client/serveur. [S3]
</p>

<hr/>

<h2>Étape 5 — Valider la syntaxe du manifeste</h2>
<p>
La commande <code>puppet parser validate</code> valide la syntaxe Puppet DSL sans appliquer de changements.
Ce comportement est décrit dans la manpage. [S4]
</p>

<pre><code>puppet parser validate /modules/nginx/manifests/init.pp</code></pre>

<p>
Si aucune sortie ne s’affiche, la syntaxe est correcte.
</p>

<hr/>

<h2>Étape 6 — Appliquer le module Puppet (première exécution)</h2>
<p>
La commande <code>puppet apply</code> exécute un catalogue en mode local. L’option <code>--modulepath</code> permet d’indiquer
où se trouvent les modules (ici <code>/modules</code>). Le principe de <code>puppet apply</code> en standalone et l’usage du modulepath
sont documentés. [S3]
</p>

<pre><code>puppet apply --modulepath=/modules -e "include nginx"</code></pre>

<p>Attendu (première exécution) :</p>
<ul>
  <li>Nginx est installé (resource <code>package</code>). [S6]</li>
  <li>Le service Nginx passe à <code>running</code> et est activé (resource <code>service</code>). [S7]</li>
  <li>Le fichier <code>/var/www/html/index.html</code> est géré avec le contenu attendu (resource <code>file</code>). [S8]</li>
</ul>

<hr/>

<h2>Étape 7 — Vérifier le résultat</h2>
<p>
Dans le conteneur :
</p>
<pre><code>curl http://localhost</code></pre>

<p>Résultat attendu :</p>
<pre><code>&lt;h1&gt;Bienvenue sur le serveur Puppet Nginx !&lt;/h1&gt;</code></pre>

<hr/>

<h2>Étape 8 — Vérifier l’idempotence</h2>
<p>
Relancer exactement la même commande. Si l’état est déjà correct, Puppet ne doit pas modifier les ressources.
L’idempotence est un objectif central des déclarations d’état dans Puppet (une ressource converge vers l’état souhaité). [S6][S7][S8]
</p>

<pre><code>puppet apply --modulepath=/modules -e "include nginx"</code></pre>

<p>Résultat attendu :</p>
<ul>
  <li>Aucun “changed” sur les ressources</li>
  <li>Un message de fin du type : <code>Notice: Applied catalog in X.XX seconds</code></li>
</ul>

<hr/>

<h2>Étape 9 — Quitter (nettoyage automatique)</h2>
<p>Pour sortir du conteneur :</p>
<pre><code>exit</code></pre>

<p>
Le conteneur est supprimé automatiquement grâce à l’option <code>--rm</code>, documentée dans la référence de <code>docker container run</code>. [S2]
</p>

<hr/>

<h2>Validation attendue (preuves)</h2>
<ul>
  <li>La première exécution Puppet installe Nginx, démarre le service, et gère la page <code>index.html</code>. [S6][S7][S8]</li>
  <li><code>curl http://localhost</code> renvoie le H1 personnalisé</li>
  <li>La seconde exécution Puppet ne fait aucun changement (idempotence)</li>
</ul>
