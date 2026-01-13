<h1>ATELIER 4 — Ansible : automatiser le déploiement</h1>

<h2>Objectif</h2>
<p>
Découvrir Ansible et les principes de la configuration as code en automatisant
le déploiement d’un serveur Nginx avec une page HTML personnalisée.
</p>
<p>
Le TP est réalisé en local, sans cloud, et de manière portable grâce à Docker.
</p>

<hr/>

<h2>Sources utilisées</h2>
<p>
Les choix techniques (exécution locale sans SSH, modules Ansible utilisés, usage d’un conteneur Ubuntu,
bind-mount, option <code>--rm</code>, élévation de privilèges avec <code>become</code>) sont basés sur les documentations officielles listées ci-dessous.
</p>

<h3>Références</h3>
<ul>
  <li><strong>[S1]</strong> Documentation Ansible : Inventaires (formats INI, groupes)</li>
  <li><strong>[S2]</strong> Documentation Ansible : connexion locale (<code>ansible_connection=local</code>)</li>
  <li><strong>[S3]</strong> Documentation Ansible : module <code>ping</code> (test de connectivité)</li>
  <li><strong>[S4]</strong> Documentation Ansible : module <code>apt</code></li>
  <li><strong>[S5]</strong> Documentation Ansible : module <code>service</code></li>
  <li><strong>[S6]</strong> Documentation Ansible : module <code>copy</code></li>
  <li><strong>[S7]</strong> Documentation Ansible : module <code>debug</code></li>
  <li><strong>[S8]</strong> Documentation Ansible : élévation de privilèges (<code>become</code>)</li>
  <li><strong>[S9]</strong> Ubuntu Official Image (Docker Hub)</li>
  <li><strong>[S10]</strong> Docker CLI : <code>docker container run</code> (options <code>--rm</code>, <code>-v</code>)</li>
</ul>

<p>Liens (copiables) :</p>
<pre><code>[S1] https://docs.ansible.com/ansible/latest/inventory_guide/intro_inventory.html
[S2] https://docs.ansible.com/ansible/latest/inventory_guide/connection_details.html
[S3] https://docs.ansible.com/ansible/latest/collections/ansible/builtin/ping_module.html
[S4] https://docs.ansible.com/ansible/latest/collections/ansible/builtin/apt_module.html
[S5] https://docs.ansible.com/ansible/latest/collections/ansible/builtin/service_module.html
[S6] https://docs.ansible.com/ansible/latest/collections/ansible/builtin/copy_module.html
[S7] https://docs.ansible.com/ansible/latest/collections/ansible/builtin/debug_module.html
[S8] https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_privilege_escalation.html
[S9] https://hub.docker.com/_/ubuntu
[S10] https://docs.docker.com/reference/cli/docker/container/run/
</code></pre>

<hr/>

<h2>Environnement utilisé</h2>
<ul>
  <li>Poste hôte : macOS / Windows / Linux</li>
  <li>Docker Desktop installé et fonctionnel</li>
  <li>Ansible exécuté dans un conteneur Ubuntu</li>
</ul>

<p>
Ce choix permet d’utiliser les modules Ansible Linux (comme <code>apt</code> et <code>service</code>) dans un environnement cohérent,
indépendamment du système d’exploitation hôte. L’image <code>ubuntu:22.04</code> provient de l’image officielle Ubuntu [S9].
</p>

<hr/>

<h2>Étape 1 — Créer le dossier du TP</h2>
<p>Créer un dossier pour ce TP avec les fichiers suivants :</p>

<pre><code>tp-04-ansible/
  inventory.ini
  playbook.yml
</code></pre>

<hr/>

<h2>Étape 2 — Créer l’inventaire Ansible</h2>
<p>
Dans le fichier <code>inventory.ini</code>, ajouter :
</p>

<pre><code>[local]
localhost ansible_connection=local
</code></pre>

<p>
Le format INI d’inventaire et la notion de groupe sont décrits dans la documentation Ansible [S1].
La variable <code>ansible_connection=local</code> indique à Ansible d’exécuter les tâches localement, sans SSH, ce qui est adapté
dans un conteneur ou une machine locale [S2].
</p>

<hr/>

<h2>Étape 3 — Créer le playbook principal</h2>
<p>
Créer le fichier <code>playbook.yml</code> avec le contenu suivant.
Les modules utilisés (<code>apt</code>, <code>service</code>, <code>copy</code>, <code>debug</code>) sont des modules intégrés (<code>ansible.builtin</code>)
documentés officiellement [S4][S5][S6][S7].
</p>

<p>
Le paramètre <code>become: yes</code> active l’élévation de privilèges (équivalent sudo) afin d’installer des paquets
et écrire dans <code>/var/www/html</code>. Ce mécanisme est documenté dans la partie privilege escalation [S8].
</p>

