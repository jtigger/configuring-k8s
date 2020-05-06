# Local Development (on Kind)

1. [install KIND](https://kind.sigs.k8s.io/docs/user/quick-start/#installation).
2. create a KIND cluster _with the configuration provided_:
    ```console
    $ kind create cluster --config=kind/config.yaml
    ```
    - marks the Node(s) of the cluster with a label Nginx looks for to scan for `Ingress` instances.
    - defines port-forwarding from your host to the cluster for specific ports.
    - all this follows the kind docs on [setting up ingress](https://kind.sigs.k8s.io/docs/user/ingress/).
3. install the Nginx Ingress Controller:
    ```console
    $ ytt -f dependencies/ingress-nginx.yaml -f kind/image-refs-from-tag-to-sha.yaml | kubectl apply -f -
    ```
    - we're following the security best practice of pulling container images located by SHA digests, not tags.
    
    verify the Nginx Ingress Controller install:
    ```console
    $ curl localhost
    ```
   TODO: explain what the result _should_ look like.
4. install `tiny-pete` — the application:
    ```console
    $ ytt -f tiny-pete/deploy/ | kubectl apply -f -
    ```
5. verify the deployment:
    ```console
    $ curl http://localhost/pete
    ```

---

# Design Rationale

_Design decisions with reasoning._

## Deploy on a KIND Cluster with the Nginx Ingress Controller

- for local development, there are two common options: minikube and kind. Both work rather well. For no particular 
  reason, we happen to be using kind.
- be default, plain Kubernetes clusters do *not* route network traffic into the cluster: a good security stance. 👍
- routing traffic into the cluster requires three pieces:
    1. configure the host network to forward traffic to the cluster;
        - done through `kind/config.yaml`
    2. install an Ingress Controller — thereby adding to the cluster the ability to convert a `Ingress` resource into
       networking configuration that routes in-bound (aka "ingress") traffic.
        - we're installing the Nginx Ingress Controller.  
    2. configure the cluster network (via kube-proxy) to direct that traffic to the right Service.
        - done through `tiny-pete/deploy/ingress.yaml`
 
## Overlay Kubernetes manifests to replace image tags with their SHA digests
 
- when publishing a container image (e.g. to Docker Hub), it is good practice to tag container images to mark with
  human-readable labels (e.g. version number).
- however, docker tags can be repositioned to point to another image.
    - sometimes an author wants to fix a minor bug without incrementing the version of the image.
    - in theory, someone could compromise the author's account to the image repository and upload malicious code and
        re-point the tag to that image.
- to ensure that the image that was selected is the one that is used, we dereference that image tag to the
   SHA digest it is currently pointing at (recording the tag as a comment).
   - SHA digests are immutable: it is the digest of the contents of the image; change anything and the digest changes.
   - one can audit the image and those results are trustworthy for users of the image.
- patches are more maintainable than manual edits.
   - therefore, instead of modifying 3rd party Kubernetes manifests, we write `ytt` overlays that contain those edits.
     (i.e. `kind/image-refs-from-tag-to-sha.yaml`)

