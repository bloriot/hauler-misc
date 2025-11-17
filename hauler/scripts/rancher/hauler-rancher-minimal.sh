# Set Variables
export vRancher=2.12.3
export vCertManager=1.19.1

# Setup Working Directory
if [ -d "workdir" ]; then rm -rf workdir; fi
mkdir workdir && cd workdir

# Download Cert Manager Images
# https://github.com/cert-manager/cert-manager
helm repo add jetstack https://charts.jetstack.io && helm repo update
certManagerImagesMinimal=$(helm template jetstack/cert-manager --version=v${vCertManager} | grep 'image:' | sed 's/"//g' | awk '{ print $2 }' | sed -e "s/^/    - name: /")

# Download Rancher Prime Images and Modify the List
# https://prime.ribs.rancher.io/
curl -sSfL https://prime.ribs.rancher.io/rancher/v${vRancher}/rancher-images.txt -o rancher-images-minimal.txt

# Exclude some images (final archive ~31G)
sed -i '/neuvector\|minio\|gke\|aks\|eks\|sriov\|thanos\|tekton\|istio\|multus\|hyper\|jenkins\|prom\|grafana\|windows/d' rancher-images-minimal.txt

sort -u rancher-images-minimal.txt -o rancher-images-minimal.txt
sed -i "s/^/    - name: registry.rancher.com\//" rancher-images-minimal.txt

# Set Rancher Images Variable
rancherImagesMinimal=$(cat rancher-images-minimal.txt)

# Create Hauler Manifest
cat << EOF > ../rancher/rancher-airgap-rancher-minimal.yaml
apiVersion: content.hauler.cattle.io/v1
kind: Charts
metadata:
  name: rancher-airgap-charts-rancher-minimal
spec:
  charts:
    - name: cert-manager
      repoURL: https://charts.jetstack.io
      version: v${vCertManager}
    - name: rancher
      repoURL: https://charts.rancher.com/server-charts/prime
      version: ${vRancher}
---
apiVersion: content.hauler.cattle.io/v1
kind: Images
metadata:
  name: rancher-airgap-cert-manager-images-rancher-minimal
spec:
  images:
${certManagerImagesMinimal}
---
apiVersion: content.hauler.cattle.io/v1
kind: Images
metadata:
  name: rancher-airgap-rancher-images-rancher-minimal
spec:
  images:
${rancherImagesMinimal}
EOF

# cleanup
rm -rf workdir