<pre><code>---
- name: TP Ansible – Déploiement local sur Ubuntu
  hosts: local
  become: yes

  tasks:
    - name: Mettre à jour la liste des paquets
      apt:
        update_cache: yes

    - name: Installer Nginx
      apt:
        name: nginx
        state: present

    - name: Démarrer et activer le service Nginx
      service:
        name: nginx
        state: started
        enabled: yes

    - name: Déployer une page d'accueil personnalisée
      copy:
        dest: /var/www/html/index.html
        content: |
          &lt;html&gt;
          &lt;head&gt;&lt;title&gt;TP Ansible&lt;/title&gt;&lt;/head&gt;
          &lt;body&gt;
            &lt;h1&gt;Bienvenue sur le serveur Nginx géré par Ansible&lt;/h1&gt;
          &lt;/body&gt;
          &lt;/html&gt;

    - name: Afficher un message de fin
      debug:
        msg: "Déploiement Ansible terminé avec succès sur {{ ansible_facts['distribution'] }}"
</code></pre>

<p>
Détails des modules :
</p>
<ul>
  <li><code>apt</code> : gestion des paquets sur distributions Debian/Ubuntu (mise à jour cache + installation Nginx). [S4]</li>
  <li><code>service</code> : gestion de l’état d’un service (started/enabled). [S5]</li>
  <li><code>copy</code> : déploiement d’un fichier et gestion de son contenu. [S6]</li>
  <li><code>debug</code> : affichage d’un message, utile pour valider les facts Ansible. [S7]</li>
</ul>

<hr/>

<h2>Étape 4 — Lancer un conteneur Ubuntu avec Ansible</h2>
<p>
Depuis le dossier du TP, lancer le conteneur Ubuntu en montant le dossier courant dans <code>/tp</code>.
Le bind-mount <code>-v</code> et l’option <code>--rm</code> sont documentés dans la référence Docker (<code>docker container run</code>) [S10].
</p>

<pre><code>docker run -it --rm \
  -v $(pwd):/tp \
  ubuntu:22.04 bash
</code></pre>

<p>
Le dossier du TP est maintenant accessible dans le conteneur via <code>/tp</code>.
</p>

<hr/>

<h2>Étape 5 — Installer Ansible dans le conteneur</h2>
<p>Dans le conteneur Ubuntu :</p>

<pre><code>apt update
apt install -y ansible curl
</code></pre>

<p>Vérification :</p>
<pre><code>ansible --version</code></pre>

<hr/>

<h2>Étape 6 — Se placer dans le dossier du TP</h2>
<pre><code>cd /tp
ls
</code></pre>

<p>Tu dois voir <code>inventory.ini</code> et <code>playbook.yml</code>.</p>

<hr/>

<h2>Étape 7 — Tester la connexion Ansible</h2>
<p>
Le module <code>ping</code> permet de valider que l’inventaire est correct et qu’Ansible peut exécuter une action
sur la cible. Ce module est documenté officiellement. [S3]
</p>

<pre><code>ansible -i inventory.ini local -m ping</code></pre>

<p>Résultat attendu :</p>
<pre><code>localhost | SUCCESS =&gt; pong</code></pre>

<hr/>

<h2>Étape 8 — Exécuter le playbook</h2>
<pre><code>ansible-playbook -i inventory.ini playbook.yml</code></pre>

<p>
Lors de la première exécution, certaines tâches peuvent être en <code>changed</code> (installation de paquets, écriture du fichier).
Les exécutions suivantes doivent converger vers <code>ok</code> si l’état cible est déjà atteint (principe d’idempotence).
</p>

<hr/>

<h2>Étape 9 — Vérification du résultat</h2>
<p>Tester le serveur Nginx :</p>
<pre><code>curl http://localhost</code></pre>

<p>Résultat attendu (le contenu exact de ton <code>copy</code>) :</p>
<pre><code>&lt;h1&gt;Bienvenue sur le serveur Nginx géré par Ansible&lt;/h1&gt;</code></pre>

<hr/>

<h2>Étape 10 — Tester l’idempotence</h2>
<p>
Modifier volontairement le fichier HTML afin de forcer un écart par rapport à l’état cible :
</p>

<pre><code>echo "KO" &gt; /var/www/html/index.html</code></pre>

<p>Puis relancer :</p>
<pre><code>ansible-playbook -i inventory.ini playbook.yml</code></pre>

<p>
La tâche <code>copy</code> doit repasser en <code>changed</code> (car le fichier ne correspond plus au contenu attendu) [S6],
les autres tâches doivent rester en <code>ok</code> si rien n’a changé.
</p>

<p>
Relancer une troisième fois :
</p>
<pre><code>ansible-playbook -i inventory.ini playbook.yml</code></pre>

<p>
Cette fois, toutes les tâches doivent être en <code>ok</code> (idempotence).
</p>

<hr/>

<h2>Conclusion</h2>
<p>
Ce TP démontre les principes fondamentaux d’Ansible :
</p>
<ul>
  <li>Automatisation déclarative via un playbook</li>
  <li>Gestion des paquets et services avec les modules <code>apt</code> et <code>service</code> [S4][S5]</li>
  <li>Gestion de fichiers avec <code>copy</code> [S6]</li>
  <li>Idempotence (convergence vers l’état cible)</li>
  <li>Reproductibilité de l’environnement grâce à Docker [S9][S10]</li>
</ul>

<p>
L’utilisation d’un conteneur Ubuntu garantit un environnement Linux cohérent, quel que soit le système hôte,
et permet d’utiliser les modules Linux de manière fiable.
</p>
