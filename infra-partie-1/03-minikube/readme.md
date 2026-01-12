<h1>Atelier Minikube (TP 3) — Déployer Nginx sur Kubernetes local</h1><br/>

<h2>Objectif</h2>
<p>
Installer et exécuter Minikube sur une VM Ubuntu (avec Docker),
puis déployer un service Nginx sur un cluster Kubernetes local et le rendre accessible.
</p>

<hr/>

<h2>Pré-requis</h2>
<ul>
  <li>Une VM Ubuntu fonctionnelle (accès terminal)</li>
  <li>Docker installé et démarré</li>
  <li>Accès Internet depuis la VM</li>
</ul>

<hr/>

<h2>Étape 1 — Vérifier l’environnement</h2>

<h3>1.1 Vérifier Ubuntu</h3>
<code>lsb_release -a</code><br/>

<h3>1.2 Vérifier Docker (daemon actif)</h3>
<code>sudo docker ps</code><br/>
<p>
Attendu : aucune erreur. Une liste vide ou non, c’est OK.
</p>

<h3>1.3 (Recommandé) Vérifier que Docker démarre au boot</h3>
<code>sudo systemctl status docker</code><br/>
<p>
Si Docker n’est pas actif :
</p>
<code>sudo systemctl start docker</code><br/>
<code>sudo systemctl enable docker</code><br/>

<hr/>

<h2>Étape 2 — Autoriser ton utilisateur à utiliser Docker (OBLIGATOIRE)</h2>
<p>
Minikube ne doit pas être lancé avec <code>sudo</code>. On met donc l’utilisateur courant dans le groupe <code>docker</code>.
</p>

<code>sudo usermod -aG docker $USER</code><br/>
<code>newgrp docker</code><br/>

<h3>Validation</h3>
<code>docker ps</code><br/>
<p>
Attendu : pas d’erreur “permission denied”.
</p>

<hr/>

<h2>Étape 3 — Installer kubectl</h2>

<h3>Méthode simple (Snap)</h3>
<code>sudo apt update</code><br/>
<code>sudo apt install -y snapd</code><br/>
<code>sudo snap install kubectl --classic</code><br/>

<h3>Validation</h3>
<code>kubectl version --client</code><br/>

<hr/>

<h2>Étape 4 — Installer Minikube</h2>

<h3>4.1 Télécharger Minikube</h3>
<code>curl -LO https://github.com/kubernetes/minikube/releases/latest/download/minikube-linux-amd64</code><br/>

<h3>4.2 Rendre exécutable</h3>
<code>chmod +x minikube-linux-amd64</code><br/>

<h3>4.3 Installer dans /usr/local/bin</h3>
<code>sudo mv minikube-linux-amd64 /usr/local/bin/minikube</code><br/>

<h3>Validation</h3>
<code>minikube version</code><br/>

<hr/>

<h2>Étape 5 — Démarrer Minikube (driver Docker)</h2>

<h3>5.1 Démarrage</h3>
<code>minikube start --driver=docker</code><br/>

<p>
Attendu : message indiquant que <code>kubectl</code> est configuré pour utiliser le cluster.
</p>

<h3>5.2 Vérifier l’état du cluster</h3>
<code>minikube status</code><br/>
<code>kubectl get nodes</code><br/>

<p>
Attendu : le node <code>minikube</code> doit être <code>Ready</code>.
</p>

<hr/>

<h2>Étape 6 — Déployer Nginx</h2>

<h3>6.1 Créer un Deployment Nginx</h3>
<code>kubectl create deployment nginx --image=nginx</code><br/>

<h3>Validation</h3>
<code>kubectl get deployments</code><br/>
<code>kubectl get pods</code><br/>
<p>
Attendu : un Pod <code>nginx-xxxxx</code> en <code>Running</code>.
</p>

<hr/>

<h2>Étape 7 — Exposer Nginx (Service NodePort)</h2>

<h3>7.1 Créer le Service</h3>
<code>kubectl expose deployment nginx --type=NodePort --port=80</code><br/>

<h3>Validation</h3>
<code>kubectl get services</code><br/>
<p>
Attendu : un service <code>nginx</code> avec un port du type <code>80:3xxxx/TCP</code>.
</p>

<hr/>

<h2>Étape 8 — Récupérer l’URL d’accès</h2>

<h3>8.1 Obtenir l’URL</h3>
<code>minikube service nginx --url</code><br/>

<p>
Attendu : une URL du type :
</p>
<code>http://192.168.xx.xx:3xxxx</code><br/>

<hr/>

<h2>Étape 9 — Tester l’accès à Nginx</h2>

<h3>9.1 Test depuis la VM</h3>
<code>curl $(minikube service nginx --url)</code><br/>

<p>
Attendu : HTML de la page par défaut Nginx (avec “Welcome to nginx!”).
</p>

<hr/>

<h2>Étape 10 — Exploration rapide (bonus)</h2>
<code>kubectl get all</code><br/>
<code>kubectl describe pod -l app=nginx</code><br/>
<code>kubectl logs -l app=nginx --tail=50</code><br/>

<hr/>

<h2>Étape 11 — Nettoyage</h2>

<h3>Supprimer les ressources Nginx</h3>
<code>kubectl delete service nginx</code><br/>
<code>kubectl delete deployment nginx</code><br/>

<h3>(Optionnel) Arrêter / supprimer le cluster</h3>
<code>minikube stop</code><br/>
<code>minikube delete</code><br/>

<hr/>

<h2>Dépannage rapide</h2>

<table>
  <thead>
    <tr>
      <th>Symptôme</th>
      <th>Cause probable</th>
      <th>Solution</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>permission denied while trying to connect to Docker daemon</td>
      <td>Utilisateur pas dans le groupe docker</td>
      <td><code>sudo usermod -aG docker $USER</code> puis <code>newgrp docker</code></td>
    </tr>
    <tr>
      <td>The docker driver should not be run with root privileges</td>
      <td>Minikube lancé avec sudo</td>
      <td>Relancer sans sudo</td>
    </tr>
    <tr>
      <td>Pod nginx reste en Pending</td>
      <td>Cluster pas prêt / ressources insuffisantes</td>
      <td><code>kubectl describe pod ...</code> puis augmenter RAM/CPU VM</td>
    </tr>
    <tr>
      <td>curl ne répond pas sur l’URL</td>
      <td>Service non exposé / NodePort non OK</td>
      <td><code>kubectl get svc</code> + <code>minikube service nginx --url</code></td>
    </tr>
  </tbody>
</table>
