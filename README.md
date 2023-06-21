# Links
- [docker-desktop kubernetes](https://www.docker.com/blog/how-kubernetes-works-under-the-hood-with-docker-desktop/)


# Features
- [X] check local development with k8s
  - [X] access is provided through service loadBalancer
  - [X] image can be restarted easily with pod delete when using same name
- [ ] (WIP) explore crossplane composition functions
- [X] **composition:**
  - [X] deploy k8s resources with crossplane composition
  - [X] update a composition automatically apply new resources
  - [X] update a composition automatically delete removed resources
- [ ] **composition revision:** update k8s resources with an updated crossplane composition
